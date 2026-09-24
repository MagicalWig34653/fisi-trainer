// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SceneKit
import XCTest
@testable import FiSiTrainer

final class PetSceneTests: XCTestCase {
    @MainActor
    func testEachPetBuildsAnOrbitableSceneWithItsOwnGeometry() throws {
        for kind: PetKind in [.cat, .fox, .dragon] {
            let view = SCNView()
            let coordinator = PetHabitatView.Coordinator()
            coordinator.show(kind, in: view)
            defer { coordinator.clear(); view.scene = nil }

            let scene = try XCTUnwrap(view.scene)
            let character = try XCTUnwrap(scene.rootNode.childNode(withName: "pet", recursively: false))
            XCTAssertNotNil(view.pointOfView?.camera)
            XCTAssertGreaterThan(character.childNodes.count, 5)
            XCTAssertNotNil(character.action(forKey: "idle"))
            XCTAssertNotNil(character.childNode(withName: "tail", recursively: true)?.action(forKey: "tailIdle"))
            XCTAssertNotNil(character.childNode(withName: "eye", recursively: true)?.action(forKey: "blink"))
            XCTAssertNotNil(character.childNode(withName: "torso", recursively: true)?.action(forKey: "breathing"))
            XCTAssertGreaterThan(scene.rootNode.childNodes.filter { $0.light != nil }.count, 1)
            let wingCount = character.childNodes.filter { $0.name == "wing" }.count
            XCTAssertEqual(wingCount, kind == .dragon ? 2 : 0)
        }
    }

    @MainActor
    func testSpeciesHaveDistinctAnatomy() throws {
        let expected: [(PetKind, [String: Int])] = [
            (.cat, ["whisker": 6, "stripe": 3, "pawPad": 4, "collar": 1]),
            (.fox, ["muzzle": 1, "whiteTailTip": 1, "darkPaw": 2, "earEdge": 2]),
            (.dragon, ["bellyScale": 4, "claw": 6, "wing": 2])
        ]
        for (kind, anatomy) in expected {
            let view = SCNView()
            let coordinator = PetHabitatView.Coordinator()
            coordinator.show(kind, in: view)
            defer { coordinator.clear(); view.scene = nil }
            let character = try XCTUnwrap(view.scene?.rootNode.childNode(withName: "pet", recursively: false))
            var counts: [String: Int] = [:]
            character.enumerateChildNodes { node, _ in
                if let name = node.name { counts[name, default: 0] += 1 }
            }
            for (name, count) in anatomy {
                XCTAssertEqual(counts[name], count, "Missing \(kind) \(name) anatomy")
            }
        }
    }

    @MainActor
    func testInteractionsCreateBoundedEffectsAndAnActivity() throws {
        let view = SCNView()
        let coordinator = PetHabitatView.Coordinator()
        coordinator.show(.cat, in: view)
        defer { coordinator.clear(); view.scene = nil }

        let scene = try XCTUnwrap(view.scene)
        let character = try XCTUnwrap(scene.rootNode.childNode(withName: "pet", recursively: false))
        let effects = try XCTUnwrap(scene.rootNode.childNode(withName: "effects", recursively: false))
        coordinator.perform(.pet)
        XCTAssertEqual(effects.childNodes.count, 3)
        XCTAssertNotNil(character.action(forKey: "activity"))

        coordinator.perform(.feed)
        XCTAssertEqual(effects.childNodes.count, 1)
        coordinator.perform(.play)
        XCTAssertTrue(effects.childNodes.isEmpty)
        XCTAssertNotNil(character.action(forKey: "activity"))
    }

    @MainActor
    func testEquippedOutfitAndToyReplacePreviousSelection() throws {
        let view = FramedPetView(frame: NSRect(x: 0, y: 0, width: 650, height: 240))
        let coordinator = PetHabitatView.Coordinator()
        defer { coordinator.clear(); view.scene = nil }

        coordinator.show(.dragon, in: view, outfit: .bandana, toy: .ball)
        let firstScene = try XCTUnwrap(view.scene)
        let firstPet = try XCTUnwrap(firstScene.rootNode.childNode(withName: "pet", recursively: false))
        XCTAssertNotNil(firstPet.childNode(withName: "accessory.outfit.bandana.flap", recursively: true))
        XCTAssertNotNil(firstScene.rootNode.childNode(withName: "accessory.toy.ball", recursively: false))
        coordinator.perform(.play)
        let ball = try XCTUnwrap(firstScene.rootNode.childNode(withName: "accessory.toy.ball", recursively: false))
        XCTAssertNotNil(ball.action(forKey: "toyPlay"))
        coordinator.perform(.play)
        XCTAssertEqual(firstScene.rootNode.childNodes.filter {
            $0.name?.hasPrefix("accessory.toy.") == true
        }.count, 1)
        XCTAssertTrue(try XCTUnwrap(firstScene.rootNode.childNode(withName: "effects", recursively: false))
            .childNodes.isEmpty)

        coordinator.show(.dragon, in: view, outfit: .crown, toy: .rocket)
        let secondScene = try XCTUnwrap(view.scene)
        let secondPet = try XCTUnwrap(secondScene.rootNode.childNode(withName: "pet", recursively: false))
        XCTAssertNotNil(secondPet.childNode(withName: "accessory.outfit.crown.band", recursively: true))
        XCTAssertNil(secondPet.childNode(withName: "accessory.outfit.bandana.flap", recursively: true))
        XCTAssertNotNil(secondScene.rootNode.childNode(withName: "accessory.toy.rocket", recursively: false))
        XCTAssertNil(secondScene.rootNode.childNode(withName: "accessory.toy.ball", recursively: false))
        try assertFramedPet(in: view)
    }

    @MainActor
    func testReducedMotionKeepsPetStillBetweenInteractions() throws {
        let view = SCNView()
        let coordinator = PetHabitatView.Coordinator()
        coordinator.show(.cat, in: view, reduceMotion: true)
        defer { coordinator.clear(); view.scene = nil }
        let pet = try XCTUnwrap(view.scene?.rootNode.childNode(withName: "pet", recursively: false))
        XCTAssertNil(pet.action(forKey: "idle"))
        XCTAssertNil(pet.action(forKey: "idleTurn"))
        coordinator.perform(.pet)
        XCTAssertNotNil(pet.action(forKey: "activity"))
    }

    @MainActor
    func testPetGeometryIsCenteredAndContainedAfterSpeciesAndViewportChanges() throws {
        let view = FramedPetView(frame: NSRect(x: 0, y: 0, width: 140, height: 128))
        let coordinator = PetHabitatView.Coordinator()
        view.reframe = { [weak view, weak coordinator] in
            guard let view else { return }
            coordinator?.frame(in: view)
        }
        defer { coordinator.clear(); view.scene = nil }

        for kind: PetKind in [.cat, .fox, .dragon] {
            coordinator.show(kind, in: view)
            try assertFramedPet(in: view)
            view.frame = NSRect(x: 0, y: 0, width: 800, height: 240)
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
            try assertFramedPet(in: view)
            let wideDistance = view.framingDistance
            view.frame = NSRect(x: 0, y: 0, width: 60, height: 240)
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
            XCTAssertGreaterThan(view.framingDistance, wideDistance)
            try assertFramedPet(in: view)
            view.frame = NSRect(x: 0, y: 0, width: 140, height: 128)
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
        }
    }

    @MainActor
    private func assertFramedPet(in view: SCNView, file: StaticString = #filePath,
                                 line: UInt = #line) throws {
        let character = try XCTUnwrap(view.scene?.rootNode.childNode(withName: "pet", recursively: false))
        let camera = try XCTUnwrap(view.pointOfView)
        let target = view.defaultCameraController.target
        let outward = SCNVector3(camera.position.x - target.x,
                                 camera.position.y - target.y,
                                 camera.position.z - target.z)
        let distance = sqrt(outward.x * outward.x + outward.y * outward.y + outward.z * outward.z)
        XCTAssertGreaterThan(distance, 0, file: file, line: line)
        guard distance > 0 else { return }
        let forward = SCNVector3(outward.x / distance, outward.y / distance, outward.z / distance)
        let horizontalLength = sqrt(forward.x * forward.x + forward.z * forward.z)
        let right = SCNVector3(forward.z / horizontalLength, 0, -forward.x / horizontalLength)
        let up = SCNVector3(forward.y * right.z - forward.z * right.y,
                            forward.z * right.x - forward.x * right.z,
                            forward.x * right.y - forward.y * right.x)
        let tanVertical = tan((camera.camera?.fieldOfView ?? 42) * .pi / 360)
        let tanHorizontal = tanVertical * view.bounds.width / view.bounds.height
        var projected: [CGPoint] = []
        character.enumerateChildNodes { node, _ in
            guard let geometry = node.geometry else { return }
            let box = geometry.boundingBox
            for x in [box.min.x, box.max.x] {
                for y in [box.min.y, box.max.y] {
                    for z in [box.min.z, box.max.z] {
                        let point = node.convertPosition(SCNVector3(x, y, z), to: nil)
                        let offset = SCNVector3(point.x - target.x, point.y - target.y,
                                                point.z - target.z)
                        let depth = distance - (offset.x * forward.x + offset.y * forward.y +
                                                offset.z * forward.z)
                        guard depth > 0 else { continue }
                        let horizontal = offset.x * right.x + offset.y * right.y + offset.z * right.z
                        let vertical = offset.x * up.x + offset.y * up.y + offset.z * up.z
                        projected.append(CGPoint(x: view.bounds.midX + horizontal /
                                                 (depth * tanHorizontal) * view.bounds.width / 2,
                                                 y: view.bounds.midY + vertical /
                                                 (depth * tanVertical) * view.bounds.height / 2))
                    }
                }
            }
        }
        XCTAssertFalse(projected.isEmpty, file: file, line: line)
        guard !projected.isEmpty else { return }
        let minX = projected.map(\.x).min()!
        let maxX = projected.map(\.x).max()!
        let minY = projected.map(\.y).min()!
        let maxY = projected.map(\.y).max()!
        XCTAssertGreaterThan(minX, 0, file: file, line: line)
        XCTAssertLessThan(maxX, view.bounds.width, file: file, line: line)
        XCTAssertGreaterThan(minY, 0, file: file, line: line)
        XCTAssertLessThan(maxY, view.bounds.height, file: file, line: line)
        XCTAssertEqual((minX + maxX) / 2, view.bounds.midX,
                       accuracy: view.bounds.width * 0.06, file: file, line: line)
        XCTAssertEqual((minY + maxY) / 2, view.bounds.midY,
                       accuracy: view.bounds.height * 0.06, file: file, line: line)
        XCTAssertNotNil(view.pointOfView?.camera, file: file, line: line)
    }
}
