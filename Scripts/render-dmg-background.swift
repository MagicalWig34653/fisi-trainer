// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import AppKit

/// Run from the repository root: swift Scripts/render-dmg-background.swift
/// Finder uses the 1x PNG for a 760×500 window and the @2x sibling on Retina displays.
private enum DMGArtwork {
    static let logicalSize = NSSize(width: 760, height: 500)
    static let ink = NSColor(red: 0.09, green: 0.13, blue: 0.20, alpha: 1)
    static let muted = NSColor(red: 0.38, green: 0.43, blue: 0.53, alpha: 1)
    static let lime = NSColor(red: 0.77, green: 0.96, blue: 0.36, alpha: 1)

    static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat,
                      _ alpha: CGFloat = 1) -> NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func rounded(_ rect: NSRect, radius: CGFloat, fill: NSColor,
                        stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        fill.setFill()
        path.fill()
        if let stroke {
            path.lineWidth = lineWidth
            stroke.setStroke()
            path.stroke()
        }
    }

    static func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat,
                      weight: NSFont.Weight, color: NSColor, tracking: CGFloat = 0,
                      centered: Bool = false) {
        let font = NSFont.systemFont(ofSize: size, weight: weight)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .kern: tracking
        ]
        let width = (text as NSString).size(withAttributes: attributes).width
        (text as NSString).draw(at: NSPoint(x: centered ? x - width / 2 : x, y: y),
                                withAttributes: attributes)
    }

    static func draw() {
        let canvas = NSRect(origin: .zero, size: logicalSize)
        color(0.95, 0.96, 0.98).setFill()
        canvas.fill()

        // A soft, app-colored header. All Finder icon labels sit on the light field below.
        let header = NSRect(x: 0, y: 363, width: 760, height: 137)
        let gradient = NSGradient(starting: color(0.08, 0.12, 0.19),
                                  ending: color(0.14, 0.17, 0.27))!
        gradient.draw(in: header, angle: 0)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: header).addClip()
        color(0.23, 0.30, 0.45, 0.20).setStroke()
        for radius: CGFloat in [92, 133, 176] {
            let arc = NSBezierPath(ovalIn: NSRect(x: 620 - radius / 2,
                                                  y: 440 - radius / 2,
                                                  width: radius, height: radius))
            arc.lineWidth = 1
            arc.stroke()
        }
        NSGraphicsContext.restoreGraphicsState()
        lime.setFill()
        NSRect(x: 0, y: 361, width: 760, height: 3).fill()

        if let icon = NSImage(contentsOfFile: "Documentation/AppIcon.png") {
            icon.draw(in: NSRect(x: 46, y: 395, width: 84, height: 84),
                      from: .zero, operation: .sourceOver, fraction: 1)
        }
        label("FiSi Trainer", x: 142, y: 434, size: 31, weight: .bold,
              color: .white, tracking: -0.7)
        label("Dein Lernlabor für Netzwerke.", x: 143, y: 406, size: 15,
              weight: .medium, color: color(0.75, 0.82, 0.87))
        rounded(NSRect(x: 610, y: 428, width: 109, height: 30), radius: 15,
                fill: lime.withAlphaComponent(0.13),
                stroke: lime.withAlphaComponent(0.38))
        label("INSTALLIEREN", x: 664.5, y: 438, size: 10, weight: .bold,
              color: lime, tracking: 1.1, centered: true)

        // Quiet landing areas preserve contrast for Finder's real icon art and labels.
        for x: CGFloat in [76, 456] {
            rounded(NSRect(x: x + 1, y: 126, width: 228, height: 214), radius: 25,
                    fill: color(0.75, 0.78, 0.85, 0.27))
            rounded(NSRect(x: x, y: 131, width: 228, height: 214), radius: 25,
                    fill: color(0.985, 0.987, 0.998),
                    stroke: color(0.82, 0.84, 0.90))
            let halo = NSBezierPath(ovalIn: NSRect(x: x + 45, y: 195,
                                                   width: 138, height: 138))
            color(0.90, 0.88, 0.98, 0.34).setFill()
            halo.fill()
        }

        // The arrow communicates the drag gesture without competing with the icons.
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: 340, y: 248))
        arrow.line(to: NSPoint(x: 414, y: 248))
        arrow.move(to: NSPoint(x: 399, y: 264))
        arrow.line(to: NSPoint(x: 415, y: 248))
        arrow.line(to: NSPoint(x: 399, y: 232))
        arrow.lineWidth = 5
        arrow.lineCapStyle = .round
        arrow.lineJoinStyle = .round
        color(0.46, 0.41, 0.69).setStroke()
        arrow.stroke()

        label("Zum Installieren in Programme ziehen.", x: 380, y: 77,
              size: 18, weight: .semibold, color: ink, centered: true)
        label("macOS 14+  ·  Apple Silicon & Intel", x: 380, y: 48,
              size: 12, weight: .medium, color: muted, centered: true)
    }

    static func render(scale: Int, to url: URL) throws {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
            pixelsWide: Int(logicalSize.width) * scale,
            pixelsHigh: Int(logicalSize.height) * scale,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        context.cgContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
        draw()
        NSGraphicsContext.restoreGraphicsState()
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "DMGArtwork", code: 1)
        }
        try data.write(to: url)
    }
}

let directory = URL(fileURLWithPath: "Packaging", isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
try DMGArtwork.render(scale: 1, to: directory.appendingPathComponent("dmg-background.png"))
try DMGArtwork.render(scale: 2, to: directory.appendingPathComponent("dmg-background@2x.png"))
