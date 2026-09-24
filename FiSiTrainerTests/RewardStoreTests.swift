// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

final class RewardStoreTests: XCTestCase {
    func testRoadmapHasOneHundredUniqueLevelsAndMatchingRankMilestones() {
        XCTAssertEqual(LevelReward.all.map(\.level), Array(1...100))
        XCTAssertEqual(RewardBadge.all.map(\.level),
                       [12, 18, 24, 30, 40, 50, 60, 70, 80, 90, 100])
        for level in [1, 3, 7, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100] {
            XCTAssertEqual(LevelReward.all[level - 1].title, LevelReward.rankTitle(for: level))
        }
        XCTAssertEqual(LevelReward.rankTitle(for: 101), "FiSi-Legende")
        for level in [4, 6, 16, 22, 35, 45, 75, 90] {
            XCTAssertTrue(LevelReward.all[level - 1].isFeatured)
        }
    }

    @MainActor
    func testBadgesAndNextFeaturedRewardAreDerivedFromSavedXP() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let rewards = RewardStore(saveURL: url)
        XCTAssertEqual(rewards.nextReward?.level, 2)
        XCTAssertEqual(rewards.xpToNextReward, 250)
        XCTAssertTrue(rewards.earnedBadges.isEmpty)

        rewards.updateXP(2_750) // Level 12
        XCTAssertEqual(rewards.level, 12)
        XCTAssertEqual(rewards.earnedBadges.map(\.name), ["Spürnase"])
        XCTAssertEqual(rewards.nextReward?.level, 15)
        XCTAssertEqual(rewards.xpToNextReward, 750)
        XCTAssertEqual(RewardStore(saveURL: url).earnedBadges.map(\.level), [12])

        rewards.updateXP(7_250) // Level 30
        XCTAssertEqual(rewards.earnedBadges.map(\.level), [12, 18, 24, 30])
        XCTAssertEqual(rewards.rankTitle, "Netzwerk-Legende")
        XCTAssertEqual(rewards.nextReward?.level, 35)
        XCTAssertEqual(rewards.xpToNextReward, 1_250)

        rewards.updateXP(24_750) // Level 100
        XCTAssertEqual(rewards.earnedBadges.map(\.level), RewardBadge.all.map(\.level))
        XCTAssertEqual(rewards.rankTitle, "FiSi-Legende")
        XCTAssertNil(rewards.nextReward)
        XCTAssertNil(rewards.xpToNextReward)
        rewards.updateXP(25_000)
        XCTAssertEqual(rewards.level, 101) // Leveling continues beyond the roadmap.
    }

    @MainActor
    func testUnlockThresholdsAndFirstPetSelection() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let rewards = RewardStore(saveURL: url)

        XCTAssertEqual(rewards.level, 1)
        XCTAssertTrue(rewards.unlockedPets.isEmpty)
        XCTAssertNil(rewards.selectedPet)
        rewards.updateXP(249)
        XCTAssertTrue(rewards.unlockedPets.isEmpty)
        rewards.updateXP(250)
        XCTAssertEqual(rewards.level, 2)
        XCTAssertEqual(rewards.unlockedPets, [.cat])
        XCTAssertEqual(rewards.selectedPet, .cat)
        rewards.updateXP(999)
        XCTAssertEqual(rewards.unlockedPets, [.cat])
        rewards.updateXP(1_000)
        XCTAssertEqual(rewards.level, 5)
        XCTAssertEqual(rewards.unlockedPets, [.cat, .fox])
        rewards.updateXP(2_250)
        XCTAssertEqual(rewards.level, 10)
        XCTAssertEqual(rewards.unlockedPets, PetKind.allCases)
    }

    @MainActor
    func testLockedPetCannotBeSelectedOrInteractedWith() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let rewards = RewardStore(saveURL: url)
        rewards.selectPet(.dragon)
        rewards.interact(.feed)
        XCTAssertNil(rewards.selectedPet)
        XCTAssertEqual(rewards.bond, 0)

        rewards.updateXP(250)
        rewards.selectPet(.fox)
        XCTAssertEqual(rewards.selectedPet, .cat)
        rewards.interact(.pet)
        XCTAssertEqual(rewards.bond, 1)
        XCTAssertEqual(rewards.count(.pet, for: .fox), 0)
    }

    @MainActor
    func testXPIsMonotonicAndIdempotentAcrossResets() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let rewards = RewardStore(saveURL: url)
        rewards.updateXP(1_000)
        rewards.updateXP(0)
        rewards.updateXP(1_000)
        rewards.updateXP(-20)
        XCTAssertEqual(rewards.totalXP, 1_000)
        XCTAssertEqual(rewards.level, 5)
        XCTAssertEqual(RewardStore(saveURL: url).totalXP, 1_000)
    }

    @MainActor
    func testSelectionAndBondPersistForEachPet() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let rewards = RewardStore(saveURL: url)
        rewards.updateXP(1_000)
        rewards.interact(.pet)
        rewards.selectPet(.fox)
        rewards.interact(.feed)
        rewards.interact(.play)

        let reloaded = RewardStore(saveURL: url)
        XCTAssertEqual(reloaded.selectedPet, .fox)
        XCTAssertEqual(reloaded.bond, 2)
        XCTAssertEqual(reloaded.count(.pet, for: .cat), 1)
        XCTAssertEqual(reloaded.count(.feed, for: .fox), 1)
        reloaded.selectPet(.cat)
        XCTAssertEqual(reloaded.bond, 1)
    }

    @MainActor
    func testEquipmentRequiresUnlockedPetAndLevelAndPersistsPerPet() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let rewards = RewardStore(saveURL: url)
        rewards.equipOutfit(.bandana, for: .cat)
        rewards.equipToy(.ball, for: .cat)
        XCTAssertNil(rewards.outfit(for: .cat))
        XCTAssertNil(rewards.toy(for: .cat))

        rewards.updateXP(750) // Level 4: cat and bandana unlocked, ball still locked.
        rewards.equipOutfit(.bandana, for: .cat)
        rewards.equipOutfit(.crown, for: .cat)
        rewards.equipToy(.ball, for: .cat)
        rewards.equipOutfit(.bandana, for: .fox)
        XCTAssertEqual(rewards.outfit(for: .cat), .bandana)
        XCTAssertNil(rewards.toy(for: .cat))
        XCTAssertNil(rewards.outfit(for: .fox))

        rewards.updateXP(5_250) // Level 22: fox and yarn unlocked.
        rewards.equipOutfit(.scarf, for: .fox)
        rewards.equipToy(.yarn, for: .fox)
        rewards.equipToy(.ball, for: .cat)
        let reloaded = RewardStore(saveURL: url)
        XCTAssertEqual(reloaded.outfit(for: .cat), .bandana)
        XCTAssertEqual(reloaded.toy(for: .cat), .ball)
        XCTAssertEqual(reloaded.outfit(for: .fox), .scarf)
        XCTAssertEqual(reloaded.toy(for: .fox), .yarn)
        XCTAssertNil(reloaded.outfit(for: .dragon))

        reloaded.equipOutfit(nil, for: .cat)
        reloaded.equipToy(nil, for: .fox)
        XCTAssertNil(RewardStore(saveURL: url).outfit(for: .cat))
        XCTAssertNil(RewardStore(saveURL: url).toy(for: .fox))
    }

    @MainActor
    func testUnknownOrLockedEquipmentInOldSaveIsIgnored() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try Data(#"{"totalXP":1000,"outfitsByPet":{"cat":"bandana","fox":"crown","unknown":"scarf"},"toysByPet":{"cat":"rocket","fox":"ball","dragon":"yarn"}}"#.utf8)
            .write(to: url, options: .atomic)
        let rewards = RewardStore(saveURL: url)
        XCTAssertNil(rewards.saveError)
        XCTAssertEqual(rewards.outfit(for: .cat), .bandana)
        XCTAssertNil(rewards.outfit(for: .fox))
        XCTAssertNil(rewards.toy(for: .cat))
        XCTAssertNil(rewards.toy(for: .fox)) // Ball unlocks at 6; this save is level 5.
        XCTAssertTrue(rewards.outfitsByPet.keys.allSatisfy { PetKind(rawValue: $0) != nil })
    }

    @MainActor
    func testLegacyStartupWithoutRewardFileAndOlderRewardSchema() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let fresh = RewardStore(saveURL: url)
        XCTAssertEqual(fresh.totalXP, 0)
        XCTAssertNil(fresh.saveError)
        fresh.updateXP(300) // Combined XP imported from existing training saves.
        XCTAssertEqual(fresh.selectedPet, .cat)

        try Data(#"{"totalXP":1000}"#.utf8).write(to: url, options: .atomic)
        let legacy = RewardStore(saveURL: url)
        XCTAssertEqual(legacy.level, 5)
        XCTAssertEqual(legacy.selectedPet, .cat)
        XCTAssertEqual(legacy.bond, 0)
        XCTAssertNil(legacy.outfit(for: .cat))
        XCTAssertNil(legacy.toy(for: .cat))
        XCTAssertNil(legacy.saveError)
    }

    @MainActor
    func testCorruptSaveIsPreservedUntilExplicitRecovery() throws {
        let url = try temporarySaveURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let damaged = Data("broken rewards".utf8)
        try damaged.write(to: url)
        let rewards = RewardStore(saveURL: url)
        XCTAssertNotNil(rewards.saveError)
        XCTAssertTrue(rewards.needsRecovery)
        rewards.updateXP(2_250)
        XCTAssertEqual(rewards.totalXP, 0)
        XCTAssertEqual(try Data(contentsOf: url), damaged)

        rewards.resetCorruptSave()
        XCTAssertNil(rewards.saveError)
        XCTAssertFalse(rewards.needsRecovery)
        XCTAssertEqual(rewards.totalXP, 0)
        let backups = try FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(),
                                                                   includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("rewards.corrupt.") }
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: backups[0]), damaged)
    }

    @MainActor
    func testWriteFailureCanBeRetriedWithoutLosingEarnedRewards() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RewardStoreTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let blockedParent = directory.appendingPathComponent("blocked")
        try Data("file".utf8).write(to: blockedParent)
        let url = blockedParent.appendingPathComponent("rewards.json")
        let rewards = RewardStore(saveURL: url)
        rewards.updateXP(1_000)
        XCTAssertEqual(rewards.totalXP, 1_000)
        XCTAssertNotNil(rewards.saveError)
        XCTAssertFalse(rewards.needsRecovery)

        try FileManager.default.removeItem(at: blockedParent)
        try FileManager.default.createDirectory(at: blockedParent, withIntermediateDirectories: true)
        rewards.retrySave()
        XCTAssertNil(rewards.saveError)
        XCTAssertEqual(RewardStore(saveURL: url).totalXP, 1_000)
    }

    private func temporarySaveURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RewardStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("rewards.json")
    }
}
