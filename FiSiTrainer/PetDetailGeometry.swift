// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import AppKit
import SceneKit

/// Small anatomy and treats layered over the main pet meshes.
enum PetDetailGeometry {
    static func decorate(_ root: SCNNode, kind: PetKind) {
        guard let head = root.childNode(withName: "head", recursively: false) else { return }
        switch kind {
        case .cat: decorateCat(root: root, head: head)
        case .fox: decorateFox(root: root, head: head)
        case .dragon: decorateDragon(root: root, head: head)
        }
    }

    static func food(for kind: PetKind) -> SCNNode {
        let food = SCNNode()
        food.name = "detail.food.\(kind.rawValue)"
        switch kind {
        case .cat: makeFish(in: food)
        case .fox: makeBerries(in: food)
        case .dragon: makeDrumstick(in: food)
        }
        return food
    }

    private static func decorateCat(root: SCNNode, head: SCNNode) {
        let stripe = color(0.46, 0.37, 0.69)
        let blush = color(0.99, 0.72, 0.82)
        let gold = color(0.98, 0.77, 0.28)
        for side: Float in [-1, 1] {
            let lobe = part(SCNSphere(radius: 0.10), color: blush,
                            at: SCNVector3(side * 0.34, 0.49, 0.20),
                            scale: SCNVector3(0.75, 1.35, 0.28), name: "detail.cat.earLobe")
            head.addChildNode(lobe)
            for index in 0..<3 {
                let freckle = part(SCNSphere(radius: 0.014), color: stripe,
                                   at: SCNVector3(side * (0.20 + Float(index % 2) * 0.055),
                                                  -0.18 - Float(index / 2) * 0.04, 0.565),
                                   scale: SCNVector3(1, 0.75, 0.45), name: "detail.cat.freckle")
                head.addChildNode(freckle)
                let toe = part(SCNSphere(radius: 0.028), color: stripe,
                               at: SCNVector3(side * 0.37 + Float(index - 1) * 0.064,
                                              0.115, 0.568),
                               scale: SCNVector3(0.5, 0.75, 0.35), name: "detail.cat.toe")
                root.addChildNode(toe)
            }
        }
        let ring = part(SCNTorus(ringRadius: 0.082, pipeRadius: 0.012), color: gold,
                        at: SCNVector3(0, 1.13, 0.535), name: "detail.cat.tagRing")
        ring.eulerAngles.x = .pi / 2
        root.addChildNode(ring)
    }

    private static func decorateFox(root: SCNNode, head: SCNNode) {
        let cream = color(1.0, 0.91, 0.77)
        let warmWhite = color(0.98, 0.97, 0.91)
        let dark = color(0.26, 0.19, 0.22)
        for side: Float in [-1, 1] {
            for index in 0..<2 {
                let cheek = part(SCNCone(topRadius: 0.008, bottomRadius: 0.08, height: 0.20),
                                 color: cream,
                                 at: SCNVector3(side * (0.41 + Float(index) * 0.055),
                                                -0.27 - Float(index) * 0.04, 0.34),
                                 name: "detail.fox.cheekTuft")
                cheek.eulerAngles.z = CGFloat(side) * -0.35
                head.addChildNode(cheek)
            }
            let nostril = part(SCNSphere(radius: 0.018), color: dark,
                               at: SCNVector3(side * 0.047, -0.22, 0.927),
                               scale: SCNVector3(0.65, 0.6, 0.4), name: "detail.fox.nostril")
            head.addChildNode(nostril)
        }
        for (index, y): (Int, Float) in [(0, 0.78), (1, 0.66), (2, 0.55)] {
            let tuft = part(SCNCone(topRadius: 0, bottomRadius: 0.105 - CGFloat(index) * 0.014,
                                    height: 0.19), color: cream,
                            at: SCNVector3(Float(index - 1) * 0.11, y, 0.49),
                            name: "detail.fox.chestTuft")
            tuft.eulerAngles.z = .pi
            root.addChildNode(tuft)
        }
        if let tail = root.childNode(withName: "tail", recursively: false) {
            for (x, y, radius): (Float, Float, CGFloat) in
                [(0.78, 0.49, 0.10), (0.91, 0.54, 0.09), (0.98, 0.48, 0.06)] {
                let accent = part(SCNSphere(radius: radius), color: warmWhite,
                                  at: SCNVector3(x, y, 0.12),
                                  scale: SCNVector3(0.8, 0.55, 0.36),
                                  name: "detail.fox.tailTipAccent")
                tail.addChildNode(accent)
            }
        }
    }

    private static func decorateDragon(root: SCNNode, head: SCNNode) {
        let ridge = color(0.20, 0.49, 0.56)
        let highlight = color(0.61, 0.88, 0.78)
        for side: Float in [-1, 1] {
            for (index, y): (Int, Float) in [(0, 0.31), (1, 0.40)] {
                let ring = part(SCNTorus(ringRadius: index == 0 ? 0.125 : 0.105,
                                         pipeRadius: 0.012), color: ridge,
                                at: SCNVector3(side * (0.29 - Float(index) * 0.025), y, -0.10),
                                name: "detail.dragon.hornRing")
                head.addChildNode(ring)
            }
            for (index, y): (Int, Float) in [(0, 0.55), (1, 0.70), (2, 0.85)] {
                let scale = part(SCNSphere(radius: 0.075), color: highlight,
                                 at: SCNVector3(side * (0.30 + Float(index % 2) * 0.045),
                                                y, 0.31),
                                 scale: SCNVector3(0.85, 0.45, 0.22),
                                 name: "detail.dragon.sideScale")
                root.addChildNode(scale)
            }
        }
        for wing in root.childNodes where wing.name == "wing" {
            let side: Float = wing.position.x < 0 ? -1 : 1
            let strut = rod(from: SCNVector3(side * 0.16, 0.12, 0.095),
                            to: SCNVector3(side * 0.65, 0.32, 0.095), radius: 0.012,
                            color: ridge, name: "detail.dragon.wingStrut")
            wing.addChildNode(strut)
            for point in [SCNVector3(side * 0.16, 0.12, 0.10),
                          SCNVector3(side * 0.52, 0.42, 0.10)] {
                wing.addChildNode(part(SCNSphere(radius: 0.035), color: highlight,
                                       at: point, name: "detail.dragon.wingJoint"))
            }
        }
        for y: Float in [0.48, 0.68, 0.88] {
            let accent = part(SCNCone(topRadius: 0, bottomRadius: 0.037, height: 0.11),
                              color: highlight, at: SCNVector3(0.12, y, -0.45),
                              name: "detail.dragon.spineAccent")
            accent.eulerAngles.z = -0.35
            root.addChildNode(accent)
        }
    }

    private static func makeFish(in root: SCNNode) {
        let blue = color(0.38, 0.76, 0.87)
        let light = color(0.76, 0.94, 0.94)
        let dark = color(0.13, 0.29, 0.42)
        root.addChildNode(part(SCNSphere(radius: 0.15), color: blue,
                               at: SCNVector3(0.035, 0, 0),
                               scale: SCNVector3(1.45, 0.68, 0.65), name: "detail.food.fish.body"))
        let tail = part(triangle(width: 0.17, height: 0.23), color: blue,
                        at: SCNVector3(-0.24, 0, 0), name: "detail.food.fish.tailFin")
        tail.eulerAngles.z = -.pi / 2
        root.addChildNode(tail)
        let fin = part(triangle(width: 0.12, height: 0.10), color: light,
                       at: SCNVector3(0.01, 0.105, 0), name: "detail.food.fish.dorsalFin")
        root.addChildNode(fin)
        for side: Float in [-1, 1] {
            root.addChildNode(part(SCNSphere(radius: 0.022), color: dark,
                                   at: SCNVector3(0.155, 0.035, side * 0.086),
                                   name: "detail.food.fish.eye"))
            for x: Float in [-0.08, 0.0, 0.08] {
                root.addChildNode(part(SCNSphere(radius: 0.025), color: light,
                                       at: SCNVector3(x, -0.018, side * 0.086),
                                       scale: SCNVector3(0.7, 0.55, 0.22),
                                       name: "detail.food.fish.scale"))
            }
        }
    }

    private static func makeBerries(in root: SCNNode) {
        let red = color(0.75, 0.13, 0.27)
        let bright = color(0.92, 0.29, 0.38)
        let green = color(0.25, 0.65, 0.38)
        for (index, center): (Int, SCNVector3) in [
            (0, SCNVector3(-0.09, 0.00, 0.02)),
            (1, SCNVector3(0.07, 0.00, 0.04)),
            (2, SCNVector3(-0.01, 0.10, -0.045))
        ] {
            root.addChildNode(part(SCNSphere(radius: 0.095),
                                   color: index == 1 ? bright : red,
                                   at: center, name: "detail.food.berry.fruit"))
            for side: Float in [-1, 1] {
                let seedX: CGFloat = center.x + CGFloat(side) * 0.026
                let seedY: CGFloat = center.y + 0.01
                let seedZ: CGFloat = center.z + 0.093
                let seedPosition = SCNVector3(seedX, seedY, seedZ)
                let seed = part(SCNSphere(radius: 0.009), color: color(1, 0.82, 0.55),
                                at: seedPosition, name: "detail.food.berry.seed")
                root.addChildNode(seed)
            }
        }
        let stem = rod(from: SCNVector3(0, 0.13, 0), to: SCNVector3(0, 0.24, 0),
                       radius: 0.012, color: green, name: "detail.food.berry.stem")
        root.addChildNode(stem)
        for side: Float in [-1, 1] {
            let leaf = part(SCNSphere(radius: 0.075), color: green,
                            at: SCNVector3(side * 0.08, 0.20, 0),
                            scale: SCNVector3(1.4, 0.35, 0.45), name: "detail.food.berry.leaf")
            leaf.eulerAngles.z = CGFloat(side) * 0.25
            root.addChildNode(leaf)
        }
    }

    private static func makeDrumstick(in root: SCNNode) {
        let roast = color(0.62, 0.27, 0.15)
        let glaze = color(0.86, 0.43, 0.20)
        let bone = color(0.96, 0.88, 0.72)
        root.addChildNode(part(SCNSphere(radius: 0.15), color: roast,
                               at: SCNVector3(-0.07, 0, 0),
                               scale: SCNVector3(1.35, 0.85, 0.70),
                               name: "detail.food.drumstick.meat"))
        let glazePatch = part(SCNSphere(radius: 0.095), color: glaze,
                              at: SCNVector3(-0.12, 0.035, 0.075),
                              scale: SCNVector3(1.0, 0.65, 0.22),
                              name: "detail.food.drumstick.glaze")
        root.addChildNode(glazePatch)
        let shaft = part(SCNCylinder(radius: 0.034, height: 0.20), color: bone,
                         at: SCNVector3(0.17, -0.005, 0), name: "detail.food.drumstick.bone")
        shaft.eulerAngles.z = .pi / 2
        root.addChildNode(shaft)
        for y: Float in [-0.038, 0.038] {
            root.addChildNode(part(SCNSphere(radius: 0.045), color: bone,
                                   at: SCNVector3(0.27, y, 0),
                                   name: "detail.food.drumstick.knob"))
        }
        for x: Float in [-0.17, -0.08, 0.01] {
            let mark = rod(from: SCNVector3(x, -0.04, 0.105),
                           to: SCNVector3(x + 0.055, 0.04, 0.105), radius: 0.007,
                           color: color(0.35, 0.14, 0.09), name: "detail.food.drumstick.score")
            root.addChildNode(mark)
        }
    }

    private static func triangle(width: CGFloat, height: CGFloat) -> SCNShape {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: -width / 2, y: -height / 2))
        path.line(to: NSPoint(x: width / 2, y: 0))
        path.line(to: NSPoint(x: -width / 2, y: height / 2))
        path.close()
        return SCNShape(path: path, extrusionDepth: 0.018)
    }

    private static func rod(from start: SCNVector3, to end: SCNVector3, radius: CGFloat,
                            color: NSColor, name: String) -> SCNNode {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        let node = part(SCNCylinder(radius: radius, height: CGFloat(length)), color: color,
                        at: SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2,
                                       (start.z + end.z) / 2), name: name)
        node.eulerAngles.z = -atan2(dx, dy)
        return node
    }

    private static func part(_ geometry: SCNGeometry, color: NSColor, at position: SCNVector3,
                             scale: SCNVector3 = SCNVector3(1, 1, 1), name: String) -> SCNNode {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.65
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
