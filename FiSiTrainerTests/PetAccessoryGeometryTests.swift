// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SceneKit
import XCTest
@testable import FiSiTrainer

final class PetAccessoryGeometryTests: XCTestCase {
    func testCatalogUnlocksAreOrderedAndStable() {
        XCTAssertEqual(PetOutfit.allCases.map(\.unlockLevel), [4, 16, 35, 75])
        XCTAssertEqual(PetToy.allCases.map(\.unlockLevel), [6, 22, 45, 90])
        XCTAssertEqual(PetOutfit.allCases.map(\.rawValue),
                       ["bandana", "scarf", "explorerHat", "crown"])
        XCTAssertEqual(PetToy.allCases.map(\.rawValue), ["ball", "yarn", "star", "rocket"])
    }

    func testDressingReplacesPreviousOutfitAndNoneRemovesIt() {
        let pet = SCNNode()
        let head = SCNNode()
        head.name = "head"
        pet.addChildNode(head)
        let torso = SCNNode()
        torso.name = "torso"
        pet.addChildNode(torso)

        PetAccessoryGeometry.dress(pet, kind: .cat, outfit: .bandana)
        XCTAssertTrue(names(in: pet).contains("accessory.outfit.bandana.flap"))
        PetAccessoryGeometry.dress(pet, kind: .cat, outfit: .crown)
        XCTAssertTrue(names(in: pet).contains("accessory.outfit.crown.jewel"))
        XCTAssertFalse(names(in: pet).contains("accessory.outfit.bandana.flap"))
        let count = names(in: pet).filter { $0.hasPrefix("accessory.outfit.") }.count
        PetAccessoryGeometry.dress(pet, kind: .cat, outfit: .crown)
        XCTAssertEqual(names(in: pet).filter { $0.hasPrefix("accessory.outfit.") }.count, count)
        PetAccessoryGeometry.dress(pet, kind: .cat, outfit: nil)
        XCTAssertFalse(names(in: pet).contains { $0.hasPrefix("accessory.outfit.") })
    }

    func testToysHaveDistinctPartsPhysicalMaterialsAndFiniteBounds() {
        let expected: [(PetToy, [String])] = [
            (.ball, ["accessory.toy.ball.body", "accessory.toy.ball.stripe"]),
            (.yarn, ["accessory.toy.yarn.ball", "accessory.toy.yarn.threadLoop"]),
            (.star, ["accessory.toy.star.body", "accessory.toy.star.center"]),
            (.rocket, ["accessory.toy.rocket.body", "accessory.toy.rocket.fin"])
        ]
        for (kind, parts) in expected {
            let toy = PetAccessoryGeometry.toy(kind)
            let names = names(in: toy)
            for part in parts { XCTAssertTrue(names.contains(part), "Missing \(part)") }
            XCTAssertTrue(toy.childNodes.allSatisfy {
                $0.geometry?.firstMaterial?.lightingModel == .physicallyBased
            })

            let box = toy.boundingBox
            let width = box.max.x - box.min.x
            let height = box.max.y - box.min.y
            let depth = box.max.z - box.min.z
            XCTAssertTrue(width.isFinite && height.isFinite && depth.isFinite)
            XCTAssertGreaterThan(width, 0.2)
            XCTAssertLessThan(width, 0.65)
            XCTAssertLessThan(height, 0.6)
            XCTAssertLessThan(depth, 0.5)
        }
    }

    private func names(in root: SCNNode) -> [String] {
        var result = [root.name].compactMap { $0 }
        root.enumerateChildNodes { node, _ in
            if let name = node.name { result.append(name) }
        }
        return result
    }
}
