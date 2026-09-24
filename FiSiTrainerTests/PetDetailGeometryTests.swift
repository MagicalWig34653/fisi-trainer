// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SceneKit
import XCTest
@testable import FiSiTrainer

final class PetDetailGeometryTests: XCTestCase {
    func testDecorationsAttachDistinctAnatomyWithoutChangingBaseNames() {
        let expected: [(PetKind, [String])] = [
            (.cat, ["detail.cat.toe", "detail.cat.freckle", "detail.cat.earLobe",
                    "detail.cat.tagRing"]),
            (.fox, ["detail.fox.cheekTuft", "detail.fox.chestTuft",
                    "detail.fox.nostril", "detail.fox.tailTipAccent"]),
            (.dragon, ["detail.dragon.hornRing", "detail.dragon.sideScale",
                       "detail.dragon.wingStrut", "detail.dragon.wingJoint",
                       "detail.dragon.spineAccent"])
        ]
        for (kind, requiredNames) in expected {
            let root = barePet()
            PetDetailGeometry.decorate(root, kind: kind)
            let names = allNodes(in: root).compactMap(\.name)

            for name in requiredNames {
                XCTAssertTrue(names.contains(name), "Missing \(kind) detail: \(name)")
            }
            XCTAssertEqual(names.filter { $0 == "head" }.count, 1)
            XCTAssertEqual(names.filter { $0 == "tail" }.count, 1)
            XCTAssertEqual(names.filter { $0 == "wing" }.count, 2)
            XCTAssertTrue(names.filter { $0.hasPrefix("detail.") }.count > 10)
        }
    }

    func testFoodHasDistinctPartsPhysicalMaterialsAndCompactBounds() {
        let expected: [(PetKind, [String])] = [
            (.cat, ["detail.food.fish.body", "detail.food.fish.tailFin",
                    "detail.food.fish.eye", "detail.food.fish.scale"]),
            (.fox, ["detail.food.berry.fruit", "detail.food.berry.leaf",
                    "detail.food.berry.seed", "detail.food.berry.stem"]),
            (.dragon, ["detail.food.drumstick.meat", "detail.food.drumstick.bone",
                       "detail.food.drumstick.knob", "detail.food.drumstick.score"])
        ]
        for (kind, requiredNames) in expected {
            let food = PetDetailGeometry.food(for: kind)
            let parts = allNodes(in: food).filter { $0.geometry != nil }
            let names = parts.compactMap(\.name)

            XCTAssertEqual(food.name, "detail.food.\(kind.rawValue)")
            XCTAssertGreaterThan(parts.count, 5)
            for name in requiredNames {
                XCTAssertTrue(names.contains(name), "Missing \(kind) food part: \(name)")
            }
            XCTAssertTrue(parts.allSatisfy {
                $0.geometry?.firstMaterial?.lightingModel == .physicallyBased
            })

            let box = food.boundingBox
            XCTAssertGreaterThan(box.max.x - box.min.x, 0.25)
            XCTAssertLessThan(box.max.x - box.min.x, 0.8)
            XCTAssertLessThan(box.max.y - box.min.y, 0.6)
            XCTAssertLessThan(box.max.z - box.min.z, 0.5)
        }
    }

    private func barePet() -> SCNNode {
        let root = SCNNode()
        for name in ["head", "tail", "wing", "wing"] {
            let node = SCNNode()
            node.name = name
            if name == "wing" {
                node.position.x = root.childNodes.contains { $0.name == "wing" } ? 0.31 : -0.31
            }
            root.addChildNode(node)
        }
        return root
    }

    private func allNodes(in root: SCNNode) -> [SCNNode] {
        var nodes = [root]
        root.enumerateChildNodes { node, _ in nodes.append(node) }
        return nodes
    }
}
