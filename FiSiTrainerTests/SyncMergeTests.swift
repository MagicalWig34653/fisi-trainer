// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

final class SyncMergeTests: XCTestCase {
    private func state(xp: Int = 0, rounds: Int = 0, correct: Int = 0, answered: Int = 0,
                       best: Int = 0, peers: [String: ProgressCounters] = [:],
                       epoch: Int = 0) -> SyncState {
        var progress = PlayerProgress()
        progress.totalXP = xp
        progress.completedRounds = rounds
        progress.correctAnswers = correct
        progress.answeredQuestions = answered
        progress.bestScore = best
        var result = SyncState()
        result.progress = progress
        result.bookkeeping = SyncBookkeeping(epoch: epoch, peers: peers)
        return result
    }

    private func counters(xp: Int = 0, rounds: Int = 0, correct: Int = 0, answered: Int = 0,
                          best: Int = 0) -> ProgressCounters {
        var result = ProgressCounters()
        result.totalXP = xp
        result.completedRounds = rounds
        result.correctAnswers = correct
        result.answeredQuestions = answered
        result.bestScore = best
        return result
    }

    private func record(attempts: Int, correct: Int) -> LearningRecord {
        var result = LearningRecord()
        for index in 0..<attempts { result.record(correct: index < correct) }
        return result
    }

    func testPayloadPublishesOnlyOwnShare() {
        let local = state(xp: 150, peers: ["B": counters(xp: 50)])
        let payload = SyncMerge.payload(for: local, deviceID: "A")
        XCTAssertEqual(payload.devices["A"]?.totalXP, 100)
        XCTAssertEqual(payload.devices["B"]?.totalXP, 50)
    }

    func testPeerContributionIsAddedOnceAndRepeatingIsHarmless() {
        let local = state(xp: 100)
        var remote = SyncPayload()
        remote.devices["B"] = counters(xp: 50, rounds: 1, correct: 3, answered: 4, best: 700)
        let first = SyncMerge.merged(local, with: remote, deviceID: "A")
        XCTAssertEqual(first.progress.totalXP, 150)
        XCTAssertEqual(first.progress.completedRounds, 1)
        XCTAssertEqual(first.progress.bestScore, 700)
        let second = SyncMerge.merged(first, with: remote, deviceID: "A")
        XCTAssertEqual(second, first)
    }

    func testNewerPeerValuesOnlyAddTheDifference() {
        var remote = SyncPayload()
        remote.devices["B"] = counters(xp: 50)
        var merged = SyncMerge.merged(state(xp: 100), with: remote, deviceID: "A")
        remote.devices["B"] = counters(xp: 80)
        merged = SyncMerge.merged(merged, with: remote, deviceID: "A")
        XCTAssertEqual(merged.progress.totalXP, 180)
        remote.devices["B"] = counters(xp: 60) // stale value never lowers the total
        merged = SyncMerge.merged(merged, with: remote, deviceID: "A")
        XCTAssertEqual(merged.progress.totalXP, 180)
    }

    func testTwoDevicesConvergeInEitherOrderWithoutLosingParallelXP() {
        let deviceA = state(xp: 100, rounds: 2, correct: 8, answered: 10, best: 900)
        let deviceB = state(xp: 70, rounds: 1, correct: 5, answered: 6, best: 1100)
        let fromA = SyncMerge.payload(for: deviceA, deviceID: "A")
        let fromB = SyncMerge.payload(for: deviceB, deviceID: "B")

        let aAfterB = SyncMerge.merged(deviceA, with: fromB, deviceID: "A")
        let bAfterA = SyncMerge.merged(deviceB, with: fromA, deviceID: "B")
        XCTAssertEqual(aAfterB.progress, bAfterA.progress)
        XCTAssertEqual(aAfterB.progress.totalXP, 170)
        XCTAssertEqual(aAfterB.progress.completedRounds, 3)
        XCTAssertEqual(aAfterB.progress.bestScore, 1100)

        // Exchanging the merged payloads again changes nothing.
        let republishedA = SyncMerge.payload(for: aAfterB, deviceID: "A")
        let republishedB = SyncMerge.payload(for: bAfterA, deviceID: "B")
        XCTAssertEqual(SyncMerge.merged(aAfterB, with: republishedB, deviceID: "A"), aAfterB)
        XCTAssertEqual(SyncMerge.merged(bAfterA, with: republishedA, deviceID: "B"), bAfterA)
        XCTAssertEqual(republishedA.devices, republishedB.devices)
    }

    func testOwnOldEntryInMergedPayloadDoesNotDoubleCount() {
        let deviceA = state(xp: 100)
        let published = SyncMerge.payload(for: deviceA, deviceID: "A")
        let deviceB = SyncMerge.merged(state(xp: 50), with: published, deviceID: "B")
        let fromB = SyncMerge.payload(for: deviceB, deviceID: "B")
        let aAfter = SyncMerge.merged(deviceA, with: fromB, deviceID: "A")
        XCTAssertEqual(aAfter.progress.totalXP, 150)
    }

    func testRestoredDeviceTakesOverHigherOwnShare() {
        var remote = SyncPayload()
        remote.devices["A"] = counters(xp: 400, best: 500)
        let merged = SyncMerge.merged(state(xp: 100), with: remote, deviceID: "A")
        XCTAssertEqual(merged.progress.totalXP, 400)
        XCTAssertEqual(merged.progress.bestScore, 500)
    }

    func testLearningKeepsRecordWithMoreAttempts() {
        var local = state()
        local.learning = ["k1": record(attempts: 2, correct: 1), "k2": record(attempts: 5, correct: 5)]
        var remote = SyncPayload()
        remote.learning = ["k1": record(attempts: 4, correct: 3), "k2": record(attempts: 1, correct: 0),
                           "k3": record(attempts: 1, correct: 1)]
        let merged = SyncMerge.merged(local, with: remote, deviceID: "A")
        XCTAssertEqual(merged.learning["k1"]?.attempts, 4)
        XCTAssertEqual(merged.learning["k2"]?.attempts, 5)
        XCTAssertEqual(merged.learning["k3"]?.attempts, 1)
    }

    func testHistoryIsUnionWithoutDuplicatesNewestFirstAndCapped() {
        func result(_ offset: TimeInterval) -> ExamResult {
            ExamResult(date: Date(timeIntervalSince1970: 1_000_000 + offset), subject: .wiso,
                       percent: 80, duration: 600)
        }
        var local = state()
        local.history = (0..<15).map { result(TimeInterval($0)) }
        var remote = SyncPayload()
        remote.history = (10..<20).map { result(TimeInterval($0)) }
        let merged = SyncMerge.merged(local, with: remote, deviceID: "A")
        XCTAssertEqual(merged.history.count, 20)
        XCTAssertEqual(Set(merged.history.map(\.date)).count, 20)
        XCTAssertEqual(merged.history.first, result(19))
    }

    func testHigherEpochDiscardsEarlierDataAndLowerEpochIsIgnored() {
        let local = state(xp: 500, peers: ["B": counters(xp: 200)], epoch: 1)
        var reset = SyncPayload()
        reset.epoch = 2
        reset.devices["C"] = counters(xp: 30)
        reset.learning = ["k": record(attempts: 1, correct: 1)]
        let adopted = SyncMerge.merged(local, with: reset, deviceID: "A")
        XCTAssertEqual(adopted.bookkeeping.epoch, 2)
        XCTAssertEqual(adopted.progress.totalXP, 30)
        XCTAssertEqual(Array(adopted.bookkeeping.peers.keys), ["C"])
        XCTAssertEqual(adopted.learning.count, 1)

        var stale = SyncPayload()
        stale.epoch = 0
        stale.devices["B"] = counters(xp: 9_999)
        XCTAssertEqual(SyncMerge.merged(adopted, with: stale, deviceID: "A"), adopted)
    }

    func testResetBookkeepingStartsNewEpochWithoutPeers() {
        let reset = SyncMerge.resetBookkeeping(SyncBookkeeping(epoch: 3, peers: ["B": counters(xp: 5)]))
        XCTAssertEqual(reset.epoch, 4)
        XCTAssertTrue(reset.peers.isEmpty)
    }

    func testInvalidRemoteDataIsIgnored() {
        let local = state(xp: 100)
        var negative = SyncPayload()
        negative.devices["B"] = counters(xp: -5)
        XCTAssertFalse(negative.isValid)
        XCTAssertEqual(SyncMerge.merged(local, with: negative, deviceID: "A"), local)

        var impossible = SyncPayload()
        impossible.devices["B"] = counters(correct: 5, answered: 2)
        XCTAssertFalse(impossible.isValid)

        var huge = SyncPayload()
        huge.devices["B"] = counters(xp: ProgressCounters.limit + 1)
        XCTAssertFalse(huge.isValid)
        XCTAssertEqual(SyncMerge.merged(local, with: huge, deviceID: "A"), local)

        var tooMany = SyncPayload()
        for index in 0...SyncPayload.maxDevices { tooMany.devices["D\(index)"] = counters() }
        XCTAssertFalse(tooMany.isValid)
    }

    func testPayloadRoundTripsThroughJSON() throws {
        var local = state(xp: 40, rounds: 1, correct: 2, answered: 3, best: 300)
        local.learning = ["k": record(attempts: 3, correct: 2)]
        let payload = SyncMerge.payload(for: local, deviceID: "A")
        let decoded = try JSONDecoder().decode(SyncPayload.self, from: JSONEncoder().encode(payload))
        XCTAssertEqual(decoded, payload)
        XCTAssertTrue(decoded.isValid)
    }
}
