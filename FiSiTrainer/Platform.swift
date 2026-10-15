// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SceneKit
import SwiftUI

#if canImport(AppKit)
import AppKit

typealias PlatformColor = NSColor
typealias PlatformBezierPath = NSBezierPath
#else
import UIKit

typealias PlatformColor = UIColor
typealias PlatformBezierPath = UIBezierPath

extension UIColor {
    /// macOS-compatible initializer so the procedural geometry reads the same on both platforms.
    convenience init(calibratedRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension UIBezierPath {
    func line(to point: CGPoint) { addLine(to: point) }

    func curve(to point: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
        addCurve(to: point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }
}
#endif

extension View {
    /// Minimum window size on the Mac; touch devices fill the screen and ignore it.
    @ViewBuilder
    func macMinimumSize(width: CGFloat, height: CGFloat) -> some View {
        #if os(macOS)
        frame(minWidth: width, minHeight: height)
        #else
        self
        #endif
    }

    /// Sheet size hint for the Mac; on iPhone and iPad the system sizes the sheet.
    @ViewBuilder
    func macSheetSize(minWidth: CGFloat, idealWidth: CGFloat,
                      minHeight: CGFloat, idealHeight: CGFloat) -> some View {
        #if os(macOS)
        frame(minWidth: minWidth, idealWidth: idealWidth, minHeight: minHeight, idealHeight: idealHeight)
        #else
        self
        #endif
    }
}

extension SCNVector3 {
    /// `SCNVector3` stores `CGFloat` on macOS and `Float` on iOS; this builds one from `CGFloat` math.
    init(cg x: CGFloat, _ y: CGFloat, _ z: CGFloat) {
        self.init(x: SCNFloat(x), y: SCNFloat(y), z: SCNFloat(z))
    }

    var cgX: CGFloat { CGFloat(x) }
    var cgY: CGFloat { CGFloat(y) }
    var cgZ: CGFloat { CGFloat(z) }
}

#if os(macOS)
/// Suffix for primary buttons that react to the Return key.
let returnKeyHint = " ↵"
let isTouchDevice = false
#else
let returnKeyHint = ""
let isTouchDevice = true
#endif
