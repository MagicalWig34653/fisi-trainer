// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import XCTest
@testable import FiSiTrainer

final class TrainingPetContextTests: XCTestCase {
    func testPortSolutionOnlyAppearsAfterAnswering() {
        let service = PortService.catalog.first { $0.id == "ssh" }!
        let question = Question(service: service, choices: [22, 25, 80, 443], correctAnswer: 22)
        var session = GameSession(questions: [question])
        let open = PetLearningContext.port(session)
        XCTAssertNil(open.explanation)
        XCTAssertNil(open.wasCorrect)
        session.selectedAnswer = 25
        let answered = PetLearningContext.port(session)
        XCTAssertEqual(open.id, answered.id)
        XCTAssertEqual(answered.wasCorrect, false)
        XCTAssertTrue(answered.explanation?.contains("Port 22") == true)
    }

    func testSubnetHintGivesMethodAndRevealsExplanationAfterAnswer() {
        let question = SubnetQuestion(prefix: 26, kind: .hosts, prompt: "Hosts in /26?",
                                      choices: ["62", "64", "126", "254"], correctAnswer: "62",
                                      explanation: "6 Hostbits: 2^6 − 2 = 62.")
        var session = SubnetSession(questions: [question])
        let open = PetLearningContext.subnet(session)
        XCTAssertNil(open.explanation)
        XCTAssertFalse(open.hint.contains("62"))
        session.selectedAnswer = "62"
        let answered = PetLearningContext.subnet(session)
        XCTAssertEqual(answered.wasCorrect, true)
        XCTAssertEqual(answered.explanation, question.explanation)
    }

    func testReadyAndCompletedRoundsHaveContextsWithoutIndexingQuestions() {
        XCTAssertFalse(PetLearningContext.port(nil).hint.isEmpty)
        XCTAssertFalse(PetLearningContext.subnet(nil).hint.isEmpty)
        XCTAssertEqual(PetLearningContext.port(GameSession(questions: [])).title, "Port-Runde abgeschlossen")
        XCTAssertEqual(PetLearningContext.subnet(SubnetSession(questions: [])).title, "Subnetz-Runde abgeschlossen")
    }
}
