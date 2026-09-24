// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

final class QuestionTimingTests: XCTestCase {
    func testSpeedBonusBoundariesAndElapsedTime() {
        let start = Date(timeIntervalSince1970: 1_000)
        let timing = QuestionTiming(startedAt: start)
        XCTAssertEqual(timing.elapsed(at: start.addingTimeInterval(-5)), 0)
        XCTAssertEqual(timing.availableBonus(at: start), 15)
        for (seconds, bonus) in [(10.0, 15), (10.001, 10), (20.0, 10),
                                 (20.001, 5), (30.0, 5), (30.001, 0)] {
            XCTAssertEqual(timing.availableBonus(at: start.addingTimeInterval(seconds)), bonus)
        }
        XCTAssertEqual(QuestionTiming.bonus(for: .infinity), 0)
    }

    func testAnsweredTimestampAndBonusSurviveCoding() throws {
        let start = Date(timeIntervalSince1970: 1_000)
        var timing = QuestionTiming(startedAt: start)
        timing.answeredAt = start.addingTimeInterval(20)
        timing.earnedBonus = 10
        let decoded = try JSONDecoder().decode(QuestionTiming.self,
                                               from: JSONEncoder().encode(timing))
        XCTAssertEqual(decoded.startedAt, start)
        XCTAssertEqual(decoded.answeredAt, timing.answeredAt)
        XCTAssertEqual(decoded.earnedBonus, 10)
        XCTAssertTrue(decoded.isValid)
    }
}
