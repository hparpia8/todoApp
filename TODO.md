# Backlog

## App Icon
- [ ] Lined paper background texture (horizontal ruled lines), vertical layout: checked box at top (below header line), unchecked box below it
- [ ] macOS squircle-style rounded corners (like iMessage) — clip icon to continuous rounded rectangle in `scripts/generate_icon.swift`
- [ ] Dark/tinted icon slots: drag PNGs into Xcode asset catalog GUI until actool 26.x toolchain issue is resolved

## UI
- [ ] Rename header label `"todo"` → `"ToDo"` in `ContentView.swift`
- [ ] Replace `"now"` divider with `"Today"`
- [ ] Dated page breaks for completed tasks grouped by day (e.g. "Monday, March 24") — insert a styled section header between each date group in the completed section

## Widget
- [ ] Remove the `"+"` add button / `Link(destination: todoapp://add)` from the widget header — widget should be read-only

## Distribution
- [ ] `scripts/build_dmg.sh` — Release build → package into `TodoApp.dmg` via `create-dmg` or `hdiutil` → upload to GitHub Releases
- [ ] Update `install.sh` to pull from the correct release asset URL
- [ ] Document notarization steps (`xcrun notarytool`) — requires paid Apple Developer account for Gatekeeper-clean install
