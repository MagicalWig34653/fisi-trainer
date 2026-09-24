// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Small, bounded answer history for one service/question type or prefix/question type.
struct LearningRecord: Codable, Equatable {
    private(set) var attempts = 0
    private(set) var correct = 0
    private(set) var recent: [Bool] = []

    var isValid: Bool {
        attempts >= 0 && attempts < Int.max && correct >= 0 && correct <= attempts &&
        recent.count <= min(attempts, 5) &&
        recent.filter { $0 }.count <= correct &&
        recent.filter { !$0 }.count <= attempts - correct
    }

    var needsPractice: Bool {
        recent.contains(false) ||
            (attempts >= 3 && Double(attempts - correct) / Double(attempts) >= 0.25)
    }

    /// Every topic retains a positive chance; mistakes raise its chance.
    var selectionWeight: Double {
        guard attempts > 0 else { return 1.75 }
        let errorRate = Double(attempts - correct) / Double(attempts)
        let recentErrorRate = recent.isEmpty ? 0 :
            Double(recent.filter { !$0 }.count) / Double(recent.count)
        return 1 + 3 * errorRate + 2 * recentErrorRate
    }

    mutating func record(correct answerWasCorrect: Bool) {
        attempts += 1
        if answerWasCorrect { correct += 1 }
        recent.append(answerWasCorrect)
        if recent.count > 5 { recent.removeFirst() }
    }
}

enum AdaptiveLearning {
    static func portKey(serviceID: String, kind: QuestionKind) -> String {
        "port:\(serviceID):\(kind.rawValue)"
    }

    static func subnetKey(prefix: Int, kind: SubnetQuestionKind) -> String {
        "subnet:\(prefix):\(kind.rawValue)"
    }

    /// Draws without replacement. Passing an RNG makes the selection reproducible in tests.
    static func weightedSample<Element, RNG: RandomNumberGenerator>(
        _ candidates: [Element], count: Int, using generator: inout RNG,
        weight: (Element) -> Double
    ) -> [Element] {
        var remaining = candidates
        var selected: [Element] = []
        for _ in 0..<min(max(count, 0), candidates.count) {
            let weights = remaining.map { max(0.01, weight($0)) }
            let total = weights.reduce(0, +)
            let draw = Double.random(in: 0..<total, using: &generator)
            var running = 0.0
            let index = weights.firstIndex { value in
                running += value
                return draw < running
            } ?? (remaining.count - 1)
            selected.append(remaining.remove(at: index))
        }
        return selected
    }
}
