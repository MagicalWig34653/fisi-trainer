// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

/// Deterministic RNG for calculation tests. Prefixed `Calc` to avoid clashing with other
/// test files' own seeded generators.
struct CalcSplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

final class ExamCalculationTests: XCTestCase {
    /// Every case, over many seeds, must produce a valid, uniquely-solvable single-choice task
    /// with a stable id/topic and four distinct options.
    func testAllCasesProduceValidTasksAcrossSeeds() {
        for calculation in ExamCalculation.allCases {
            for seed in UInt64(1)...200 {
                var rng = CalcSplitMix64(seed: seed &* 97 &+ 13)
                let task = calculation.makeTask(using: &rng)

                XCTAssertTrue(task.isValid, "\(calculation.rawValue) seed \(seed): invalid task: \(task)")
                XCTAssertEqual(task.id, calculation.id, "\(calculation.rawValue) seed \(seed): wrong id")
                XCTAssertEqual(task.topic, calculation.topic, "\(calculation.rawValue) seed \(seed): wrong topic")
                XCTAssertEqual(task.kind, .single, "\(calculation.rawValue) seed \(seed): wrong kind")
                XCTAssertEqual(task.options.count, 4, "\(calculation.rawValue) seed \(seed): expected 4 options")
                XCTAssertEqual(Set(task.options).count, 4, "\(calculation.rawValue) seed \(seed): options not unique")
                XCTAssertEqual(task.solution.count, 1)
                XCTAssertTrue(task.options.indices.contains(task.solution[0]))
                XCTAssertFalse(task.prompt.isEmpty)
                XCTAssertFalse(task.explanation.isEmpty)
            }
        }
    }

    func testIDsAreStableAndUnique() {
        XCTAssertEqual(Set(ExamCalculation.allCases.map(\.id)).count, ExamCalculation.allCases.count)
        for calculation in ExamCalculation.allCases {
            XCTAssertEqual(calculation.id, "calc-\(calculation.rawValue)")
            XCTAssertFalse(calculation.title.isEmpty)
        }
    }

    func testTopicsMatchSubjectGrouping() {
        let wisoCases: Set<ExamCalculation> = [
            .reallohn, .inflationsrate, .kuendigungsfrist, .jugendurlaub, .urlaubstage,
            .betriebsrat, .svanteil, .nettolohn, .produktivitaet, .wirtschaftlichkeit,
            .rentabilitaet, .zinsen, .skonto, .stromkosten
        ]
        let itCases: Set<ExamCalculation> = [
            .raid, .uebertragung, .bildspeicher, .einheiten, .subnetze, .usv, .verfuegbarkeit
        ]
        XCTAssertEqual(wisoCases.union(itCases), Set(ExamCalculation.allCases))
        for calculation in wisoCases { XCTAssertEqual(calculation.topic.subject, .wiso) }
        for calculation in itCases { XCTAssertEqual(calculation.topic.subject, .it) }
    }

    // MARK: - Fixed calculation helpers

    func testRaidCapacityHelper() {
        XCTAssertEqual(ExamCalculation.raidCapacity(level: 0, disks: 4, size: 2), 8)
        XCTAssertEqual(ExamCalculation.raidCapacity(level: 1, disks: 2, size: 4), 4)
        XCTAssertEqual(ExamCalculation.raidCapacity(level: 5, disks: 5, size: 2), 8)
        XCTAssertEqual(ExamCalculation.raidCapacity(level: 6, disks: 6, size: 2), 8)
        XCTAssertEqual(ExamCalculation.raidCapacity(level: 10, disks: 8, size: 2), 8)
    }

    func testNoticePeriodHelper() {
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 0), "4 Wochen zum 15. oder zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 1), "4 Wochen zum 15. oder zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 2), "1 Monat zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 5), "2 Monate zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 8), "3 Monate zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 10), "4 Monate zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 12), "5 Monate zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 15), "6 Monate zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 20), "7 Monate zum Ende eines Kalendermonats")
        XCTAssertEqual(ExamCalculation.noticePeriod(years: 40), "7 Monate zum Ende eines Kalendermonats")
    }

    func testCouncilSizeHelper() {
        XCTAssertEqual(ExamCalculation.councilSize(voters: 5), 1)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 20), 1)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 21), 3)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 100), 5)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 200), 7)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 400), 9)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 700), 11)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 1000), 13)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 1500), 15)
        XCTAssertEqual(ExamCalculation.councilSize(voters: 4), 0)
    }

    func testYouthVacationHelper() {
        XCTAssertEqual(ExamCalculation.youthVacation(ageAtYearStart: 14), 30)
        XCTAssertEqual(ExamCalculation.youthVacation(ageAtYearStart: 15), 30)
        XCTAssertEqual(ExamCalculation.youthVacation(ageAtYearStart: 16), 27)
        XCTAssertEqual(ExamCalculation.youthVacation(ageAtYearStart: 17), 25)
        XCTAssertEqual(ExamCalculation.youthVacation(ageAtYearStart: 18), 24)
        XCTAssertEqual(ExamCalculation.youthVacation(ageAtYearStart: 30), 24)
    }

    // MARK: - Spot checks that the generated prompt/explanation match the computed answer

    func testGeneratedRaidTaskMatchesHelper() {
        var rng = CalcSplitMix64(seed: 42)
        let task = ExamCalculation.raid.makeTask(using: &rng)
        XCTAssertTrue(task.isValid)
        XCTAssertTrue(task.explanation.contains(task.options[task.solution[0]]))
    }

    func testGeneratedKuendigungsfristUsesKnownPeriods() {
        let allPeriods: Set<String> = [
            "2 Wochen", "4 Wochen zum 15. oder zum Ende eines Kalendermonats",
            "1 Monat zum Ende eines Kalendermonats", "2 Monate zum Ende eines Kalendermonats",
            "3 Monate zum Ende eines Kalendermonats", "4 Monate zum Ende eines Kalendermonats",
            "5 Monate zum Ende eines Kalendermonats", "6 Monate zum Ende eines Kalendermonats",
            "7 Monate zum Ende eines Kalendermonats"
        ]
        for seed in UInt64(1)...50 {
            var rng = CalcSplitMix64(seed: seed)
            let task = ExamCalculation.kuendigungsfrist.makeTask(using: &rng)
            for option in task.options {
                XCTAssertTrue(allPeriods.contains(option), "Unexpected notice period option: \(option)")
            }
        }
    }
}
