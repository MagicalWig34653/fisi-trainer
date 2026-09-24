// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import AppKit
import SceneKit
import SwiftUI

final class FramedPetView: SCNView {
    var reframe: (() -> Void)?
    var framingCenter = SCNVector3Zero
    var framingDistance: CGFloat = 1
    private var lastLayoutSize = CGSize.zero

    override func layout() {
        super.layout()
        if bounds.size != lastLayoutSize {
            lastLayoutSize = bounds.size
            reframe?()
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            reframe?()
        } else {
            super.mouseDown(with: event)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        guard let camera = pointOfView else { return }
        let offset = SCNVector3(camera.position.x - framingCenter.x,
                                camera.position.y - framingCenter.y,
                                camera.position.z - framingCenter.z)
        let distance = sqrt(offset.x * offset.x + offset.y * offset.y + offset.z * offset.z)
        guard distance > 0 else { return }
        let next = min(max(distance * exp(event.scrollingDeltaY * 0.006),
                           framingDistance * 0.55), framingDistance * 2.5)
        let ratio = next / distance
        camera.position = SCNVector3(framingCenter.x + offset.x * ratio,
                                     framingCenter.y + offset.y * ratio,
                                     framingCenter.z + offset.z * ratio)
    }
}

/// A real, orbitable SceneKit habitat. The surrounding view owns pet availability and actions.
struct PetHabitatView: NSViewRepresentable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let pet: PetKind
    let interaction: PetInteraction?
    let interactionID: Int
    let outfit: PetOutfit?
    let toy: PetToy?

    init(pet: PetKind, interaction: PetInteraction?, interactionID: Int,
         outfit: PetOutfit? = nil, toy: PetToy? = nil) {
        self.pet = pet
        self.interaction = interaction
        self.interactionID = interactionID
        self.outfit = outfit
        self.toy = toy
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> SCNView {
        let view = FramedPetView()
        view.allowsCameraControl = true
        view.cameraControlConfiguration.allowsTranslation = false
        view.cameraControlConfiguration.autoSwitchToFreeCamera = false
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.automaticTarget = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.18, alpha: 1)
        view.setAccessibilityRole(.image)
        view.setAccessibilityHelp("Mit der Maus ziehen, um das 3D-Haustier zu drehen.")
        view.reframe = { [weak coordinator = context.coordinator, weak view] in
            guard let view else { return }
            coordinator?.frame(in: view)
        }
        context.coordinator.show(pet, in: view, outfit: outfit, toy: toy,
                                 reduceMotion: reduceMotion)
        context.coordinator.lastInteractionID = interactionID
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.pet != pet || coordinator.outfit != outfit || coordinator.toy != toy ||
            coordinator.reduceMotion != reduceMotion {
            coordinator.show(pet, in: view, outfit: outfit, toy: toy,
                             reduceMotion: reduceMotion)
            coordinator.lastInteractionID = interactionID
        } else if interactionID != coordinator.lastInteractionID {
            coordinator.lastInteractionID = interactionID
            if let interaction { coordinator.perform(interaction) }
        }
    }

    static func dismantleNSView(_ view: SCNView, coordinator: Coordinator) {
        (view as? FramedPetView)?.reframe = nil
        coordinator.clear()
        view.isPlaying = false
        view.scene = nil
    }

    final class Coordinator {
        private static let backdrop = NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.18, alpha: 1)
        var pet: PetKind?
        var outfit: PetOutfit?
        var toy: PetToy?
        var reduceMotion = false
        var lastInteractionID = 0
        private var character: SCNNode?
        private var head: SCNNode?
        private var effects: SCNNode?
        private var camera: SCNNode?
        private var toyNode: SCNNode?
        private let toyRest = SCNVector3(0.94, 0.20, 0.37)

        func clear() {
            character?.enumerateChildNodes { node, _ in node.removeAllActions() }
            character?.removeAllActions()
            effects?.childNodes.forEach { $0.removeAllActions(); $0.removeFromParentNode() }
            toyNode?.removeAllActions()
            character = nil
            head = nil
            effects = nil
            camera = nil
            toyNode = nil
            pet = nil
            outfit = nil
            toy = nil
        }

        func show(_ kind: PetKind, in view: SCNView,
                  outfit: PetOutfit? = nil, toy: PetToy? = nil,
                  reduceMotion: Bool = false) {
            clear()
            pet = kind
            self.outfit = outfit
            self.toy = toy
            self.reduceMotion = reduceMotion
            let scene = SCNScene()
            scene.background.contents = Self.backdrop

            let plinth = Self.node(SCNCylinder(radius: 1.55, height: 0.18),
                                   color: NSColor(calibratedRed: 0.23, green: 0.30, blue: 0.43, alpha: 1),
                                   at: SCNVector3(0, -0.12, 0))
            plinth.geometry?.firstMaterial?.metalness.contents = 0.2
            scene.rootNode.addChildNode(plinth)
            let inset = Self.node(SCNCylinder(radius: 1.42, height: 0.025),
                                 color: NSColor(calibratedRed: 0.36, green: 0.46, blue: 0.59, alpha: 1),
                                 at: SCNVector3(0, -0.012, 0))
            scene.rootNode.addChildNode(inset)

            let character = SCNNode()
            character.name = "pet"
            let head = Self.build(kind, into: character)
            PetDetailGeometry.decorate(character, kind: kind)
            PetAccessoryGeometry.dress(character, kind: kind, outfit: outfit)
            scene.rootNode.addChildNode(character)
            self.character = character
            self.head = head
            let effects = SCNNode()
            effects.name = "effects"
            scene.rootNode.addChildNode(effects)
            self.effects = effects
            if let toy {
                let equippedToy = PetAccessoryGeometry.toy(toy)
                equippedToy.position = toyRest
                scene.rootNode.addChildNode(equippedToy)
                toyNode = equippedToy
            }
            idle()
            if !reduceMotion { animateDetails() }

            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.fieldOfView = 42
            camera.camera?.projectionDirection = .vertical
            camera.camera?.wantsExposureAdaptation = false
            camera.camera?.exposureOffset = -1.0
            self.camera = camera
            scene.rootNode.addChildNode(camera)
            scene.rootNode.addChildNode(Self.light(.ambient, intensity: 35,
                                                    at: SCNVector3(0, 0, 0)))
            scene.rootNode.addChildNode(Self.light(.omni, intensity: 55,
                                                    at: SCNVector3(-2, 4, 4)))
            scene.rootNode.addChildNode(Self.light(.omni, intensity: 25,
                                                    at: SCNVector3(2, 3, -2)))
            view.scene = scene
            view.pointOfView = camera
            frame(in: view)
            view.setAccessibilityLabel("Interaktives 3D-Haustier: \(Self.name(for: kind))")
            view.isPlaying = true
        }

        /// Fits only the pet geometry; the plinth and temporary effects do not control camera scale.
        func frame(in view: SCNView) {
            guard let character, let camera, view.bounds.width > 0, view.bounds.height > 0 else { return }
            var points: [SCNVector3] = []
            character.enumerateChildNodes { node, _ in
                guard let geometry = node.geometry else { return }
                let box = geometry.boundingBox
                for x in [box.min.x, box.max.x] {
                    for y in [box.min.y, box.max.y] {
                        for z in [box.min.z, box.max.z] {
                            points.append(node.convertPosition(SCNVector3(x, y, z), to: character))
                        }
                    }
                }
            }
            guard let first = points.first else { return }
            var low = first
            var high = first
            for point in points {
                low = SCNVector3(min(low.x, point.x), min(low.y, point.y), min(low.z, point.z))
                high = SCNVector3(max(high.x, point.x), max(high.y, point.y), max(high.z, point.z))
            }
            var target = SCNVector3((low.x + high.x) / 2, (low.y + high.y) / 2,
                                    (low.z + high.z) / 2)
            // A small elevation shows the face and paws without hiding the feet.
            let directionY: CGFloat = 0.22
            let directionZ = sqrt(1 - directionY * directionY)
            let tanVertical = tan(CGFloat(camera.camera?.fieldOfView ?? 42) * .pi / 360)
            let tanHorizontal = tanVertical * view.bounds.width / view.bounds.height
            let fill: CGFloat = 0.78
            // Reserve room for the largest jump while keeping the resting pet as the center.
            let fitPoints = points + points.map { SCNVector3($0.x, $0.y + 0.8, $0.z) }

            func distance(to target: SCNVector3) -> CGFloat {
                fitPoints.reduce(CGFloat(0.5)) { current, point in
                    let dx = point.x - target.x
                    let dy = point.y - target.y
                    let dz = point.z - target.z
                    let vertical = dy * directionZ - dz * directionY
                    let forward = dy * directionY + dz * directionZ
                    return max(current, forward + max(abs(dx) / (tanHorizontal * fill),
                                                      abs(vertical) / (tanVertical * fill)))
                } + 0.12
            }

            // Perspective makes nearer parts appear larger. Align the projected pet rectangle.
            for _ in 0..<3 {
                let fitted = distance(to: target)
                var minX = CGFloat.infinity
                var maxX = -CGFloat.infinity
                var minY = CGFloat.infinity
                var maxY = -CGFloat.infinity
                for point in points {
                    let dx = point.x - target.x
                    let dy = point.y - target.y
                    let dz = point.z - target.z
                    let depth = fitted - dy * directionY - dz * directionZ
                    let x = dx / (depth * tanHorizontal)
                    let y = (dy * directionZ - dz * directionY) / (depth * tanVertical)
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
                target.x += (minX + maxX) / 2 * fitted * tanHorizontal
                let shiftY = (minY + maxY) / 2 * fitted * tanVertical
                target.y += shiftY * directionZ
                target.z -= shiftY * directionY
            }
            let fitted = distance(to: target)
            camera.position = SCNVector3(target.x, target.y + directionY * fitted,
                                         target.z + directionZ * fitted)
            camera.look(at: target)
            view.defaultCameraController.target = target
            if let framed = view as? FramedPetView {
                framed.framingCenter = target
                framed.framingDistance = fitted
            }
        }

        private func idle() {
            guard let character else { return }
            character.position = SCNVector3Zero
            character.eulerAngles = SCNVector3Zero
            character.scale = SCNVector3(1, 1, 1)
            head?.removeAction(forKey: "watchToy")
            head?.eulerAngles = SCNVector3Zero
            guard !reduceMotion else { return }
            let rise = SCNAction.moveBy(x: 0, y: 0.055, z: 0, duration: 1.15)
            rise.timingMode = .easeInEaseOut
            let fall = rise.reversed()
            character.runAction(.repeatForever(.sequence([rise, fall])), forKey: "idle")
            let turn = SCNAction.rotateTo(x: 0, y: 0.10, z: 0, duration: 2.1)
            turn.timingMode = .easeInEaseOut
            let otherWay = SCNAction.rotateTo(x: 0, y: -0.10, z: 0, duration: 4.2)
            otherWay.timingMode = .easeInEaseOut
            character.runAction(.repeatForever(.sequence([turn, otherWay,
                    .rotateTo(x: 0, y: 0, z: 0, duration: 2.1), .wait(duration: 1.0)])),
                    forKey: "idleTurn")
            let glance = SCNAction.rotateTo(x: 0, y: -0.13, z: 0, duration: 0.55)
            glance.timingMode = .easeInEaseOut
            head?.runAction(.repeatForever(.sequence([.wait(duration: 1.2), glance,
                .wait(duration: 0.7), .rotateTo(x: 0, y: 0.10, z: 0, duration: 0.8),
                .wait(duration: 0.7), .rotateTo(x: 0, y: 0, z: 0, duration: 0.6),
                .wait(duration: 1.1)])), forKey: "idleLook")
        }

        private func animateDetails() {
            guard let character else { return }
            if let torso = character.childNode(withName: "torso", recursively: true) {
                let base = torso.scale
                let inhale = SCNAction.customAction(duration: 1.55) { node, elapsed in
                    let factor = CGFloat(1 + 0.035 * sin(Double(elapsed) / 1.55 * .pi / 2))
                    node.scale = SCNVector3(base.x * factor, base.y * factor, base.z * factor)
                }
                let exhale = SCNAction.customAction(duration: 1.55) { node, elapsed in
                    let factor = CGFloat(1 + 0.035 * cos(Double(elapsed) / 1.55 * .pi / 2))
                    node.scale = SCNVector3(base.x * factor, base.y * factor, base.z * factor)
                }
                torso.runAction(.repeatForever(.sequence([inhale, exhale])), forKey: "breathing")
            }
            var eyes: [SCNNode] = []
            character.enumerateChildNodes { node, _ in
                if node.name == "eye" { eyes.append(node) }
            }
            for eye in eyes {
                let close = SCNAction.customAction(duration: 0.09) { node, elapsed in
                    node.scale = SCNVector3(1, 1 - 0.92 * Float(elapsed / 0.09), 1)
                }
                let open = SCNAction.customAction(duration: 0.14) { node, elapsed in
                    node.scale = SCNVector3(1, 0.08 + 0.92 * Float(elapsed / 0.14), 1)
                }
                eye.runAction(.repeatForever(.sequence([.wait(duration: 2.6), close, open,
                                                        .wait(duration: 1.9), close, open])), forKey: "blink")
            }
            if let tail = character.childNode(withName: "tail", recursively: true) {
                let swish = SCNAction.rotateBy(x: 0, y: 0, z: 0.12, duration: 1.4)
                swish.timingMode = .easeInEaseOut
                tail.runAction(.repeatForever(.sequence([swish, swish.reversed()])), forKey: "tailIdle")
            }
            character.enumerateChildNodes { node, _ in
                if node.name == "wing" {
                    let direction: CGFloat = node.position.x < 0 ? -1 : 1
                    let spread = SCNAction.rotateBy(x: 0, y: 0, z: direction * 0.11, duration: 1.5)
                    spread.timingMode = .easeInEaseOut
                    node.runAction(.repeatForever(.sequence([spread, spread.reversed()])),
                                   forKey: "wingIdle")
                } else if node.name == "paw" {
                    let lift = SCNAction.moveBy(x: 0, y: 0.035, z: 0.04, duration: 0.7)
                    lift.timingMode = .easeInEaseOut
                    let delay = node.position.x < 0 ? 0.4 : 1.4
                    node.runAction(.repeatForever(.sequence([.wait(duration: delay), lift,
                                                            lift.reversed(), .wait(duration: 1.3)])),
                                   forKey: "pawIdle")
                }
            }
        }

        func perform(_ action: PetInteraction) {
            guard let character else { return }
            character.removeAction(forKey: "idle")
            character.removeAction(forKey: "idleTurn")
            character.removeAction(forKey: "activity")
            head?.removeAction(forKey: "nod")
            head?.removeAction(forKey: "idleLook")
            head?.removeAction(forKey: "watchToy")
            character.position = SCNVector3Zero
            character.eulerAngles = SCNVector3Zero
            character.scale = SCNVector3(1, 1, 1)
            head?.eulerAngles = SCNVector3Zero
            effects?.childNodes.forEach { $0.removeFromParentNode() }
            toyNode?.removeAllActions()
            toyNode?.position = toyRest
            toyNode?.eulerAngles = SCNVector3Zero
            toyNode?.scale = SCNVector3(1, 1, 1)

            let motion: SCNAction
            switch action {
            case .pet:
                let up = SCNAction.moveBy(x: 0, y: reduceMotion ? 0.08 : 0.28,
                                          z: 0, duration: 0.17)
                up.timingMode = .easeOut
                let down = up.reversed()
                down.timingMode = .easeIn
                motion = .sequence([up, down, up, down])
                hearts()
            case .feed:
                let tilt = SCNAction.rotateTo(x: 0.24, y: 0, z: 0, duration: 0.18)
                let level = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.18)
                head?.runAction(.sequence([.wait(duration: 1.0), tilt, level, tilt, level]),
                                forKey: "nod")
                food()
                motion = .wait(duration: 1.85)
            case .play:
                let jump = SCNAction.moveBy(x: 0, y: reduceMotion ? 0.2 : 0.8,
                                            z: 0, duration: 0.34)
                jump.timingMode = .easeOut
                let land = jump.reversed()
                land.timingMode = .easeIn
                motion = reduceMotion ? .sequence([jump, land]) :
                    .group([.sequence([jump, land]),
                            .rotateBy(x: 0, y: .pi * 2, z: 0, duration: 0.68)])
                animateToyForPlay()
            }
            character.runAction(.sequence([motion, .run { [weak self] _ in self?.idle() }]), forKey: "activity")
        }

        private func animateToyForPlay() {
            guard let toyNode, let toy else { return }
            let motion: SCNAction
            switch toy {
            case .ball, .yarn:
                let distance: CGFloat = reduceMotion ? 0.18 : 0.45
                let rise: CGFloat = reduceMotion ? 0.05 : 0.13
                let roll = SCNAction.moveBy(x: -distance, y: rise, z: 0.12, duration: 0.32)
                roll.timingMode = .easeOut
                let returnRoll = SCNAction.moveBy(x: distance, y: -rise, z: -0.12, duration: 0.38)
                returnRoll.timingMode = .easeIn
                motion = reduceMotion ? .sequence([roll, returnRoll]) :
                    .group([.sequence([roll, returnRoll]),
                            .rotateBy(x: 0, y: 0, z: .pi * 2, duration: 0.70)])
            case .star:
                let hop = SCNAction.moveBy(x: 0, y: reduceMotion ? 0.14 : 0.43,
                                           z: 0, duration: 0.35)
                hop.timingMode = .easeOut
                motion = reduceMotion ? .sequence([hop, hop.reversed()]) :
                    .group([.sequence([hop, hop.reversed()]),
                            .rotateBy(x: 0, y: .pi * 2, z: 0, duration: 0.7)])
            case .rocket:
                let launch = SCNAction.moveBy(x: 0, y: reduceMotion ? 0.25 : 0.85,
                                              z: 0, duration: 0.4)
                launch.timingMode = .easeOut
                motion = .sequence([launch, launch.reversed()])
            }
            let rest = toyRest
            toyNode.runAction(.sequence([motion, .run { node in
                node.position = rest
                node.eulerAngles = SCNVector3Zero
            }]), forKey: "toyPlay")
            head?.runAction(.sequence([.rotateTo(x: 0, y: 0.13, z: 0, duration: 0.2),
                                       .wait(duration: 0.3),
                                       .rotateTo(x: 0, y: 0, z: 0, duration: 0.2)]),
                            forKey: "watchToy")
        }

        private func hearts() {
            guard let effects else { return }
            for index in 0..<3 {
                let heart = Self.heart()
                let side: Float = index == 1 ? 1 : -1
                heart.position = SCNVector3(side * (0.35 + Float(index) * 0.16), 1.35, 0.55)
                heart.opacity = 0
                effects.addChildNode(heart)
                let fly = SCNAction.group([
                    .moveBy(x: CGFloat(side) * 0.18, y: 0.7, z: 0, duration: 0.8),
                    .sequence([.fadeIn(duration: 0.15), .wait(duration: 0.35), .fadeOut(duration: 0.3)])
                ])
                heart.runAction(.sequence([.wait(duration: Double(index) * 0.14), fly, .removeFromParentNode()]))
            }
        }

        private func food() {
            guard let effects else { return }
            let treat = PetDetailGeometry.food(for: pet ?? .cat)
            treat.position = SCNVector3(-1.05, 0.56, 0.75)
            effects.addChildNode(treat)
            let approach = SCNAction.move(to: SCNVector3(0, 1.12, 0.79), duration: 1.15)
            approach.timingMode = .easeInEaseOut
            treat.runAction(.sequence([approach, .wait(duration: 0.4),
                                       .scale(to: 0.01, duration: 0.3), .removeFromParentNode()]))
        }

        private static func build(_ kind: PetKind, into root: SCNNode) -> SCNNode {
            let fur: NSColor
            let inner: NSColor
            let belly: NSColor
            switch kind {
            case .cat:
                fur = NSColor(calibratedRed: 0.65, green: 0.57, blue: 0.88, alpha: 1)
                inner = NSColor(calibratedRed: 0.98, green: 0.67, blue: 0.77, alpha: 1)
                belly = NSColor(calibratedRed: 0.87, green: 0.82, blue: 0.98, alpha: 1)
            case .fox:
                fur = NSColor(calibratedRed: 0.97, green: 0.48, blue: 0.23, alpha: 1)
                inner = NSColor(calibratedRed: 0.96, green: 0.69, blue: 0.75, alpha: 1)
                belly = NSColor(calibratedRed: 1, green: 0.91, blue: 0.75, alpha: 1)
            case .dragon:
                fur = NSColor(calibratedRed: 0.40, green: 0.77, blue: 0.68, alpha: 1)
                inner = NSColor(calibratedRed: 0.32, green: 0.63, blue: 0.85, alpha: 1)
                belly = NSColor(calibratedRed: 0.83, green: 0.94, blue: 0.74, alpha: 1)
            }

            let torso = node(SCNSphere(radius: 0.55), color: fur, at: SCNVector3(0, 0.57, 0),
                             scale: SCNVector3(1, 1.13, 0.84))
            torso.name = "torso"
            root.addChildNode(torso)
            root.addChildNode(node(SCNSphere(radius: 0.4), color: belly, at: SCNVector3(0, 0.59, 0.39),
                                   scale: SCNVector3(0.82, 1.05, 0.36)))
            for x: Float in [-0.37, 0.37] {
                let paw = node(SCNSphere(radius: 0.17), color: fur,
                               at: SCNVector3(x, 0.16, 0.36), scale: SCNVector3(1, 0.65, 1.3))
                paw.name = "paw"
                root.addChildNode(paw)
            }

            let head = SCNNode()
            head.name = "head"
            head.position = SCNVector3(0, 1.37, 0.18)
            root.addChildNode(head)
            head.addChildNode(node(SCNSphere(radius: 0.48), color: fur, at: SCNVector3Zero,
                                   scale: SCNVector3(1.08, 0.94, 0.9)))
            for x: Float in [-0.19, 0.19] {
                let eye = SCNNode()
                eye.name = "eye"
                eye.position = SCNVector3(x, 0.07, 0.415)
                head.addChildNode(eye)
                eye.addChildNode(node(SCNSphere(radius: kind == .dragon ? 0.12 : 0.105), color: .white,
                                      at: SCNVector3Zero, scale: SCNVector3(1, 1.15, 0.48)))
                eye.addChildNode(node(SCNSphere(radius: 0.065), color: kind == .dragon ?
                                      NSColor(calibratedRed: 0.18, green: 0.35, blue: 0.52, alpha: 1) :
                                      NSColor(white: 0.09, alpha: 1),
                                      at: SCNVector3(0, -0.008, 0.068), scale: SCNVector3(0.78, 1.15, 0.45)))
                eye.addChildNode(node(SCNSphere(radius: 0.026), color: .white,
                                      at: SCNVector3(-0.024, 0.035, 0.094)))
            }
            head.addChildNode(node(SCNSphere(radius: 0.19), color: belly,
                                   at: SCNVector3(0, -0.17, 0.38), scale: SCNVector3(1.35, 0.73, 0.63)))
            head.addChildNode(node(SCNSphere(radius: 0.065), color: inner,
                                   at: SCNVector3(0, -0.13, 0.51), scale: SCNVector3(1.15, 0.7, 0.8)))

            switch kind {
            case .cat:
                for x: Float in [-0.34, 0.34] {
                    head.addChildNode(node(SCNCone(topRadius: 0, bottomRadius: 0.21, height: 0.49),
                                           color: fur, at: SCNVector3(x, 0.45, -0.02)))
                    head.addChildNode(node(SCNCone(topRadius: 0, bottomRadius: 0.12, height: 0.32),
                                           color: inner, at: SCNVector3(x, 0.46, 0.12)))
                }
                catDetails(root: root, head: head, fur: fur, inner: inner, belly: belly)
            case .fox:
                for x: Float in [-0.36, 0.36] {
                    head.addChildNode(node(SCNCone(topRadius: 0, bottomRadius: 0.23, height: 0.56),
                                           color: fur, at: SCNVector3(x, 0.49, -0.04)))
                    head.addChildNode(node(SCNCone(topRadius: 0, bottomRadius: 0.13, height: 0.35),
                                           color: inner, at: SCNVector3(x, 0.48, 0.1)))
                }
                foxDetails(root: root, head: head, fur: fur, inner: inner, belly: belly)
            case .dragon:
                for x: Float in [-0.29, 0.29] {
                    let horn = node(SCNCone(topRadius: 0, bottomRadius: 0.13, height: 0.47),
                                    color: inner, at: SCNVector3(x, 0.45, -0.1))
                    horn.eulerAngles.z = x > 0 ? -0.25 : 0.25
                    head.addChildNode(horn)
                    let wing = wingNode(color: inner, side: x > 0 ? 1 : -1)
                    root.addChildNode(wing)
                }
                dragonDetails(root: root, head: head, fur: fur, inner: inner, belly: belly)
            }
            return head
        }

        private static func catDetails(root: SCNNode, head: SCNNode, fur: NSColor,
                                       inner: NSColor, belly: NSColor) {
            let stripe = NSColor(calibratedRed: 0.48, green: 0.39, blue: 0.73, alpha: 1)
            for x: Float in [-0.20, 0, 0.20] {
                let mark = node(SCNSphere(radius: 0.055), color: stripe,
                                at: SCNVector3(x, 0.34 - abs(x) * 0.22, 0.33),
                                scale: SCNVector3(0.65, 1.7, 0.35))
                mark.name = "stripe"
                head.addChildNode(mark)
            }
            for side: Float in [-1, 1] {
                head.addChildNode(node(SCNSphere(radius: 0.15), color: belly,
                                       at: SCNVector3(side * 0.12, -0.19, 0.50),
                                       scale: SCNVector3(1.0, 0.65, 0.6)))
                for index in 0..<3 {
                    let y = Float(index - 1) * 0.075 - 0.18
                    let whisker = rod(from: SCNVector3(side * 0.21, y, 0.55),
                                      to: SCNVector3(side * 0.60, y + Float(index - 1) * 0.055, 0.56),
                                      radius: 0.008, color: belly)
                    whisker.name = "whisker"
                    head.addChildNode(whisker)
                }
                head.addChildNode(node(SCNSphere(radius: 0.055), color: stripe,
                                       at: SCNVector3(side * 0.41, -0.03, 0.26),
                                       scale: SCNVector3(1.6, 0.55, 0.4)))
                for index in 0..<2 {
                    let pad = node(SCNSphere(radius: 0.04), color: inner,
                                   at: SCNVector3(side * (0.32 + Float(index) * 0.09),
                                                  0.13, 0.56),
                                   scale: SCNVector3(0.8, 0.5, 0.35))
                    pad.name = "pawPad"
                    root.addChildNode(pad)
                }
            }
            head.addChildNode(rod(from: SCNVector3(0, -0.17, 0.56),
                                  to: SCNVector3(0, -0.25, 0.56), radius: 0.009, color: stripe))
            for side: Float in [-1, 1] {
                head.addChildNode(rod(from: SCNVector3(0, -0.25, 0.56),
                                      to: SCNVector3(side * 0.085, -0.27, 0.54), radius: 0.009,
                                      color: stripe))
            }
            let collar = node(SCNTorus(ringRadius: 0.38, pipeRadius: 0.035), color: stripe,
                              at: SCNVector3(0, 1.06, 0.14))
            collar.name = "collar"
            root.addChildNode(collar)
            root.addChildNode(node(SCNSphere(radius: 0.075), color: .systemYellow,
                                   at: SCNVector3(0, 1.04, 0.53),
                                   scale: SCNVector3(1, 1.15, 0.35)))
            let tail = SCNNode()
            tail.name = "tail"
            tail.position = SCNVector3(0.42, 0.42, -0.36)
            root.addChildNode(tail)
            let segments: [(Float, Float, CGFloat)] = [(0.08, 0.04, 0.15), (0.25, 0.17, 0.14),
                                                        (0.37, 0.35, 0.13), (0.39, 0.53, 0.13)]
            for (x, y, radius) in segments {
                tail.addChildNode(node(SCNSphere(radius: radius), color: fur,
                                       at: SCNVector3(x, y, 0)))
            }
            tail.addChildNode(node(SCNSphere(radius: 0.13), color: stripe,
                                   at: SCNVector3(0.39, 0.56, 0),
                                   scale: SCNVector3(1, 0.45, 1)))
        }

        private static func foxDetails(root: SCNNode, head: SCNNode, fur: NSColor,
                                       inner: NSColor, belly: NSColor) {
            let dark = NSColor(calibratedRed: 0.24, green: 0.20, blue: 0.25, alpha: 1)
            for side: Float in [-1, 1] {
                let edge = node(SCNCone(topRadius: 0, bottomRadius: 0.235, height: 0.59),
                                color: dark, at: SCNVector3(side * 0.36, 0.49, -0.10))
                edge.name = "earEdge"
                head.addChildNode(edge)
                head.addChildNode(node(SCNSphere(radius: 0.22), color: belly,
                                       at: SCNVector3(side * 0.26, -0.18, 0.34),
                                       scale: SCNVector3(1.15, 0.74, 0.56)))
                let paw = node(SCNSphere(radius: 0.14), color: dark,
                               at: SCNVector3(side * 0.37, 0.13, 0.45),
                               scale: SCNVector3(1.05, 0.54, 1.35))
                paw.name = "darkPaw"
                root.addChildNode(paw)
                head.addChildNode(node(SCNSphere(radius: 0.07), color: fur,
                                       at: SCNVector3(side * 0.43, -0.21, 0.18),
                                       scale: SCNVector3(1.5, 0.65, 0.5)))
            }
            let muzzle = node(SCNCone(topRadius: 0.025, bottomRadius: 0.23, height: 0.58),
                              color: belly, at: SCNVector3(0, -0.20, 0.56))
            muzzle.name = "muzzle"
            muzzle.eulerAngles.x = .pi / 2
            head.addChildNode(muzzle)
            head.addChildNode(node(SCNSphere(radius: 0.085), color: dark,
                                   at: SCNVector3(0, -0.21, 0.87),
                                   scale: SCNVector3(1.15, 0.75, 0.65)))
            let tail = SCNNode()
            tail.name = "tail"
            tail.position = SCNVector3(0.40, 0.47, -0.43)
            root.addChildNode(tail)
            let segments: [(Float, Float, CGFloat)] = [(0.17, 0.04, 0.19), (0.39, 0.13, 0.25),
                                                        (0.61, 0.27, 0.27), (0.80, 0.40, 0.22)]
            for (x, y, radius) in segments {
                tail.addChildNode(node(SCNSphere(radius: radius), color: fur,
                                       at: SCNVector3(x, y, 0),
                                       scale: SCNVector3(1.15, 0.95, 0.9)))
            }
            let whiteTip = node(SCNSphere(radius: 0.21), color: belly,
                                at: SCNVector3(0.92, 0.48, 0),
                                scale: SCNVector3(0.95, 0.88, 0.87))
            whiteTip.name = "whiteTailTip"
            tail.addChildNode(whiteTip)
        }

        private static func dragonDetails(root: SCNNode, head: SCNNode, fur: NSColor,
                                          inner: NSColor, belly: NSColor) {
            let ridge = NSColor(calibratedRed: 0.22, green: 0.56, blue: 0.59, alpha: 1)
            for y: Float in [0.34, 0.49, 0.64, 0.79] {
                let scale = node(SCNSphere(radius: 0.105), color: belly,
                                 at: SCNVector3(0, y, 0.54),
                                 scale: SCNVector3(2.55, 0.48, 0.25))
                scale.name = "bellyScale"
                root.addChildNode(scale)
            }
            for side: Float in [-1, 1] {
                head.addChildNode(rod(from: SCNVector3(side * 0.07, 0.27, 0.41),
                                      to: SCNVector3(side * 0.30, 0.21, 0.36),
                                      radius: 0.026, color: ridge))
                head.addChildNode(node(SCNSphere(radius: 0.16), color: fur,
                                       at: SCNVector3(side * 0.27, -0.17, 0.40),
                                       scale: SCNVector3(1, 0.65, 0.75)))
                for index in 0..<3 {
                    let claw = node(SCNCone(topRadius: 0, bottomRadius: 0.035, height: 0.15),
                                    color: belly,
                                    at: SCNVector3(side * (0.29 + Float(index) * 0.07),
                                                   0.12, 0.54))
                    claw.name = "claw"
                    claw.eulerAngles.x = .pi / 2
                    root.addChildNode(claw)
                }
            }
            for y: Float in [0.40, 0.58, 0.76, 0.94] {
                root.addChildNode(node(SCNCone(topRadius: 0, bottomRadius: 0.09, height: 0.22),
                                       color: ridge, at: SCNVector3(0, y, -0.48)))
            }
            for x: Float in [-0.10, 0.10] {
                head.addChildNode(node(SCNSphere(radius: 0.025), color: ridge,
                                       at: SCNVector3(x, -0.17, 0.55)))
            }
            let tail = SCNNode()
            tail.name = "tail"
            tail.position = SCNVector3(0.42, 0.39, -0.43)
            root.addChildNode(tail)
            let segments: [(Float, Float, CGFloat)] = [(0.08, 0.02, 0.18), (0.25, 0.07, 0.15),
                                                        (0.43, 0.13, 0.12), (0.59, 0.18, 0.09)]
            for (x, y, radius) in segments {
                tail.addChildNode(node(SCNSphere(radius: radius), color: fur,
                                       at: SCNVector3(x, y, 0),
                                       scale: SCNVector3(1.3, 0.8, 0.8)))
            }
            let tip = node(SCNCone(topRadius: 0, bottomRadius: 0.10, height: 0.25),
                           color: inner, at: SCNVector3(0.72, 0.23, 0))
            tip.eulerAngles.z = -.pi / 2.8
            tail.addChildNode(tip)
        }

        private static func rod(from start: SCNVector3, to end: SCNVector3,
                                radius: CGFloat, color: NSColor) -> SCNNode {
            let dx = end.x - start.x
            let dy = end.y - start.y
            let length = sqrt(dx * dx + dy * dy)
            let rod = node(SCNCylinder(radius: radius, height: CGFloat(length)), color: color,
                           at: SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2,
                                          (start.z + end.z) / 2))
            rod.eulerAngles.z = -atan2(dx, dy)
            return rod
        }

        private static func wingNode(color: NSColor, side: Float) -> SCNNode {
            let path = NSBezierPath()
            path.move(to: .zero)
            path.line(to: NSPoint(x: CGFloat(side) * 0.75, y: 0.74))
            path.line(to: NSPoint(x: CGFloat(side) * 0.65, y: 0.32))
            path.line(to: NSPoint(x: CGFloat(side) * 0.52, y: 0.42))
            path.line(to: NSPoint(x: CGFloat(side) * 0.49, y: 0.13))
            path.line(to: NSPoint(x: CGFloat(side) * 0.32, y: 0.28))
            path.close()
            let wing = node(SCNShape(path: path, extrusionDepth: 0.07), color: color,
                            at: SCNVector3(side * 0.31, 0.68, -0.3))
            wing.name = "wing"
            let ribColor = NSColor(calibratedRed: 0.20, green: 0.48, blue: 0.68, alpha: 1)
            for end in [SCNVector3(side * 0.75, 0.74, 0.08),
                        SCNVector3(side * 0.52, 0.42, 0.08),
                        SCNVector3(side * 0.32, 0.28, 0.08)] {
                wing.addChildNode(rod(from: SCNVector3(0, 0, 0.08), to: end,
                                      radius: 0.014, color: ribColor))
            }
            return wing
        }

        private static func heart() -> SCNNode {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 0, y: -0.16))
            path.curve(to: NSPoint(x: -0.2, y: 0.08), controlPoint1: NSPoint(x: -0.15, y: -0.04),
                       controlPoint2: NSPoint(x: -0.26, y: 0.08))
            path.curve(to: NSPoint(x: 0, y: 0.13), controlPoint1: NSPoint(x: -0.17, y: 0.23),
                       controlPoint2: NSPoint(x: -0.05, y: 0.2))
            path.curve(to: NSPoint(x: 0.2, y: 0.08), controlPoint1: NSPoint(x: 0.05, y: 0.2),
                       controlPoint2: NSPoint(x: 0.17, y: 0.23))
            path.curve(to: NSPoint(x: 0, y: -0.16), controlPoint1: NSPoint(x: 0.26, y: 0.08),
                       controlPoint2: NSPoint(x: 0.15, y: -0.04))
            path.close()
            return node(SCNShape(path: path, extrusionDepth: 0.04), color: .systemPink,
                        at: SCNVector3Zero)
        }

        private static func node(_ geometry: SCNGeometry, color: NSColor, at position: SCNVector3,
                                 scale: SCNVector3 = SCNVector3(1, 1, 1)) -> SCNNode {
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            material.roughness.contents = 0.72
            material.isDoubleSided = true
            geometry.materials = [material]
            let node = SCNNode(geometry: geometry)
            node.position = position
            node.scale = scale
            return node
        }

        private static func light(_ type: SCNLight.LightType, intensity: CGFloat,
                                  at position: SCNVector3) -> SCNNode {
            let node = SCNNode()
            let light = SCNLight()
            light.type = type
            light.intensity = intensity
            node.light = light
            node.position = position
            return node
        }

        private static func name(for kind: PetKind) -> String {
            switch kind {
            case .cat: "Katze"
            case .fox: "Fuchs"
            case .dragon: "Drache"
            }
        }
    }
}
