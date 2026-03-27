# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Branch Policy

Before making any code changes, check the current branch:

- **On `main` or `master`:** Create a new branch named after the feature or bug and do all work there.
- **On a feature branch with uncommitted changes:** Confirm the branch is relevant to the current work, then proceed.
- **On a feature branch with no changes that matches origin HEAD:** Create a new branch from it, pull from `origin main`/`origin master` to bring it up to date, then proceed.

**Branch naming:** Use underscores, descriptive of the change (e.g., `fix_app_icon`, `add_due_dates`, `update_widget_layout`). No prefixes like `feature/` or `fix/`.

**Commit messages:** Keep the title short. The body (if needed) should be concise — a few words per bullet, no filler.

Never commit directly to `main` or `master`.

## Build & Development

### macOS App (Swift/SwiftUI)
```bash
make setup      # Install XcodeGen via Homebrew + generate TodoApp.xcodeproj
make build      # Build debug config from terminal
make run        # Build and launch the app
make archive    # Build release archive
make clean      # Remove generated project and build artifacts
make open       # Open in Xcode
```

The Xcode project is **generated** — never edit `TodoApp.xcodeproj` directly. All project configuration lives in `project.yml` (XcodeGen spec). Regenerate with `make generate` after changes to `project.yml`.

Run Swift tests via Xcode's test scheme (⌘U) or `xcodebuild test -scheme TodoApp`.

### MCP Server (TypeScript)
```bash
cd mcp-server
npm run build       # Compile TypeScript → dist/index.js
npm start           # Run the MCP server (stdio transport)
npm run dev         # Watch mode
npm test            # Run Vitest suite
npm run test:watch  # Interactive watch mode
```

Run a single test file: `npx vitest run src/todo-store.test.ts`

## Architecture

### Data Flow
All state is persisted to `~/Library/Application Support/ArtisanalTodo/todos.json` as a JSON array of `TodoItem` objects. Both the macOS app and MCP server read/write this same file.

```
SwiftUI App ←→ TodoStore.swift ←→ todos.json ←→ mcp-server/src/todo-store.ts ←→ MCP Server
                    ↓                                        ↓
              WidgetKit reload                   open artisanaltodo:// (URL scheme)
```

### Sync Mechanism
- **App → File:** `TodoStore.swift` writes on every mutation, then calls `WidgetCenter.shared.reloadAllTimelines()`
- **File → App:** `TodoStore.swift` sets up a `DispatchSource.makeFileSystemObjectSource` watcher; external writes trigger a reload
- **MCP → App:** After writes, the MCP server calls `execSync("open artisanaltodo://refresh")`. `TodoAppApp.swift` handles this URL scheme to force a reload. If the app isn't running, the file watcher catches changes on next launch.

### macOS App Structure
- **`TodoApp/Models/TodoStore.swift`** — `ObservableObject` managing all state. Single source of truth; handles file I/O, the file watcher, and WidgetKit reloads.
- **`TodoApp/Models/TodoItem.swift`** — `Codable` struct shared between app and widget. Fields: `id` (UUID), `title`, `createdAt`, `completedAt`, `isCompleted`.
- **`TodoApp/Views/ContentView.swift`** — Main UI: completed history grouped by day (most recent first), active pending tasks, bottom input bar.
- **`TodoApp/Theme/AppTheme.swift`** — Color scheme enum, typography, and layout constants defining the pen-and-paper aesthetic.
- **`TodoAppApp.swift`** — App entry point and URL scheme handler (`artisanaltodo://refresh`).

### MCP Server Structure
- **`mcp-server/src/index.ts`** — Server entry point. Registers 4 tools (`add_todo`, `list_todos`, `complete_todo`, `delete_todo`) and connects via stdio transport.
- **`mcp-server/src/todo-store.ts`** — Pure logic module (no side effects, fully testable). Handles file I/O, CRUD, lookup, and formatting.

**Smart todo lookup** supports three strategies: 1-based list position (e.g., `"3"`), case-insensitive substring title match, or full UUID. Ambiguous matches (multiple titles match) return an error listing the matches.

### Unsigned vs. Signed Builds
Data path differs by signing:
- **Unsigned (dev):** `~/Library/Application Support/ArtisanalTodo/todos.json`
- **Signed (distribution):** sandboxed container path

The MCP server always uses the unsigned path. For signed builds, update `TODO_FILE_PATH` in `mcp-server/src/todo-store.ts`.

### WidgetKit
The widget extension (`TodoWidget/`) shares data via App Groups. It reads the same todos and renders Small/Medium/Large sizes. Reload is triggered by `TodoStore.swift` after every mutation.
