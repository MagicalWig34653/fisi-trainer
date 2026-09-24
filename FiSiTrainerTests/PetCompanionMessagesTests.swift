// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import XCTest
@testable import FiSiTrainer

final class PetCompanionMessagesTests: XCTestCase {
    func testPreparedMessagesRotateWithoutImmediateRepetition() {
        for result: Bool? in [nil, false, true] {
            let messages = (0..<3).map { PetCompanionMessages.greeting(after: result, turn: $0) }
            XCTAssertEqual(Set(messages).count, 3)
            XCTAssertEqual(PetCompanionMessages.greeting(after: result, turn: 3), messages[0])
        }

        let motivations = (0..<4).map { PetCompanionMessages.motivation(turn: $0) }
        XCTAssertEqual(Set(motivations).count, 4)
        XCTAssertEqual(PetCompanionMessages.motivation(turn: 4), motivations[0])
    }
}
