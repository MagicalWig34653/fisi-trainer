// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import AppKit
import SceneKit

enum PetAccessoryGeometry {
    static func dress(_ root: SCNNode, kind: PetKind, outfit: PetOutfit?) {
        var previous: [SCNNode] = []
        root.enumerateChildNodes { node, _ in
            if node.name?.hasPrefix("accessory.outfit.") == true { previous.append(node) }
        }
        previous.forEach { $0.removeFromParentNode() }
        guard let outfit else { return }
        guard let head = root.childNode(withName: "head", recursively: false),
              let torso = root.childNode(withName: "torso", recursively: false) else { return }

        switch outfit {
        case .bandana: addBandana(to: torso, kind: kind)
        case .scarf: addScarf(to: torso, kind: kind)
        case .explorerHat: addExplorerHat(to: head, kind: kind)
        case .crown: addCrown(to: head, kind: kind)
        }
    }

    static func toy(_ kind: PetToy) -> SCNNode {
        let root = SCNNode()
        root.name = "accessory.toy.\(kind.rawValue)"
        switch kind {
        case .ball: makeBall(in: root)
        case .yarn: makeYarn(in: root)
        case .star: makeStar(in: root)
        case .rocket: makeRocket(in: root)
        }
        return root
    }

    private static func neckRadius(_ kind: PetKind) -> CGFloat {
        switch kind {
        case .cat: 0.38
        case .fox: 0.40
        case .dragon: 0.36
        }
    }

    private static func headTop(_ kind: PetKind) -> CGFloat {
        switch kind {
        case .cat: 0.43
        case .fox: 0.44
        case .dragon: 0.43
        }
    }

    private static func addBandana(to torso: SCNNode, kind: PetKind) {
        let cloth = color(0.91, 0.23, 0.30)
        let trim = color(1.0, 0.72, 0.46)
        let collar = part(SCNTorus(ringRadius: neckRadius(kind), pipeRadius: 0.035),
                          color: cloth, at: SCNVector3(0, 0.48, 0),
                          name: "accessory.outfit.bandana.neck")
        torso.addChildNode(collar)
        torso.addChildNode(part(SCNBox(width: 0.48, height: 0.055, length: 0.03,
                                       chamferRadius: 0.025), color: cloth,
                                at: SCNVector3(0, 0.51, 0.665),
                                name: "accessory.outfit.bandana.frontBand"))

        let path = NSBezierPath()
        path.move(to: NSPoint(x: -0.24, y: 0.08))
        path.line(to: NSPoint(x: 0.24, y: 0.08))
        path.line(to: NSPoint(x: 0, y: -0.25))
        path.close()
        let flap = part(SCNShape(path: path, extrusionDepth: 0.035), color: cloth,
                        at: SCNVector3(0, 0.41, 0.70), name: "accessory.outfit.bandana.flap")
        torso.addChildNode(flap)
        torso.addChildNode(part(SCNSphere(radius: 0.035), color: trim,
                                at: SCNVector3(0, 0.47, 0.745),
                                name: "accessory.outfit.bandana.knot"))
    }

    private static func addScarf(to torso: SCNNode, kind: PetKind) {
        let blue = color(0.24, 0.57, 0.85)
        let light = color(0.79, 0.91, 1.0)
        for y: CGFloat in [0.39, 0.47, 0.55] {
            let wrap = part(SCNTorus(ringRadius: neckRadius(kind), pipeRadius: 0.055),
                            color: y == 0.47 ? light : blue,
                            at: SCNVector3(0, y, 0), name: "accessory.outfit.scarf.wrap")
            torso.addChildNode(wrap)
            torso.addChildNode(part(SCNBox(width: 0.52, height: 0.055, length: 0.035,
                                           chamferRadius: 0.025),
                                    color: y == 0.47 ? light : blue,
                                    at: SCNVector3(0, y, 0.665),
                                    name: "accessory.outfit.scarf.frontWrap"))
        }
        let end = part(SCNBox(width: 0.105, height: 0.31, length: 0.035, chamferRadius: 0.025),
                       color: blue, at: SCNVector3(0.19, 0.23, 0.70),
                       name: "accessory.outfit.scarf.end")
        end.eulerAngles.z = -0.18
        torso.addChildNode(end)
        for index in 0..<3 {
            torso.addChildNode(part(SCNCylinder(radius: 0.009, height: 0.065),
                                    color: light,
                                    at: SCNVector3(0.15 + CGFloat(index) * 0.04, 0.04, 0.71),
                                    name: "accessory.outfit.scarf.fringe"))
        }
    }

    private static func addExplorerHat(to head: SCNNode, kind: PetKind) {
        let tan = color(0.70, 0.50, 0.28)
        let dark = color(0.34, 0.27, 0.23)
        let y = headTop(kind)
        head.addChildNode(part(SCNCylinder(radius: 0.43, height: 0.045), color: tan,
                               at: SCNVector3(0, y, -0.035),
                               name: "accessory.outfit.explorerHat.brim"))
        head.addChildNode(part(SCNCylinder(radius: 0.27, height: 0.23), color: tan,
                               at: SCNVector3(0, y + 0.13, -0.045),
                               name: "accessory.outfit.explorerHat.crown"))
        head.addChildNode(part(SCNCylinder(radius: 0.274, height: 0.035), color: dark,
                               at: SCNVector3(0, y + 0.055, -0.045),
                               name: "accessory.outfit.explorerHat.band"))
        head.addChildNode(part(SCNSphere(radius: 0.045), color: color(0.99, 0.79, 0.27),
                               at: SCNVector3(0.21, y + 0.07, 0.12),
                               scale: SCNVector3(0.9, 0.9, 0.35),
                               name: "accessory.outfit.explorerHat.badge"))
    }

    private static func addCrown(to head: SCNNode, kind: PetKind) {
        let gold = color(0.98, 0.73, 0.18)
        let jewel = color(0.22, 0.76, 0.84)
        let y = headTop(kind)
        head.addChildNode(part(SCNTorus(ringRadius: 0.27, pipeRadius: 0.055), color: gold,
                               at: SCNVector3(0, y + 0.04, -0.025),
                               name: "accessory.outfit.crown.band"))
        for x: CGFloat in [-0.22, -0.11, 0, 0.11, 0.22] {
            let tall = x == 0
            head.addChildNode(part(SCNCone(topRadius: 0, bottomRadius: 0.075,
                                           height: tall ? 0.28 : 0.20), color: gold,
                                   at: SCNVector3(x, y + (tall ? 0.20 : 0.16), 0.13),
                                   name: "accessory.outfit.crown.point"))
        }
        head.addChildNode(part(SCNSphere(radius: 0.065), color: jewel,
                               at: SCNVector3(0, y + 0.075, 0.25),
                               scale: SCNVector3(0.8, 1, 0.4),
                               name: "accessory.outfit.crown.jewel"))
    }

    private static func makeBall(in root: SCNNode) {
        let yellow = color(0.98, 0.71, 0.23)
        let coral = color(0.93, 0.32, 0.35)
        root.addChildNode(part(SCNSphere(radius: 0.19), color: yellow,
                               at: SCNVector3Zero, name: "accessory.toy.ball.body"))
        let stripe = part(SCNTorus(ringRadius: 0.181, pipeRadius: 0.014), color: coral,
                          at: SCNVector3Zero, name: "accessory.toy.ball.stripe")
        stripe.eulerAngles.x = .pi / 2
        root.addChildNode(stripe)
        root.addChildNode(part(SCNSphere(radius: 0.05), color: coral,
                               at: SCNVector3(0, 0.08, 0.174),
                               scale: SCNVector3(1, 1, 0.3), name: "accessory.toy.ball.patch"))
    }

    private static func makeYarn(in root: SCNNode) {
        let lavender = color(0.69, 0.48, 0.88)
        let light = color(0.91, 0.76, 1.0)
        root.addChildNode(part(SCNSphere(radius: 0.17), color: lavender,
                               at: SCNVector3Zero, name: "accessory.toy.yarn.ball"))
        for angle: CGFloat in [0, .pi / 3, .pi * 2 / 3] {
            let loop = part(SCNTorus(ringRadius: 0.168, pipeRadius: 0.009), color: light,
                            at: SCNVector3Zero, name: "accessory.toy.yarn.threadLoop")
            loop.eulerAngles = SCNVector3(angle, angle * 0.65, 0)
            root.addChildNode(loop)
        }
        let loose = part(SCNCylinder(radius: 0.012, height: 0.14), color: light,
                         at: SCNVector3(0.17, -0.10, 0), name: "accessory.toy.yarn.looseThread")
        loose.eulerAngles.z = .pi / 3
        root.addChildNode(loose)
    }

    private static func makeStar(in root: SCNNode) {
        let gold = color(1.0, 0.78, 0.19)
        let bright = color(1.0, 0.95, 0.62)
        let star = part(SCNShape(path: starPath(outer: 0.22, inner: 0.095),
                                 extrusionDepth: 0.06), color: gold,
                        at: SCNVector3(0, 0, -0.03), name: "accessory.toy.star.body")
        root.addChildNode(star)
        root.addChildNode(part(SCNSphere(radius: 0.066), color: bright,
                               at: SCNVector3(0, 0, 0.045),
                               scale: SCNVector3(1, 1, 0.27),
                               name: "accessory.toy.star.center"))
    }

    private static func makeRocket(in root: SCNNode) {
        let blue = color(0.32, 0.67, 0.84)
        let white = color(0.91, 0.96, 0.97)
        let red = color(0.96, 0.35, 0.35)
        root.addChildNode(part(SCNCylinder(radius: 0.085, height: 0.25), color: white,
                               at: SCNVector3(0, 0, 0), name: "accessory.toy.rocket.body"))
        root.addChildNode(part(SCNCone(topRadius: 0, bottomRadius: 0.085, height: 0.14),
                               color: red, at: SCNVector3(0, 0.19, 0),
                               name: "accessory.toy.rocket.nose"))
        for side: CGFloat in [-1, 1] {
            let fin = part(SCNBox(width: 0.09, height: 0.13, length: 0.035,
                                  chamferRadius: 0.012), color: red,
                           at: SCNVector3(side * 0.105, -0.085, 0),
                           name: "accessory.toy.rocket.fin")
            fin.eulerAngles.z = side * 0.28
            root.addChildNode(fin)
        }
        root.addChildNode(part(SCNSphere(radius: 0.048), color: blue,
                               at: SCNVector3(0, 0.035, 0.079),
                               scale: SCNVector3(1, 1, 0.3),
                               name: "accessory.toy.rocket.window"))
        root.addChildNode(part(SCNCone(topRadius: 0.018, bottomRadius: 0.055, height: 0.10),
                               color: goldFlame, at: SCNVector3(0, -0.17, 0),
                               name: "accessory.toy.rocket.flame"))
    }

    private static var goldFlame: NSColor { color(1.0, 0.68, 0.20) }

    private static func starPath(outer: CGFloat, inner: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        for index in 0..<10 {
            let angle = CGFloat(index) * .pi / 5 - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = NSPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.line(to: point) }
        }
        path.close()
        return path
    }

    private static func part(_ geometry: SCNGeometry, color: NSColor, at position: SCNVector3,
                             scale: SCNVector3 = SCNVector3(1, 1, 1), name: String) -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.62
        material.isDoubleSided = true
        geometry.materials = [material]
        let node = SCNNode(geometry: geometry)
        node.name = name
        node.position = position
        node.scale = scale
        return node
    }

    private static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
        NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
    }
}
