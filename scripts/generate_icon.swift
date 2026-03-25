#!/usr/bin/env swift
// Generates AppIcon PNG files for all macOS sizes.
// Run from the project root: swift scripts/generate_icon.swift

import Foundation
import CoreGraphics
import ImageIO

// ── Colours (match the app theme) ─────────────────────────────────────────
let bgColor     = CGColor(red: 0.973, green: 0.961, blue: 0.918, alpha: 1) // warm cream
let boxColor    = CGColor(red: 0.420, green: 0.384, blue: 0.345, alpha: 1) // muted warm gray
let accentColor = CGColor(red: 0.722, green: 0.451, blue: 0.200, alpha: 1) // copper accent

// ── Drawing ───────────────────────────────────────────────────────────────

func makeIcon(size: Int) -> CGImage {
    let s = CGFloat(size)
    let space = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0, space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Background — warm cream fill
    ctx.setFillColor(bgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

    // Subtle inner shadow to give a slight paper depth at larger sizes
    if size >= 128 {
        let inset = s * 0.04
        let innerRect = CGRect(x: inset, y: inset, width: s - inset*2, height: s - inset*2)
        ctx.setShadow(offset: CGSize(width: 0, height: -s*0.01), blur: s*0.04,
                      color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.06))
        ctx.setFillColor(bgColor)
        ctx.fill(innerRect)
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
    }

    // ── Layout ────────────────────────────────────────────────────────────
    let bs   = s * 0.285          // box side length
    let gap  = s * 0.07           // gap between the two boxes
    let ox   = (s - bs * 2 - gap) / 2   // x of left box
    let oy   = (s - bs) / 2       // y of both boxes (vertically centred)
    let lw   = max(1.0, s * 0.034)     // stroke width
    let cr   = bs * 0.13          // corner radius

    // ── Left box: CHECKED ─────────────────────────────────────────────────
    let leftRect = CGRect(x: ox, y: oy, width: bs, height: bs)

    // Box outline (accent colour for the checked box)
    ctx.setStrokeColor(accentColor)
    ctx.setLineWidth(lw)
    ctx.addPath(CGPath(roundedRect: leftRect,
                       cornerWidth: cr, cornerHeight: cr, transform: nil))
    ctx.strokePath()

    // Very light fill inside checked box
    ctx.setFillColor(CGColor(red: 0.722, green: 0.451, blue: 0.200, alpha: 0.10))
    ctx.addPath(CGPath(roundedRect: leftRect,
                       cornerWidth: cr, cornerHeight: cr, transform: nil))
    ctx.fillPath()

    // Checkmark — Core Graphics is Y-up, so vertex has the smallest y value
    //   p1 → left side, just above middle
    //   p2 → lower-centre (the "dip" of the tick)
    //   p3 → upper-right
    ctx.setStrokeColor(accentColor)
    ctx.setLineWidth(lw * 1.5)
    let p1 = CGPoint(x: ox + bs * 0.20, y: oy + bs * 0.52)
    let p2 = CGPoint(x: ox + bs * 0.42, y: oy + bs * 0.28)
    let p3 = CGPoint(x: ox + bs * 0.82, y: oy + bs * 0.72)
    ctx.move(to: p1)
    ctx.addLine(to: p2)
    ctx.addLine(to: p3)
    ctx.strokePath()

    // ── Right box: UNCHECKED ──────────────────────────────────────────────
    let rx = ox + bs + gap
    let rightRect = CGRect(x: rx, y: oy, width: bs, height: bs)

    ctx.setStrokeColor(boxColor)
    ctx.setLineWidth(lw)
    ctx.addPath(CGPath(roundedRect: rightRect,
                       cornerWidth: cr, cornerHeight: cr, transform: nil))
    ctx.strokePath()

    return ctx.makeImage()!
}

// ── Save PNG ──────────────────────────────────────────────────────────────

func savePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

// ── Main ──────────────────────────────────────────────────────────────────

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetDir  = projectRoot
    .appendingPathComponent("TodoApp/Assets.xcassets/AppIcon.appiconset")

try! FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

// Generate every size we need (some are reused for different scale variants)
let sizes = [16, 32, 64, 128, 256, 512, 1024]
for sz in sizes {
    let url = iconsetDir.appendingPathComponent("icon_\(sz).png")
    savePNG(makeIcon(size: sz), to: url)
    print("  ✓ \(sz)×\(sz)  →  icon_\(sz).png")
}

print("\nDone — icons written to:\n\(iconsetDir.path)")
