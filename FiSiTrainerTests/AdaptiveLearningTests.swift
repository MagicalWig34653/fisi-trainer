// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

final class AdaptiveLearningTests: XCTestCase {
    func testRecentSuccessReducesPracticeWeight() {
        var record = LearningRecord()
        record.record(correct: false)
        let initialWeight = record.selectionWeight
        for _ in 0..<5 { record.record(correct: true) }
        XCTAssertEqual(record.recent, Array(repeating: true, count: 5))
        XCTAssertLessThan(record.selectionWeight, initialWeight)
        XCTAssertFalse(record.needsPractice)
        XCTAssertTrue(record.isValid)
    }

    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    func testMistakesIncreaseWeightAndSamplingKeepsExploration() {
        var weak = LearningRecord()
        weak.record(correct: false)
        var strong = LearningRecord()
        strong.record(correct: true)
        XCTAssertGreaterThan(weak.selectionWeight, strong.selectionWeight)
        XCTAssertGreaterThan(strong.selectionWeight, 0)

        var random = SeededGenerator(state: 7)
        var weakSelections = 0
        var strongSelections = 0
        for _ in 0..<1_000 {
            let sample = AdaptiveLearning.weightedSample(["weak", "strong"], count: 1,
                using: &random) { $0 == "weak" ? weak.selectionWeight : strong.selectionWeight }
            if sample == ["weak"] { weakSelections += 1 }
            else { strongSelections += 1 }
        }
        XCTAssertGreaterThan(weakSelections, strongSelections)
        XCTAssertGreaterThan(strongSelections, 0)
        XCTAssertEqual(Set(AdaptiveLearning.weightedSample([1, 2, 3], count: 3,
            using: &random) { _ in 1 }), Set([1, 2, 3]))
    }

    @MainActor
    func testPortLearningPersistsOnceAndResets() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("port.json")
        let service = PortService.catalog[0]
        let question = Question(service: service, choices: [service.port, 22, 23, 25],
            correctAnswer: service.port, questionKind: .port)
        let store = GameStore(questions: [question], saveURL: url)
        XCTAssertTrue(store.learningFocus.isEmpty)
        store.startRound()
        store.answer(22)
        store.answer(service.port)
        let key = AdaptiveLearning.portKey(serviceID: service.id, kind: .port)
        XCTAssertEqual(store.learning[key]?.attempts, 1)
        XCTAssertEqual(store.learning[key]?.correct, 0)
        XCTAssertEqual(store.learningFocus, ["\(service.name) · Port"])

        let restored = GameStore(saveURL: url)
        XCTAssertEqual(restored.learning[key], store.learning[key])
        XCTAssertEqual(restored.learningFocus, store.learningFocus)
        restored.resetProgress()
        XCTAssertTrue(restored.learning.isEmpty)
        XCTAssertTrue(restored.learningFocus.isEmpty)
        XCTAssertTrue(GameStore(saveURL: url).learning.isEmpty)
    }

    @MainActor
    func testSubnetLearningPersistsAndLegacySaveHasEmptyLearning() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("subnet.json")
        let question = SubnetQuestion(prefix: 24, kind: .mask,
            prompt: "Maske für /24?",
            choices: ["255.255.255.0", "255.255.0.0", "255.255.255.128", "255.255.255.192"],
            correctAnswer: "255.255.255.0", explanation: "24 Netzbits.")
        let store = SubnetStore(questions: [question], saveURL: url)
        store.startRound()
        store.answer("255.255.0.0")
        store.answer(question.correctAnswer)
        let key = AdaptiveLearning.subnetKey(prefix: 24, kind: .mask)
        XCTAssertEqual(store.learning[key]?.attempts, 1)
        XCTAssertEqual(SubnetStore(saveURL: url).learningFocus, ["/24 · Maske"])

        let data = try Data(contentsOf: url)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        legacy.removeValue(forKey: "learning")
        try JSONSerialization.data(withJSONObject: legacy).write(to: url)
        let restored = SubnetStore(saveURL: url)
        XCTAssertNil(restored.saveError)
        XCTAssertTrue(restored.learning.isEmpty)
        XCTAssertEqual(restored.progress.answeredQuestions, 1)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AdaptiveLearningTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
