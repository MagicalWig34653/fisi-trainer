// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

final class RewardSyncMergeTests: XCTestCase {
    private func choice(_ value: String?, at time: TimeInterval) -> RewardSyncChoice {
        RewardSyncChoice(value: value, at: time)
    }

    func testInteractionCountsTakeTheMaximumPerKey() {
        var a = RewardSyncData()
        a.interactions = ["cat": ["pet": 5, "feed": 1]]
        var b = RewardSyncData()
        b.interactions = ["cat": ["pet": 3, "play": 4], "fox": ["feed": 2]]

        let merged = a.merged(with: b)

        XCTAssertEqual(merged.interactions, ["cat": ["pet": 5, "feed": 1, "play": 4], "fox": ["feed": 2]])
    }

    func testNewerChoiceWinsInEitherOrder() {
        var a = RewardSyncData()
        a.outfits = ["cat": choice("bandana", at: 10)]
        a.selectedPet = choice("cat", at: 10)
        var b = RewardSyncData()
        b.outfits = ["cat": choice("scarf", at: 20)]
        b.selectedPet = choice("fox", at: 5)

        for merged in [a.merged(with: b), b.merged(with: a)] {
            XCTAssertEqual(merged.outfits["cat"]?.value, "scarf")
            XCTAssertEqual(merged.selectedPet?.value, "cat")
        }
    }

    func testRemovingAnItemIsAChoiceToo() {
        var a = RewardSyncData()
        a.toys = ["cat": choice("ball", at: 10)]
        var b = RewardSyncData()
        b.toys = ["cat": choice(nil, at: 20)]

        XCTAssertNil(a.merged(with: b).toys["cat"]?.value)
        XCTAssertNotNil(a.merged(with: b).toys["cat"])
        XCTAssertEqual(a.merged(with: b), b.merged(with: a))
    }

    func testEqualTimestampsStillConverge() {
        var a = RewardSyncData()
        a.outfits = ["cat": choice("bandana", at: 10)]
        var b = RewardSyncData()
        b.outfits = ["cat": choice("scarf", at: 10)]
        var c = RewardSyncData()
        c.outfits = ["cat": choice(nil, at: 10)]

        XCTAssertEqual(a.merged(with: b), b.merged(with: a))
        XCTAssertEqual(a.merged(with: c), c.merged(with: a))
        XCTAssertEqual(a.merged(with: b).merged(with: c), a.merged(with: c.merged(with: b)))
    }

    func testMergingIsIdempotent() {
        var a = RewardSyncData()
        a.selectedPet = choice("dragon", at: 3)
        a.outfits = ["dragon": choice("crown", at: 4)]
        a.interactions = ["dragon": ["play": 9]]

        XCTAssertEqual(a.merged(with: a), a)
        XCTAssertEqual(a.merged(with: RewardSyncData()), a)
    }

    func testValidityRejectsDataThisAppCouldNotHaveWritten() {
        XCTAssertTrue(RewardSyncData().isValid)

        var unknownPet = RewardSyncData()
        unknownPet.interactions = ["hamster": ["pet": 1]]
        XCTAssertFalse(unknownPet.isValid)

        var negative = RewardSyncData()
        negative.interactions = ["cat": ["pet": -1]]
        XCTAssertFalse(negative.isValid)

        var unknownAction = RewardSyncData()
        unknownAction.interactions = ["cat": ["dance": 1]]
        XCTAssertFalse(unknownAction.isValid)

        var unknownOutfit = RewardSyncData()
        unknownOutfit.outfits = ["cat": choice("tophat", at: 1)]
        XCTAssertFalse(unknownOutfit.isValid)

        var unknownToy = RewardSyncData()
        unknownToy.toys = ["cat": choice("laser", at: 1)]
        XCTAssertFalse(unknownToy.isValid)

        var badTime = RewardSyncData()
        badTime.selectedPet = choice("cat", at: -1)
        XCTAssertFalse(badTime.isValid)

        var notFinite = RewardSyncData()
        notFinite.selectedPet = choice("cat", at: .infinity)
        XCTAssertFalse(notFinite.isValid)

        var huge = RewardSyncData()
        huge.interactions = ["cat": ["pet": ProgressCounters.limit + 1]]
        XCTAssertFalse(huge.isValid)
    }
}

final class RewardStoreSyncTests: XCTestCase {
    private var directory: URL!
    private var time = Date(timeIntervalSince1970: 1_000)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
    }

    /// A store far enough in the roadmap that every pet, outfit and toy is unlocked.
    @MainActor
    private func makeStore(_ name: String, xp: Int = 250 * 99) -> RewardStore {
        let store = RewardStore(saveURL: directory.appendingPathComponent("\(name).json"),
                                now: { self.time })
        store.updateXP(xp)
        return store
    }

    @MainActor
    private func connect(_ store: RewardStore, _ cloud: FakeCloud) {
        store.enableSync(backend: FakeBackend(cloud: cloud), throttle: 0)
    }

    private func tick() { time = time.addingTimeInterval(10) }

    @MainActor
    func testEquipmentAndSelectionReachTheOtherDevice() {
        let deviceA = makeStore("a")
        let deviceB = makeStore("b")
        let cloud = FakeCloud()
        connect(deviceA, cloud)
        connect(deviceB, cloud)

        deviceA.selectPet(.fox)
        deviceA.equipOutfit(.scarf, for: .fox)
        deviceA.equipToy(.star, for: .fox)

        XCTAssertEqual(deviceB.selectedPet, .fox)
        XCTAssertEqual(deviceB.outfit(for: .fox), .scarf)
        XCTAssertEqual(deviceB.toy(for: .fox), .star)
        XCTAssertNil(deviceB.outfit(for: .cat))
    }

    @MainActor
    func testTheLaterChangeWinsAndRemovingSyncs() {
        let deviceA = makeStore("a")
        let deviceB = makeStore("b")
        let cloud = FakeCloud()
        connect(deviceA, cloud)
        connect(deviceB, cloud)

        deviceA.equipOutfit(.bandana, for: .cat)
        tick()
        deviceB.equipOutfit(.crown, for: .cat)
        XCTAssertEqual(deviceA.outfit(for: .cat), .crown)
        XCTAssertEqual(deviceB.outfit(for: .cat), .crown)

        tick()
        deviceA.equipOutfit(nil, for: .cat)
        XCTAssertNil(deviceA.outfit(for: .cat))
        XCTAssertNil(deviceB.outfit(for: .cat))
    }

    @MainActor
    func testChangesMadeOfflineMergeOnFirstConnection() {
        let deviceA = makeStore("a")
        let deviceB = makeStore("b")
        deviceA.equipOutfit(.bandana, for: .cat)
        tick()
        deviceB.equipOutfit(.scarf, for: .fox)
        tick()
        deviceB.equipOutfit(.crown, for: .cat)

        let cloud = FakeCloud()
        connect(deviceA, cloud)
        connect(deviceB, cloud)

        for device in [deviceA, deviceB] {
            XCTAssertEqual(device.outfit(for: .cat), .crown)
            XCTAssertEqual(device.outfit(for: .fox), .scarf)
        }
    }

    @MainActor
    func testBondCountsTakeTheMaximum() {
        let deviceA = makeStore("a")
        let deviceB = makeStore("b")
        deviceA.selectPet(.cat)
        deviceB.selectPet(.cat)
        for _ in 0..<3 { deviceA.interact(.pet) }
        for _ in 0..<5 { deviceB.interact(.pet) }
        deviceB.interact(.feed)

        let cloud = FakeCloud()
        connect(deviceA, cloud)
        connect(deviceB, cloud)

        XCTAssertEqual(deviceA.count(.pet, for: .cat), 5)
        XCTAssertEqual(deviceA.count(.feed, for: .cat), 1)
        XCTAssertEqual(deviceB.count(.pet, for: .cat), 5)
    }

    @MainActor
    func testLockedEquipmentAndPetsFromAnotherDeviceStayHidden() {
        let deviceA = makeStore("a")
        let beginner = makeStore("b", xp: 250) // level 2: only the cat
        XCTAssertEqual(beginner.selectedPet, .cat)
        let cloud = FakeCloud()
        connect(deviceA, cloud)
        connect(beginner, cloud)

        deviceA.selectPet(.dragon)
        deviceA.equipOutfit(.crown, for: .cat)

        XCTAssertEqual(beginner.selectedPet, .cat)
        XCTAssertNil(beginner.outfit(for: .cat))
        XCTAssertNil(beginner.outfit(for: .dragon))
    }

    @MainActor
    func testStampsSurviveARestartWithoutOverridingNewerChanges() {
        let deviceA = makeStore("a")
        let cloud = FakeCloud()
        connect(deviceA, cloud)
        deviceA.equipOutfit(.bandana, for: .cat)
        tick()
        let deviceB = makeStore("b")
        connect(deviceB, cloud)
        deviceB.equipOutfit(.crown, for: .cat)

        let reloaded = RewardStore(saveURL: directory.appendingPathComponent("a.json"), now: { self.time })
        XCTAssertEqual(reloaded.outfit(for: .cat), .crown)
        reloaded.enableSync(backend: FakeBackend(cloud: cloud), throttle: 0)
        XCTAssertEqual(reloaded.outfit(for: .cat), .crown)
        XCTAssertEqual(deviceB.outfit(for: .cat), .crown)
    }

    @MainActor
    func testSaveWithoutSyncFieldStillLoadsAndPublishesNothingBogus() throws {
        let url = directory.appendingPathComponent("legacy.json")
        try Data(#"{"totalXP":5000,"outfitsByPet":{"cat":"bandana"}}"#.utf8).write(to: url)
        let store = RewardStore(saveURL: url, now: { self.time })
        XCTAssertNil(store.saveError)
        XCTAssertEqual(store.outfit(for: .cat), .bandana)

        let cloud = FakeCloud()
        connect(store, cloud)
        let remote = FakeBackend(cloud: cloud)
        // Without a stamp the old choice has no claim against newer data from another device.
        var data = RewardSyncData()
        data.outfits["cat"] = RewardSyncChoice(value: "scarf", at: 1)
        remote.write(try JSONEncoder().encode(data), forKey: "sync.rewards")
        XCTAssertEqual(store.outfit(for: .cat), .scarf)
    }

    @MainActor
    func testDamagedSaveNeverPublishesOrMerges() throws {
        let url = directory.appendingPathComponent("broken.json")
        try Data("kaputt".utf8).write(to: url)
        let store = RewardStore(saveURL: url, now: { self.time })
        XCTAssertNotNil(store.saveError)

        let cloud = FakeCloud()
        let other = makeStore("b")
        connect(other, cloud)
        other.equipOutfit(.scarf, for: .cat)
        connect(store, cloud)

        XCTAssertNil(store.outfit(for: .cat))
        XCTAssertEqual(try Data(contentsOf: url), Data("kaputt".utf8))
    }

    @MainActor
    func testInvalidRemoteDataIsIgnored() throws {
        let store = makeStore("a")
        store.equipOutfit(.bandana, for: .cat)
        let cloud = FakeCloud()
        cloud.values["sync.rewards"] = Data("{ kein json".utf8)
        connect(store, cloud)
        XCTAssertEqual(store.outfit(for: .cat), .bandana)

        var bad = RewardSyncData()
        bad.interactions = ["hamster": ["pet": 1]]
        bad.outfits["cat"] = RewardSyncChoice(value: "scarf", at: 9_999_999)
        let remote = FakeBackend(cloud: cloud)
        remote.write(try JSONEncoder().encode(bad), forKey: "sync.rewards")
        XCTAssertEqual(store.outfit(for: .cat), .bandana)
    }

    @MainActor
    func testRewardXPIsNeverSynchronizedDirectly() throws {
        let deviceA = makeStore("a", xp: 250 * 99)
        let deviceB = makeStore("b", xp: 250)
        let cloud = FakeCloud()
        connect(deviceA, cloud)
        connect(deviceB, cloud)

        XCTAssertEqual(deviceB.totalXP, 250)
        let payload = try XCTUnwrap(cloud.values["sync.rewards"])
        XCTAssertFalse(String(decoding: payload, as: UTF8.self).contains("totalXP"))
    }
}
