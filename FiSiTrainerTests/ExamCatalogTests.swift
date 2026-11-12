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

final class ExamOriginTests: XCTestCase {
    func testEveryIHKCardHasParseableOriginAndSource() {
        for card in ExamCatalog.ihk {
            guard let origin = card.origin else { XCTFail("Keine Herkunft: \(card.id)"); continue }
            var rng = SystemRandomNumberGenerator()
            guard let task = ExamTaskFactory.task(from: card, using: &rng) else { XCTFail("Kein Task: \(card.id)"); continue }
            XCTAssertTrue(task.explanation.contains("Quelle:"), "Keine Quelle: \(card.id)")
            XCTAssertTrue(task.explanation.contains("\(origin.term.title) \(origin.yearText)"), "Quelle passt nicht zur ID: \(card.id)")
        }
    }

    func testImportedExamsAreCompleteAndCarryTheirOrigin() {
        let exams: [(String, [ExamCard], String)] = [
            ("ihk-ap2-2023s-ga1-", ExamCatalog.ihkS2023GA1, "Sommer 2023"),
            ("ihk-ap2-2023s-ga2-", ExamCatalog.ihkS2023GA2, "Sommer 2023"),
            ("ihk-ap2-2023s-wiso-", ExamCatalog.ihkS2023WiSo, "Sommer 2023"),
            ("ihk-ap2-2022w-ga1-", ExamCatalog.ihkW2022GA1, "Winter 2022/23"),
            ("ihk-ap2-2022w-ga2-", ExamCatalog.ihkW2022GA2, "Winter 2022/23"),
            ("ihk-ap2-2022w-wiso-", ExamCatalog.ihkW2022WiSo, "Winter 2022/23"),
            ("ihk-ap2-2022s-ga1-", ExamCatalog.ihkS2022GA1, "Sommer 2022"),
            ("ihk-ap2-2022s-ga2-", ExamCatalog.ihkS2022GA2, "Sommer 2022"),
            ("ihk-ap2-2022s-wiso-", ExamCatalog.ihkS2022WiSo, "Sommer 2022"),
            ("ihk-ap2-2021w-ga1-", ExamCatalog.ihkW2021GA1, "Winter 2021/22"),
            ("ihk-ap2-2021w-ga2-", ExamCatalog.ihkW2021GA2, "Winter 2021/22"),
            ("ihk-ap2-2021w-wiso-", ExamCatalog.ihkW2021WiSo, "Winter 2021/22")
        ]
        for (prefix, cards, label) in exams {
            XCTAssertFalse(cards.isEmpty, prefix)
            for card in cards {
                XCTAssertTrue(card.id.hasPrefix(prefix), card.id)
                XCTAssertNotNil(ExamOrigin(cardID: card.id), card.id)
            }
            XCTAssertTrue(cards.allSatisfy { $0.id.hasPrefix(prefix) })
            _ = label
        }
        XCTAssertEqual([ExamCatalog.ihkS2023GA1.count, ExamCatalog.ihkS2023GA2.count, ExamCatalog.ihkS2023WiSo.count], [19, 24, 31])
        XCTAssertEqual([ExamCatalog.ihkW2022GA1.count, ExamCatalog.ihkW2022GA2.count, ExamCatalog.ihkW2022WiSo.count], [17, 22, 30])
        XCTAssertEqual([ExamCatalog.ihkS2022GA1.count, ExamCatalog.ihkS2022GA2.count, ExamCatalog.ihkS2022WiSo.count], [20, 26, 29])
        XCTAssertEqual([ExamCatalog.ihkW2021GA1.count, ExamCatalog.ihkW2021GA2.count, ExamCatalog.ihkW2021WiSo.count], [24, 21, 30])
        XCTAssertEqual(ExamCatalog.ihkS2022.count, ExamCatalog.ihkS2022GA1.count + ExamCatalog.ihkS2022GA2.count + ExamCatalog.ihkS2022WiSo.count)
        XCTAssertEqual(ExamCatalog.ihkW2021.count, ExamCatalog.ihkW2021GA1.count + ExamCatalog.ihkW2021GA2.count + ExamCatalog.ihkW2021WiSo.count)
        XCTAssertTrue(ExamCatalog.ihk.contains { $0.id.hasPrefix("ihk-ap2-2022s-") })
        XCTAssertTrue(ExamCatalog.ihk.contains { $0.id.hasPrefix("ihk-ap2-2021w-") })
        XCTAssertEqual(ExamCatalog.ihkS2023.count, ExamCatalog.ihkS2023GA1.count + ExamCatalog.ihkS2023GA2.count + ExamCatalog.ihkS2023WiSo.count)
        XCTAssertEqual(ExamCatalog.ihkW2022.count, ExamCatalog.ihkW2022GA1.count + ExamCatalog.ihkW2022GA2.count + ExamCatalog.ihkW2022WiSo.count)
        XCTAssertTrue(ExamCatalog.ihk.contains { $0.id.hasPrefix("ihk-ap2-2023s-") })
        XCTAssertTrue(ExamCatalog.ihk.contains { $0.id.hasPrefix("ihk-ap2-2022w-") })
    }

    /// Erklärungen nennen den Antwortwortlaut statt der Ziffern des Originals, auch bei Mehrfachauswahl.
    func testIhkZifferNamesAnswerWording() {
        XCTAssertEqual(ExamCatalog.ihkZiffer("Ziffer 3. Weil …", answer: "Bausparvertrag."),
                       "„Bausparvertrag“ (im Original Ziffer 3). Weil …")
        XCTAssertEqual(ExamCatalog.ihkZiffer("Ziffern 3 und 6.", answers: ["Bausparvertrag", "VL-Sparplan"]),
                       "„Bausparvertrag“ und „VL-Sparplan“ (im Original Ziffern 3 und 6).")
        XCTAssertEqual(ExamCatalog.ihkZiffer("Ziffern 1, 2 und 5.", answers: ["A", "B", "C"]),
                       "„A“, „B“ und „C“ (im Original Ziffern 1, 2 und 5).")
        // Zahl der Ziffern passt nicht zur Zahl der Antworten: Erklärung bleibt unverändert.
        XCTAssertEqual(ExamCatalog.ihkZiffer("Ziffern 1 und 5.", answers: ["A"]), "Ziffern 1 und 5.")
        XCTAssertEqual(ExamCatalog.ihkZiffer("Position 1 und 2.", answers: ["A", "B"]), "Position 1 und 2.")
        let wiso = ExamCatalog.ihkS2022WiSo.first { $0.id == "ihk-ap2-2022s-wiso-2" }
        if case let .multiple(_, _, _, _, _, explanation)? = wiso {
            XCTAssertFalse(explanation.contains("Lösungsblatt: Ziffern"), explanation)
            XCTAssertTrue(explanation.contains("(im Original Ziffern 1 und 5)"), explanation)
        } else {
            XCTFail("2022S WiSo 2 fehlt oder ist keine Mehrfachauswahl")
        }
    }

    func testOwnCardsHaveNoOrigin() {
        XCTAssertNil(ExamOrigin(cardID: "sys-k01"))
    }

    /// Bestandskarten, die wortgleich als IHK-Aufgabe vorliegen, behalten ihre ID und nennen die Prüfung als Quelle.
    func testDuplicateStockCardsNameTheirExam() {
        var rng = CatalogRNG(seed: 7)
        for (id, task) in [("sys-k01", "1cb"), ("sys-k17", "3b"), ("sys-k18", "3c")] {
            guard let card = ExamCatalog.all.first(where: { $0.id == id }),
                  let made = ExamTaskFactory.task(from: card, using: &rng) else { XCTFail(id); continue }
            XCTAssertTrue(made.explanation.contains("Quelle: IHK AP2 FiSi Winter 2022/23, GA1, Aufgabe \(task)."), id)
        }
        XCTAssertFalse(ExamCatalog.all.contains { ["ihk-ap2-2022w-ga1-1cb", "ihk-ap2-2022w-ga1-3b", "ihk-ap2-2022w-ga1-3c"].contains($0.id) })
    }

    /// sys-k01 wertet wie die IHK-Musterlösung 10 Platten (ein Verbund über beide Arrays).
    func testSysK01CountsTenDisks() {
        guard case let .choice(_, _, prompt, options, explanation)? = ExamCatalog.all.first(where: { $0.id == "sys-k01" }) else {
            return XCTFail("sys-k01 fehlt oder ist keine Auswahl")
        }
        XCTAssertEqual(options.first, "10 Platten")
        XCTAssertFalse(options.dropFirst().contains("10 Platten"))
        XCTAssertTrue(prompt.contains("über beide Arrays"))
        XCTAssertTrue(explanation.contains("7 + 2 + 1 = 10 Platten"))
    }

    func testFilterRecentAndPart() {
        let old = ExamOrigin(cardID: "ihk-ap2-2019w-ga1-1")
        let new = ExamOrigin(cardID: "ihk-ap2-2026s-ga1-1")
        var filter = ExamOriginFilter.all
        XCTAssertTrue(filter.allows(old, referenceYear: 2026))
        filter.onlyRecent = true
        XCTAssertFalse(filter.allows(old, referenceYear: 2026))
        XCTAssertTrue(filter.allows(new, referenceYear: 2026))
        XCTAssertTrue(filter.allows(nil, referenceYear: 2026))
        filter.part = .ap1
        XCTAssertFalse(filter.allows(new, referenceYear: 2026))
    }

    func testFilterCanHideOwnCards() {
        var filter = ExamOriginFilter.all
        XCTAssertTrue(filter.showOwn)
        XCTAssertTrue(filter.allows(nil, referenceYear: 2026))
        filter.showOwn = false
        XCTAssertFalse(filter.allows(nil, referenceYear: 2026))
        XCTAssertTrue(filter.allows(ExamOrigin(cardID: "ihk-ap2-2026s-ga1-1"), referenceYear: 2026))
        let cards = ExamTaskFactory.cards(for: .quiz, subject: .it, topic: nil, catalog: ExamCatalog.all, filter: filter)
        XCTAssertFalse(cards.isEmpty)
        XCTAssertTrue(cards.allSatisfy { $0.origin != nil })
    }

    func testOwnCardSwitchIsPersistedAndOldDataStaysReadable() {
        let defaults = UserDefaults(suiteName: "originfilter-own-test")!
        defaults.removePersistentDomain(forName: "originfilter-own-test")
        ExamOriginFilter(onlyRecent: false, part: nil, showOwn: false).save(to: defaults)
        XCTAssertFalse(ExamOriginFilter.load(from: defaults).showOwn)
        defaults.set(Data(#"{"onlyRecent":true}"#.utf8), forKey: ExamOriginFilter.defaultsKey)
        XCTAssertEqual(ExamOriginFilter.load(from: defaults), ExamOriginFilter(onlyRecent: true, part: nil, showOwn: true))
    }

    func testFilterIsPersisted() {
        let defaults = UserDefaults(suiteName: "originfilter-test")!
        defaults.removePersistentDomain(forName: "originfilter-test")
        ExamOriginFilter(onlyRecent: true, part: .ap2).save(to: defaults)
        XCTAssertEqual(ExamOriginFilter.load(from: defaults), ExamOriginFilter(onlyRecent: true, part: .ap2))
    }
}
