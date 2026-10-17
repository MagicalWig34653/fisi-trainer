// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// What the iCloud sync needs to merge, as pure value types so the rules can be tested without iCloud.
///
/// Every device publishes one `SyncPayload` per store. Totals are never overwritten: each device publishes
/// only what *it* earned (`devices[deviceID]`), the others' values are remembered in
/// `SyncBookkeeping.peers`, and the local total is the sum. The local totals keep their existing format.

/// Counters of one device. All fields except `bestScore` are added up across devices.
struct ProgressCounters: Codable, Equatable {
    var totalXP = 0
    var completedRounds = 0
    var correctAnswers = 0
    var answeredQuestions = 0
    var bestScore = 0

    /// Upper bound that keeps sums over all devices far away from `Int` overflow.
    static let limit = 1_000_000_000

    init() {}

    init(_ progress: PlayerProgress) {
        totalXP = progress.totalXP
        completedRounds = progress.completedRounds
        correctAnswers = progress.correctAnswers
        answeredQuestions = progress.answeredQuestions
        bestScore = progress.bestScore
    }

    var isValid: Bool {
        [totalXP, completedRounds, correctAnswers, answeredQuestions, bestScore]
            .allSatisfy { (0...Self.limit).contains($0) } && answeredQuestions >= correctAnswers
    }

    /// The additive fields only. A peer's best score is not remembered per device: `bestScore` of the local
    /// progress already is the maximum over all devices, and remembering it again would make every device
    /// republish the global maximum as its own.
    var additivePart: ProgressCounters {
        var result = self
        result.bestScore = 0
        return result
    }

    /// Field-wise maximum, used to take over a peer's newest published values.
    func maximum(with other: ProgressCounters) -> ProgressCounters {
        var result = ProgressCounters()
        result.totalXP = max(totalXP, other.totalXP)
        result.completedRounds = max(completedRounds, other.completedRounds)
        result.correctAnswers = max(correctAnswers, other.correctAnswers)
        result.answeredQuestions = max(answeredQuestions, other.answeredQuestions)
        result.bestScore = max(bestScore, other.bestScore)
        return result
    }

    /// Additive fields only: how much `self` exceeds `other` (never negative).
    func increase(over other: ProgressCounters) -> ProgressCounters {
        var result = ProgressCounters()
        result.totalXP = max(0, totalXP - other.totalXP)
        result.completedRounds = max(0, completedRounds - other.completedRounds)
        result.correctAnswers = max(0, correctAnswers - other.correctAnswers)
        result.answeredQuestions = max(0, answeredQuestions - other.answeredQuestions)
        return result
    }

    /// Adds the additive fields; `bestScore` takes the larger value.
    func adding(_ other: ProgressCounters) -> ProgressCounters {
        var result = ProgressCounters()
        result.totalXP = totalXP + other.totalXP
        result.completedRounds = completedRounds + other.completedRounds
        result.correctAnswers = correctAnswers + other.correctAnswers
        result.answeredQuestions = answeredQuestions + other.answeredQuestions
        result.bestScore = max(bestScore, other.bestScore)
        return result
    }

    /// Subtracts the additive fields (never below zero); `bestScore` stays.
    func removing(_ other: ProgressCounters) -> ProgressCounters {
        var result = self
        result.totalXP = max(0, totalXP - other.totalXP)
        result.completedRounds = max(0, completedRounds - other.completedRounds)
        result.correctAnswers = max(0, correctAnswers - other.correctAnswers)
        result.answeredQuestions = max(0, answeredQuestions - other.answeredQuestions)
        return result
    }
}

extension PlayerProgress {
    init(_ counters: ProgressCounters) {
        self.init()
        totalXP = counters.totalXP
        completedRounds = counters.completedRounds
        correctAnswers = counters.correctAnswers
        answeredQuestions = counters.answeredQuestions
        bestScore = counters.bestScore
    }
}

/// Stored locally next to the save (optional field, so old saves stay readable).
struct SyncBookkeeping: Codable, Equatable {
    /// Raised by a reset; the higher epoch wins everywhere and discards older data.
    var epoch = 0
    /// Last values published by the other devices; already included in the local totals.
    var peers: [String: ProgressCounters] = [:]
}

/// The blob each device writes to iCloud for one store.
struct SyncPayload: Codable, Equatable {
    var epoch = 0
    var devices: [String: ProgressCounters] = [:]
    var learning: [String: LearningRecord] = [:]
    var history: [ExamResult] = []

    static let maxDevices = 50
    static let maxHistory = 20

    /// Rejects payloads that could not have been produced by this app. Invalid remote data is ignored.
    var isValid: Bool {
        epoch >= 0 && devices.count <= Self.maxDevices &&
            devices.values.allSatisfy(\.isValid) &&
            learning.values.allSatisfy(\.isValid) &&
            history.count <= Self.maxHistory &&
            history.allSatisfy { (0...100).contains($0.percent) && $0.duration >= 0 }
    }
}

/// A store's syncable state.
struct SyncState: Equatable {
    var progress = PlayerProgress()
    var learning: [String: LearningRecord] = [:]
    var history: [ExamResult] = []
    var bookkeeping = SyncBookkeeping()
}

enum SyncMerge {
    /// What this device itself earned: the local total minus everything that came from other devices.
    static func ownCounters(of state: SyncState) -> ProgressCounters {
        let peers = state.bookkeeping.peers.values.reduce(ProgressCounters()) { $0.adding($1) }
        return ProgressCounters(state.progress).removing(peers)
    }

    static func payload(for state: SyncState, deviceID: String) -> SyncPayload {
        var devices = state.bookkeeping.peers
        devices[deviceID] = ownCounters(of: state)
        return SyncPayload(epoch: state.bookkeeping.epoch, devices: devices,
                           learning: state.learning, history: state.history)
    }

    /// Merges what another device published into the local state. Safe to repeat and to apply in any order.
    static func merged(_ local: SyncState, with remote: SyncPayload, deviceID: String) -> SyncState {
        guard remote.isValid, remote.epoch >= local.bookkeeping.epoch else { return local }
        var state = local

        if remote.epoch > local.bookkeeping.epoch {
            // Another device reset: everything from before is discarded, including this device's share.
            var peers = remote.devices
            peers.removeValue(forKey: deviceID)
            state.progress = PlayerProgress(peers.values.reduce(ProgressCounters()) { $0.adding($1) })
            state.bookkeeping = SyncBookkeeping(epoch: remote.epoch, peers: peers.mapValues(\.additivePart))
            state.learning = remote.learning
            state.history = remote.history
            return state
        }

        var counters = ProgressCounters(state.progress)
        for (id, published) in remote.devices where id != deviceID {
            let known = state.bookkeeping.peers[id] ?? ProgressCounters()
            let updated = known.maximum(with: published).additivePart
            if updated != known {
                counters = counters.adding(updated.increase(over: known))
                state.bookkeeping.peers[id] = updated
            }
            counters.bestScore = max(counters.bestScore, published.bestScore)
        }
        // The same device ID with more than we know (e.g. restored from an older backup) is taken over.
        if let mine = remote.devices[deviceID] {
            state.progress = PlayerProgress(counters)
            counters = counters.adding(mine.increase(over: ownCounters(of: state)))
            counters.bestScore = max(counters.bestScore, mine.bestScore)
        }
        state.progress = PlayerProgress(counters)
        state.learning = mergedLearning(state.learning, remote.learning)
        state.history = mergedHistory(state.history, remote.history)
        return state
    }

    /// The record with more attempts wins (then more correct answers, then the local one).
    static func mergedLearning(_ local: [String: LearningRecord],
                               _ remote: [String: LearningRecord]) -> [String: LearningRecord] {
        var result = local
        for (key, record) in remote {
            guard let existing = result[key] else {
                result[key] = record
                continue
            }
            if record.attempts > existing.attempts ||
                (record.attempts == existing.attempts && record.correct > existing.correct) {
                result[key] = record
            }
        }
        return result
    }

    /// Union without duplicates, newest first, at most `SyncPayload.maxHistory` entries.
    static func mergedHistory(_ local: [ExamResult], _ remote: [ExamResult]) -> [ExamResult] {
        var result = local
        for entry in remote where !result.contains(entry) { result.append(entry) }
        result.sort { $0.date > $1.date }
        return Array(result.prefix(SyncPayload.maxHistory))
    }

    /// A reset starts a new epoch and forgets all peers, so older data from other devices is ignored.
    static func resetBookkeeping(_ bookkeeping: SyncBookkeeping) -> SyncBookkeeping {
        SyncBookkeeping(epoch: bookkeeping.epoch + 1, peers: [:])
    }
}

/// Remote data is only merged when it could have been produced by this app.
protocol SyncValidatable {
    var isValid: Bool { get }
}

extension SyncPayload: SyncValidatable {}

/// One selection or equipment choice and when it was made. `value == nil` is a deliberate "nothing", so
/// taking an outfit off spreads to the other devices like putting one on.
struct RewardSyncChoice: Codable, Equatable {
    var value: String?
    var at: TimeInterval

    /// The later choice wins. Equal times fall back to the larger value so every device picks the same one.
    static func winner(_ first: RewardSyncChoice, _ second: RewardSyncChoice) -> RewardSyncChoice {
        if first.at != second.at { return first.at > second.at ? first : second }
        return (first.value ?? "") >= (second.value ?? "") ? first : second
    }

    func isValid(knownValue: (String) -> Bool) -> Bool {
        at.isFinite && at >= 0 && (value.map(knownValue) ?? true)
    }
}

/// The reward state that is shared between devices: which pet is selected, its outfit and toy, and the bond
/// counters. The reward XP is deliberately missing: it is derived from the three games' combined XP, which
/// sync themselves, and only ever rises (`RewardStore.updateXP`), so nothing is relocked.
struct RewardSyncData: Codable, Equatable, SyncValidatable {
    var selectedPet: RewardSyncChoice?
    var outfits: [String: RewardSyncChoice] = [:]
    var toys: [String: RewardSyncChoice] = [:]
    var interactions: [String: [String: Int]] = [:]

    var isValid: Bool {
        let isPet: (String) -> Bool = { PetKind(rawValue: $0) != nil }
        return (selectedPet?.isValid(knownValue: isPet) ?? true) &&
            outfits.allSatisfy { isPet($0.key) && $0.value.isValid { PetOutfit(rawValue: $0) != nil } } &&
            toys.allSatisfy { isPet($0.key) && $0.value.isValid { PetToy(rawValue: $0) != nil } } &&
            interactions.allSatisfy { pet, counts in
                isPet(pet) && counts.allSatisfy {
                    PetInteraction(rawValue: $0.key) != nil && (0...ProgressCounters.limit).contains($0.value)
                }
            }
    }

    /// Choices: the later one wins. Counters: the larger value, because they only ever grow.
    /// Commutative, associative and idempotent, so all devices end up with the same state.
    func merged(with other: RewardSyncData) -> RewardSyncData {
        var result = self
        result.selectedPet = Self.winner(selectedPet, other.selectedPet)
        result.outfits = Self.winners(outfits, other.outfits)
        result.toys = Self.winners(toys, other.toys)
        for (pet, counts) in other.interactions {
            result.interactions[pet] = (result.interactions[pet] ?? [:])
                .merging(counts) { max($0, $1) }
        }
        return result
    }

    private static func winner(_ first: RewardSyncChoice?, _ second: RewardSyncChoice?) -> RewardSyncChoice? {
        guard let first else { return second }
        guard let second else { return first }
        return RewardSyncChoice.winner(first, second)
    }

    private static func winners(_ first: [String: RewardSyncChoice],
                                _ second: [String: RewardSyncChoice]) -> [String: RewardSyncChoice] {
        first.merging(second) { RewardSyncChoice.winner($0, $1) }
    }
}
