// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

/// Deterministic, dependency-free RNG for catalog tests. The prefixed name avoids
/// colliding with any other test file's random number generator.
private struct CatalogRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E37_79B9_7F4A_7C15
        if state == 0 { state = 0x9E37_79B9_7F4A_7C15 }
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

final class ExamCatalogTests: XCTestCase {
    func testAllCardAndCalculationIDsAreUnique() {
        let ids = ExamCatalog.all.map(\.id) + ExamCalculation.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "IDs müssen eindeutig sein.")
    }

    func testEveryCardProducesAValidTaskAcrossSeeds() {
        for seed: UInt64 in [1, 42, 12_345, 999_983, 0] {
            var rng = CatalogRNG(seed: seed)
            for card in ExamCatalog.all {
                guard let task = ExamTaskFactory.task(from: card, catalog: ExamCatalog.all, using: &rng) else {
                    if case .fact = card {
                        XCTFail("Fact-Karte \(card.id) lieferte keinen Task (Seed \(seed)).")
                    }
                    continue
                }
                XCTAssertTrue(task.isValid, "Ungültiger Task für \(card.id) (Seed \(seed)).")
                XCTAssertEqual(task.id, card.id)
                XCTAssertEqual(task.topic, card.topic)
            }
        }
    }

    func testEveryCalculationProducesAValidTaskAcrossSeeds() {
        for seed: UInt64 in [3, 17, 4_242, 555_001] {
            var rng = CatalogRNG(seed: seed)
            for calculation in ExamCalculation.allCases {
                let task = calculation.makeTask(using: &rng)
                XCTAssertTrue(task.isValid, "Ungültiger Task für \(calculation.id) (Seed \(seed)).")
                XCTAssertEqual(task.id, calculation.id)
                XCTAssertEqual(task.topic, calculation.topic)
                XCTAssertEqual(task.kind, .single)
                XCTAssertEqual(task.options.count, 4)
                XCTAssertEqual(Set(task.options).count, 4)
            }
        }
    }

    func testChoiceCardsHaveFiveUniqueOptions() {
        for card in ExamCatalog.all {
            guard case let .choice(id, _, _, options, _) = card else { continue }
            XCTAssertEqual(options.count, 5, id)
            XCTAssertEqual(Set(options).count, 5, id)
        }
    }

    func testGapSentencesContainExactlyOneBlank() {
        for card in ExamCatalog.all {
            guard case let .gap(id, _, _, sentences, _, _) = card else { continue }
            for (sentence, word) in sentences {
                let blanks = sentence.components(separatedBy: "___").count - 1
                XCTAssertEqual(blanks, 1, "\(id): \"\(sentence)\"")
                XCTAssertFalse(word.isEmpty, id)
            }
        }
    }

    func testFactGroupsHaveAtLeastFourDistinctAnswersPerSubject() {
        struct Key: Hashable { let group: String; let subject: ExamSubject }
        var answersByGroup: [Key: Set<String>] = [:]
        for card in ExamCatalog.all {
            guard case let .fact(_, topic, group, _, answer, _) = card else { continue }
            answersByGroup[Key(group: group, subject: topic.subject), default: []].insert(answer)
        }
        XCTAssertFalse(answersByGroup.isEmpty, "Es sollten .fact-Karten vorhanden sein.")
        for (key, answers) in answersByGroup {
            XCTAssertGreaterThanOrEqual(answers.count, 4,
                "Gruppe \(key.group) (\(key.subject)) hat nur \(answers.count) verschiedene Antworten.")
        }
    }

    func testAvailableCountMeetsRoundLengthForEveryModeAndSubjectWithoutFilter() {
        for subject in ExamSubject.allCases {
            for mode in ExamMode.allCases {
                let count = ExamTaskFactory.availableCount(for: mode, subject: subject, topic: nil)
                if mode == .calc {
                    XCTAssertGreaterThan(count, 0, "\(mode) · \(subject)")
                } else {
                    XCTAssertGreaterThanOrEqual(count, mode.roundLength, "\(mode) · \(subject)")
                }
            }
        }
    }

    func testEveryTopicHasAtLeastOneChoiceAndStatementCard() {
        for topic in ExamTopic.allCases {
            let cards = ExamCatalog.all.filter { $0.topic == topic }
            XCTAssertTrue(cards.contains { if case .choice = $0 { return true } else { return false } },
                          "\(topic) hat keine .choice-Karte.")
            XCTAssertTrue(cards.contains { if case .statement = $0 { return true } else { return false } },
                          "\(topic) hat keine .statement-Karte.")
        }
    }

    func testExamRoundProducesThirtyValidTasksForBothSubjects() {
        for subject in ExamSubject.allCases {
            var rng = CatalogRNG(seed: 7)
            let tasks = ExamTaskFactory.makeRound(mode: .exam, subject: subject, topic: nil,
                                                  catalog: ExamCatalog.all, using: &rng) { _ in 1 }
            XCTAssertEqual(tasks.count, 30, "\(subject)")
            XCTAssertTrue(tasks.allSatisfy(\.isValid), "\(subject)")
        }
    }

    func testExamGradeBoundaries() {
        let cases: [(percent: Double, note: Int)] = [
            (92, 1), (91, 2), (81, 2), (80, 3), (67, 3), (66, 4), (50, 4), (49, 5), (30, 5), (29, 6)
        ]
        for (percent, note) in cases {
            XCTAssertEqual(ExamGrade.grade(forPercent: percent).note, note, "\(percent)%")
        }
    }
}
