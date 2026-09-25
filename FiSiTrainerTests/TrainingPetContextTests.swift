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

    private func makeExamTask(kind: ExamTask.Kind = .single) -> ExamTask {
        switch kind {
        case .single:
            return ExamTask(id: "exam-t1", kind: .single, topic: .ausbildung,
                            prompt: "Wer ist die zuständige Stelle für IT-Berufe?",
                            items: [], options: ["IHK", "Handwerkskammer", "Arbeitsagentur", "Finanzamt"],
                            solution: [0], explanation: "Die IHK führt das Verzeichnis der Ausbildungsverhältnisse.")
        case .multiple:
            return ExamTask(id: "exam-t2", kind: .multiple, topic: .arbeitsrecht,
                            prompt: "Welche Angaben gehören ins qualifizierte Zeugnis?",
                            items: [], options: ["Leistung", "Verhalten", "Art der Tätigkeit", "Gehalt", "Kontonummer"],
                            solution: [0, 1, 2], explanation: "Leistung, Verhalten und Art der Tätigkeit gehören dazu.")
        case .match:
            return ExamTask(id: "exam-t3", kind: .match, topic: .sozial,
                            prompt: "Ordne den Versicherungszweig zu.",
                            items: ["Krankheit", "Alter"], options: ["Krankenversicherung", "Rentenversicherung"],
                            solution: [0, 1], explanation: "Krankheit → KV, Alter → RV.")
        case .order:
            return ExamTask(id: "exam-t4", kind: .order, topic: .mitbestimmung,
                            prompt: "Bringe die Tarifrunde in die richtige Reihenfolge.",
                            items: ["Kündigung", "Verhandlung", "Streik", "Einigung"], options: [],
                            solution: [0, 1, 2, 3], explanation: "So läuft eine Tarifrunde typischerweise ab.")
        }
    }

    func testExamHubHasNeutralContextWithoutSolution() {
        let context = PetLearningContext.exam(nil, mode: .quiz)
        XCTAssertNil(context.explanation)
        XCTAssertNil(context.wasCorrect)
        XCTAssertFalse(context.hint.isEmpty)
    }

    func testExamHintNeverRevealsSolutionBeforeAnswering() {
        let task = makeExamTask()
        let session = ExamSession(mode: .quiz, subject: .wiso, topic: .ausbildung,
                                  tasks: [task], startedAt: Date())
        let context = PetLearningContext.exam(session, mode: .quiz)
        XCTAssertNil(context.explanation)
        XCTAssertNil(context.wasCorrect)
        XCTAssertFalse(context.hint.contains("IHK"))
    }

    func testExamRevealsSolutionAfterAnsweringInPracticeMode() {
        let task = makeExamTask()
        var session = ExamSession(mode: .quiz, subject: .wiso, topic: .ausbildung,
                                  tasks: [task], startedAt: Date())
        session.answers = [[1]]
        let context = PetLearningContext.exam(session, mode: .quiz)
        XCTAssertEqual(context.wasCorrect, false)
        XCTAssertTrue(context.explanation?.contains("Lösung: IHK") == true)
    }

    func testExamModeNeverRevealsSolutionEvenIfMarkedAnswered() {
        let task = makeExamTask()
        var session = ExamSession(mode: .exam, subject: .wiso, topic: nil,
                                  tasks: [task], startedAt: Date())
        // Defensive check: the exam simulation never pauses for a resolution, but the
        // context builder must still refuse to reveal a solution if this ever happened.
        session.answers = [[0]]
        let context = PetLearningContext.exam(session, mode: .exam)
        XCTAssertNil(context.explanation)
        XCTAssertNil(context.wasCorrect)
    }

    func testExamFinishedContextShowsNoSolutionOnlySummary() {
        let task = makeExamTask()
        var session = ExamSession(mode: .exam, subject: .wiso, topic: nil,
                                  tasks: [task], startedAt: Date())
        session.answers = [[0]]
        session.index = 1
        session.correctCount = 1
        session.credit = 1
        session.finishedAt = Date()
        let context = PetLearningContext.exam(session, mode: .exam)
        XCTAssertNil(context.wasCorrect)
        XCTAssertFalse(context.explanation?.contains("Lösung") ?? false)
        XCTAssertTrue(context.title.contains("abgeschlossen"))
    }

    func testExamStableIDAcrossKinds() {
        for kind: ExamTask.Kind in [.single, .multiple, .match, .order] {
            let task = makeExamTask(kind: kind)
            let session = ExamSession(mode: .quiz, subject: .wiso, topic: task.topic, tasks: [task], startedAt: Date())
            let first = PetLearningContext.exam(session, mode: .quiz)
            let second = PetLearningContext.exam(session, mode: .quiz)
            XCTAssertEqual(first.id, second.id)
        }
    }
}
