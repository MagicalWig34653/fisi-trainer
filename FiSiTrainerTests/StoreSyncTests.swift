// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

/// A stand-in for iCloud: all clients share the values and are told when another client wrote.
@MainActor
final class FakeCloud {
    var values: [String: Data] = [:]
    var clients: [FakeBackend] = []
}

@MainActor
final class FakeBackend: SyncBackend {
    let cloud: FakeCloud
    private var observers: [String: () -> Void] = [:]

    init(cloud: FakeCloud) {
        self.cloud = cloud
        cloud.clients.append(self)
    }

    func read(_ key: String) -> Data? { cloud.values[key] }

    func write(_ data: Data, forKey key: String) {
        cloud.values[key] = data
        for client in cloud.clients where client !== self { client.observers[key]?() }
    }

    func setObserver(forKey key: String, _ handler: (() -> Void)?) { observers[key] = handler }
}

final class StoreSyncTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_000)

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @MainActor
    private func answerCorrectly(_ store: GameStore, count: Int) {
        store.startRound()
        for index in 0..<count {
            guard let question = store.currentQuestion else { return }
            store.answer(question.correctAnswer)
            if index < count - 1 { store.nextQuestion() }
        }
    }

    @MainActor
    func testTwoGameStoresShareProgressWithoutLosingParallelXP() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let deviceA = GameStore(saveURL: directory.appendingPathComponent("a.json"), now: { self.fixedDate })
        let deviceB = GameStore(saveURL: directory.appendingPathComponent("b.json"), now: { self.fixedDate })
        answerCorrectly(deviceA, count: 1)
        answerCorrectly(deviceB, count: 2)
        let earnedA = deviceA.progress.totalXP
        let earnedB = deviceB.progress.totalXP
        XCTAssertGreaterThan(earnedA, 0)
        XCTAssertGreaterThan(earnedB, earnedA)

        let cloud = FakeCloud()
        deviceA.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)
        deviceB.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "B", throttle: 0)

        XCTAssertEqual(deviceA.progress.totalXP, earnedA + earnedB)
        XCTAssertEqual(deviceB.progress.totalXP, earnedA + earnedB)
        XCTAssertEqual(deviceA.progress.answeredQuestions, 3)
        XCTAssertEqual(deviceB.progress.answeredQuestions, 3)
        XCTAssertEqual(deviceA.learning, deviceB.learning)

        // Further progress on one device reaches the other and is counted once.
        deviceA.nextQuestion()
        deviceA.answer(try XCTUnwrap(deviceA.currentQuestion).correctAnswer)
        XCTAssertGreaterThan(deviceA.progress.totalXP, earnedA + earnedB)
        XCTAssertEqual(deviceB.progress.totalXP, deviceA.progress.totalXP)
    }

    @MainActor
    func testMergedProgressSurvivesRestart() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let urlA = directory.appendingPathComponent("a.json")
        let deviceA = GameStore(saveURL: urlA, now: { self.fixedDate })
        let deviceB = GameStore(saveURL: directory.appendingPathComponent("b.json"), now: { self.fixedDate })
        answerCorrectly(deviceA, count: 1)
        answerCorrectly(deviceB, count: 1)
        let expected = deviceA.progress.totalXP + deviceB.progress.totalXP

        let cloud = FakeCloud()
        deviceA.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)
        deviceB.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "B", throttle: 0)
        XCTAssertEqual(deviceA.progress.totalXP, expected)

        let reloaded = GameStore(saveURL: urlA, now: { self.fixedDate })
        XCTAssertEqual(reloaded.progress.totalXP, expected)
        // Restarting with sync on must not count the other device's share a second time.
        reloaded.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)
        XCTAssertEqual(reloaded.progress.totalXP, expected)
    }

    @MainActor
    func testResetOnOneDeviceResetsTheOthers() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let deviceA = GameStore(saveURL: directory.appendingPathComponent("a.json"), now: { self.fixedDate })
        let deviceB = GameStore(saveURL: directory.appendingPathComponent("b.json"), now: { self.fixedDate })
        answerCorrectly(deviceA, count: 1)
        answerCorrectly(deviceB, count: 1)
        let cloud = FakeCloud()
        deviceA.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)
        deviceB.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "B", throttle: 0)
        XCTAssertGreaterThan(deviceA.progress.totalXP, 0)

        deviceB.resetProgress()

        XCTAssertEqual(deviceB.progress.totalXP, 0)
        XCTAssertEqual(deviceA.progress.totalXP, 0)
        XCTAssertTrue(deviceA.learning.isEmpty)
        // Progress earned afterwards counts again on both.
        deviceA.nextQuestion()
        deviceA.answer(try XCTUnwrap(deviceA.currentQuestion).correctAnswer)
        XCTAssertGreaterThan(deviceA.progress.totalXP, 0)
        XCTAssertEqual(deviceB.progress.totalXP, deviceA.progress.totalXP)
    }

    @MainActor
    func testResetWithoutSyncDoesNotWipeOtherDevicesLater() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let deviceA = GameStore(saveURL: directory.appendingPathComponent("a.json"), now: { self.fixedDate })
        let deviceB = GameStore(saveURL: directory.appendingPathComponent("b.json"), now: { self.fixedDate })
        answerCorrectly(deviceB, count: 2)
        deviceA.resetProgress() // never synced: must not look like a reset of the whole account
        let earnedB = deviceB.progress.totalXP

        let cloud = FakeCloud()
        deviceB.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "B", throttle: 0)
        deviceA.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)

        XCTAssertEqual(deviceA.progress.totalXP, earnedB)
        XCTAssertEqual(deviceB.progress.totalXP, earnedB)
    }

    @MainActor
    func testDamagedSaveNeverPublishesOrMerges() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("a.json")
        try Data("kaputt".utf8).write(to: url)
        let store = GameStore(saveURL: url, now: { self.fixedDate })
        XCTAssertNotNil(store.saveError)

        let cloud = FakeCloud()
        let other = GameStore(saveURL: directory.appendingPathComponent("b.json"), now: { self.fixedDate })
        answerCorrectly(other, count: 1)
        other.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "B", throttle: 0)
        store.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)

        XCTAssertEqual(store.progress.totalXP, 0)
        XCTAssertEqual(try Data(contentsOf: url), Data("kaputt".utf8))
        let payload = try JSONDecoder().decode(SyncPayload.self, from: try XCTUnwrap(cloud.values["sync.port"]))
        XCTAssertNil(payload.devices["A"])
    }

    @MainActor
    func testInvalidRemoteDataIsIgnored() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = GameStore(saveURL: directory.appendingPathComponent("a.json"), now: { self.fixedDate })
        answerCorrectly(store, count: 1)
        let before = store.progress

        let cloud = FakeCloud()
        cloud.values["sync.port"] = Data("{ kein gültiges json".utf8)
        store.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)
        XCTAssertEqual(store.progress, before)

        var negative = SyncPayload()
        var counters = ProgressCounters()
        counters.totalXP = -10
        negative.devices["B"] = counters
        cloud.values["sync.port"] = try JSONEncoder().encode(negative)
        cloud.clients[0].setObserver(forKey: "sync.port", nil)
        store.disableSync()
        store.enableSync(backend: cloud.clients[0], deviceID: "A", throttle: 0)
        XCTAssertEqual(store.progress, before)
    }

    @MainActor
    func testLegacySaveWithoutSyncFieldStillLoadsAndKeepsItsXP() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("a.json")
        let legacy = """
        {"progress":{"totalXP":120,"completedRounds":1,"bestScore":500,"correctAnswers":4,"answeredQuestions":6}}
        """
        try Data(legacy.utf8).write(to: url)
        let store = GameStore(saveURL: url, now: { self.fixedDate })
        XCTAssertNil(store.saveError)
        XCTAssertEqual(store.progress.totalXP, 120)

        let cloud = FakeCloud()
        store.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)
        let payload = try JSONDecoder().decode(SyncPayload.self, from: try XCTUnwrap(cloud.values["sync.port"]))
        XCTAssertEqual(payload.devices["A"]?.totalXP, 120)
    }

    @MainActor
    func testSubnetStoresShareProgress() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let deviceA = SubnetStore(saveURL: directory.appendingPathComponent("a.json"), now: { self.fixedDate })
        let deviceB = SubnetStore(saveURL: directory.appendingPathComponent("b.json"), now: { self.fixedDate })
        for store in [deviceA, deviceB] {
            store.startRound()
            store.answer(try XCTUnwrap(store.currentQuestion).correctAnswer)
        }
        let expected = deviceA.progress.totalXP + deviceB.progress.totalXP

        let cloud = FakeCloud()
        deviceA.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)
        deviceB.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "B", throttle: 0)
        XCTAssertEqual(deviceA.progress.totalXP, expected)
        XCTAssertEqual(deviceB.progress.totalXP, expected)
        XCTAssertNotNil(cloud.values["sync.subnet"])
    }

    @MainActor
    func testExamHistoryAndProgressSync() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let deviceA = ExamStore(saveURL: directory.appendingPathComponent("a.json"), now: { self.fixedDate })
        let deviceB = ExamStore(saveURL: directory.appendingPathComponent("b.json"), now: { self.fixedDate })
        for store in [deviceA, deviceB] {
            store.start(mode: .quiz, subject: .it, topic: nil)
            let task = try XCTUnwrap(store.session(for: .quiz)?.currentTask)
            store.answer(task.solution, mode: .quiz)
        }
        let expected = deviceA.progress.totalXP + deviceB.progress.totalXP

        let cloud = FakeCloud()
        deviceA.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "A", throttle: 0)
        deviceB.enableSync(backend: FakeBackend(cloud: cloud), deviceID: "B", throttle: 0)
        XCTAssertEqual(deviceA.progress.totalXP, expected)
        XCTAssertEqual(deviceB.progress.totalXP, expected)
        XCTAssertNotNil(cloud.values["sync.exam"])
        // A running round is never synced.
        XCTAssertTrue(deviceA.hasActiveSession(.quiz))
    }
}
