// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

final class GameStoreTests: XCTestCase {
    @MainActor
    func testGeneratedRoundCoversEveryKindWithValidChoices() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = GameStore(saveURL: directory.appendingPathComponent("progress.json"))

        store.startRound()

        let questions = try XCTUnwrap(store.session?.questions)
        XCTAssertEqual(questions.count, 10)
        XCTAssertEqual(Set(questions.map(\.service.id)).count, 10)
        XCTAssertEqual(Set(questions.map(\.kind)), Set([.port, .service, .transport]))
        for question in questions {
            XCTAssertTrue(question.isValid)
            XCTAssertEqual(question.choices.count, question.kind == .transport ? 3 : 4)
            XCTAssertEqual(Set(question.choices).count, question.choices.count)
            XCTAssertTrue(question.choices.contains(question.correctAnswer))
            XCTAssertEqual(Set(question.choices.map(question.answerLabel)).count,
                           question.choices.count)
            if question.kind == .port {
                XCTAssertEqual(question.correctAnswer, question.service.port)
            }
            if question.kind == .service {
                XCTAssertEqual(question.answerLabel(question.correctAnswer), question.service.name)
            }
        }
    }

    @MainActor
    func testReverseServiceChoicesShowTheMatchingServiceNames() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = GameStore(saveURL: directory.appendingPathComponent("progress.json"))
        store.startRound()

        let questions = try XCTUnwrap(store.session?.questions.filter { $0.kind == .service })
        XCTAssertFalse(questions.isEmpty)
        for question in questions {
            XCTAssertEqual(question.answerLabel(question.correctAnswer), question.service.name)
            for choice in question.choices {
                let service = try XCTUnwrap(PortService.catalog.first { $0.port == choice })
                XCTAssertEqual(question.answerLabel(choice), service.name)
            }
        }
    }

    @MainActor
    func testTransportChoicesCoverTCPUDPAndBothWithoutLeakingAnswerInContext() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = GameStore(saveURL: directory.appendingPathComponent("progress.json"))
        store.startRound()

        let questions = try XCTUnwrap(store.session?.questions.filter { $0.kind == .transport })
        XCTAssertFalse(questions.isEmpty)
        for question in questions {
            XCTAssertEqual(Set(question.choices.map(question.answerLabel)),
                           Set(["TCP", "UDP", "TCP und UDP"]))
            let expectedAnswer = question.service.transport == "TCP / UDP"
                ? "TCP und UDP" : question.service.transport
            XCTAssertEqual(question.answerLabel(question.correctAnswer), expectedAnswer)
            XCTAssertTrue(question.context.contains(String(question.service.port)))
            XCTAssertFalse(question.context.contains("TCP"))
            XCTAssertFalse(question.context.contains("UDP"))
        }
    }

    @MainActor
    func testOnlyFirstValidAnswerScoresAndRoundCompletesOnce() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = GameStore(questions: fixedQuestions(count: 2),
                              saveURL: directory.appendingPathComponent("progress.json"),
                              now: fixedNow)
        store.startRound()
        store.nextQuestion()
        XCTAssertEqual(store.session?.index, 0)
        let first = try XCTUnwrap(store.currentQuestion)
        let wrong = try XCTUnwrap(first.choices.first { $0 != first.correctAnswer })

        store.answer(-1) // A port outside the offered choices must do nothing.
        XCTAssertNil(store.session?.selectedAnswer)
        XCTAssertEqual(store.progress.answeredQuestions, 0)
        store.answer(first.correctAnswer)
        store.answer(wrong)

        XCTAssertEqual(store.session?.score, 100)
        XCTAssertEqual(store.session?.correctCount, 1)
        XCTAssertEqual(store.progress.correctAnswers, 1)
        XCTAssertEqual(store.progress.answeredQuestions, 1)
        XCTAssertEqual(store.progress.totalXP, 40)

        store.nextQuestion()
        let second = try XCTUnwrap(store.currentQuestion)
        store.answer(try XCTUnwrap(second.choices.first { $0 != second.correctAnswer }))
        store.nextQuestion()
        store.nextQuestion()
        store.answer(second.correctAnswer)

        XCTAssertEqual(store.session?.isComplete, true)
        XCTAssertNil(store.currentQuestion)
        XCTAssertEqual(store.session?.score, 100)
        XCTAssertEqual(store.progress.answeredQuestions, 2)
        XCTAssertEqual(store.progress.correctAnswers, 1)
        XCTAssertEqual(store.progress.completedRounds, 1)
        XCTAssertEqual(store.progress.bestScore, 100)
        XCTAssertEqual(store.progress.totalXP, 95) // 40 + 5 for answers, 50 for completion.
    }

    @MainActor
    func testStreakBonusCapsAndResetsAndXPAdvancesLevel() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let questions = fixedQuestions(count: 10)
        let store = GameStore(questions: questions,
                              saveURL: directory.appendingPathComponent("progress.json"),
                              now: fixedNow)
        store.startRound()

        for question in questions {
            store.answer(question.correctAnswer)
            store.nextQuestion()
        }
        XCTAssertEqual(store.session?.score, 1350) // 100...150, then capped at 150.
        XCTAssertEqual(store.progress.totalXP, 450) // Ten fast answers and a completed round.
        XCTAssertEqual(store.progress.level, 2)
        XCTAssertEqual(store.progress.completedRounds, 1)

        store.startRound()
        store.answer(questions[0].correctAnswer)
        store.nextQuestion()
        store.answer(try XCTUnwrap(questions[1].choices.first {
            $0 != questions[1].correctAnswer
        }))
        store.nextQuestion()
        store.answer(questions[2].correctAnswer)
        XCTAssertEqual(store.session?.score, 200)
        XCTAssertEqual(store.session?.streak, 1)
        XCTAssertEqual(store.progress.totalXP, 535)
    }

    @MainActor
    func testAnsweredQuestionAndProgressSurviveReload() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("progress.json")
        let questions = fixedQuestions(count: 2)
        let original = GameStore(questions: questions, saveURL: saveURL, now: fixedNow)
        original.startRound()
        original.answer(questions[0].correctAnswer)

        let restored = GameStore(questions: questions, saveURL: saveURL)
        XCTAssertEqual(restored.session?.index, 0)
        XCTAssertEqual(restored.session?.selectedAnswer, questions[0].correctAnswer)
        XCTAssertEqual(restored.session?.score, 100)
        XCTAssertEqual(restored.progress.totalXP, 40)
        XCTAssertEqual(restored.progress.answeredQuestions, 1)

        restored.startRound() // An active round must not be replaced.
        XCTAssertEqual(restored.session?.selectedAnswer, questions[0].correctAnswer)
        restored.nextQuestion()
        XCTAssertEqual(restored.session?.index, 1)
        XCTAssertEqual(restored.currentQuestion?.service.id, questions[1].service.id)
        XCTAssertNil(restored.session?.selectedAnswer)

        let reloaded = GameStore(questions: questions, saveURL: saveURL)
        XCTAssertEqual(reloaded.session?.index, 1)
        XCTAssertEqual(reloaded.progress.totalXP, 40)
    }

    @MainActor
    func testAnsweredQuestionOfEveryKindSurvivesReload() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = GameStore(saveURL: directory.appendingPathComponent("source.json"))
        source.startRound()
        let questions = try XCTUnwrap(source.session?.questions)

        for kind in [QuestionKind.port, .service, .transport] {
            let question = try XCTUnwrap(questions.first { $0.kind == kind })
            let saveURL = directory.appendingPathComponent("\(kind).json")
            let original = GameStore(questions: [question], saveURL: saveURL, now: fixedNow)
            original.startRound()
            original.answer(question.correctAnswer)

            let restored = GameStore(saveURL: saveURL)
            let savedQuestion = try XCTUnwrap(restored.currentQuestion)
            XCTAssertEqual(savedQuestion.kind, kind)
            XCTAssertEqual(savedQuestion.choices, question.choices)
            XCTAssertEqual(savedQuestion.answerLabel(savedQuestion.correctAnswer),
                           question.answerLabel(question.correctAnswer))
            XCTAssertEqual(restored.session?.selectedAnswer, question.correctAnswer)
            XCTAssertEqual(restored.session?.score, 100)
            XCTAssertEqual(restored.progress.answeredQuestions, 1)
            XCTAssertEqual(restored.progress.totalXP, 40)
            XCTAssertNil(restored.saveError)
        }
    }

    @MainActor
    func testTimerKeepsRunningAcrossReloadAndScoresAtAnswerTime() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("progress.json")
        let questions = fixedQuestions(count: 2)
        let start = Date(timeIntervalSince1970: 1_000)
        var clock = start
        let original = GameStore(questions: questions, saveURL: saveURL, now: { clock })
        original.startRound()
        XCTAssertEqual(original.session?.timing?.startedAt, start)

        clock = start.addingTimeInterval(19.5)
        let restored = GameStore(questions: questions, saveURL: saveURL, now: { clock })
        XCTAssertEqual(restored.session?.timing?.startedAt, start)
        XCTAssertEqual(restored.session?.timing?.availableBonus(at: clock), 10)
        clock = start.addingTimeInterval(20)
        restored.answer(questions[0].correctAnswer)
        restored.answer(questions[0].correctAnswer)
        XCTAssertEqual(restored.session?.timing?.earnedBonus, 10)
        XCTAssertEqual(restored.session?.timing?.answeredAt, clock)
        XCTAssertEqual(restored.progress.totalXP, 35)
        XCTAssertEqual(restored.session?.score, 100)

        restored.nextQuestion()
        XCTAssertEqual(restored.session?.timing?.startedAt, clock)
        let wrong = try XCTUnwrap(questions[1].choices.first { $0 != questions[1].correctAnswer })
        restored.answer(wrong)
        XCTAssertEqual(restored.session?.timing?.earnedBonus, 0)
        XCTAssertEqual(restored.session?.speedBonusTotal, 10)
        XCTAssertEqual(restored.progress.totalXP, 40)
    }

    @MainActor
    func testLegacyUnansweredQuestionGetsOnePersistedStartTime() throws {
        struct LegacySave: Encodable {
            let progress = PlayerProgress()
            let session: GameSession
        }
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("progress.json")
        try JSONEncoder().encode(LegacySave(session: GameSession(
            questions: fixedQuestions(count: 2)))).write(to: saveURL)
        let firstTime = Date(timeIntervalSince1970: 1_000)
        let first = GameStore(saveURL: saveURL, now: { firstTime })
        XCTAssertEqual(first.session?.timing?.startedAt, firstTime)
        let later = firstTime.addingTimeInterval(12)
        let second = GameStore(saveURL: saveURL, now: { later })
        XCTAssertEqual(second.session?.timing?.startedAt, firstTime)
        XCTAssertEqual(second.session?.timing?.availableBonus(at: later), 10)
        XCTAssertNil(second.saveError)
    }

    @MainActor
    func testLegacySaveWithoutKindOrLabelsRestoresAnsweredRoundAndXP() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("progress.json")
        let legacyJSON = """
        {
          "progress": {
            "totalXP": 25, "completedRounds": 0, "bestScore": 0,
            "correctAnswers": 1, "answeredQuestions": 1
          },
          "session": {
            "questions": [{
              "service": {
                "id": "ftp", "name": "FTP (Steuerung)", "port": 21,
                "transport": "TCP", "hint": "Unverschlüsselte Dateiübertragung"
              },
              "choices": [21, 22, 23, 25], "correctAnswer": 21
            }],
            "index": 0, "selectedAnswer": 21, "score": 100,
            "correctCount": 1, "streak": 1
          }
        }
        """
        try Data(legacyJSON.utf8).write(to: saveURL)

        let restored = GameStore(saveURL: saveURL)
        XCTAssertNil(restored.saveError)
        XCTAssertEqual(restored.currentQuestion?.kind, .port)
        XCTAssertEqual(restored.currentQuestion?.answerLabel(21), "21")
        XCTAssertEqual(restored.session?.selectedAnswer, 21)
        XCTAssertEqual(restored.session?.score, 100)
        XCTAssertEqual(restored.progress.answeredQuestions, 1)
        XCTAssertEqual(restored.progress.totalXP, 25)
        XCTAssertNil(restored.session?.timing) // An old answer earns no retroactive bonus.

        restored.nextQuestion()
        XCTAssertEqual(restored.progress.completedRounds, 1)
        XCTAssertEqual(restored.progress.totalXP, 75)
        XCTAssertNil(GameStore(saveURL: saveURL).saveError)
    }

    @MainActor
    func testCorruptSaveIsPreservedUntilExplicitReset() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("progress.json")
        let corruptData = Data("not valid JSON".utf8)
        try corruptData.write(to: saveURL)

        let store = GameStore(questions: fixedQuestions(count: 2), saveURL: saveURL)
        XCTAssertNotNil(store.saveError)
        XCTAssertNil(store.session)
        store.startRound()
        XCTAssertNil(store.session)
        XCTAssertEqual(try Data(contentsOf: saveURL), corruptData)

        store.resetProgress()
        XCTAssertNil(store.saveError)
        XCTAssertEqual(store.progress.totalXP, 0)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .contains { $0.hasPrefix("progress.corrupt.") })
        store.startRound()
        XCTAssertEqual(store.session?.questions.count, 2)
        XCTAssertNil(GameStore(saveURL: saveURL).saveError)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FiSiTrainerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func fixedNow() -> Date { Date(timeIntervalSince1970: 1_000) }

    private func fixedQuestions(count: Int) -> [Question] {
        let services = Array(PortService.catalog.prefix(count))
        return services.map { service in
            let alternatives = PortService.catalog.map(\.port)
                .filter { $0 != service.port }
                .prefix(3)
            return Question(service: service,
                            choices: [service.port] + Array(alternatives),
                            correctAnswer: service.port)
        }
    }
}
