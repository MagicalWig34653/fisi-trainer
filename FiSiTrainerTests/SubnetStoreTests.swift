// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

final class SubnetStoreTests: XCTestCase {
    @MainActor
    func testIPv4ArithmeticAndGeneratedRound() throws {
        XCTAssertEqual(SubnetStore.mask(for: 16), "255.255.0.0")
        XCTAssertEqual(SubnetStore.mask(for: 24), "255.255.255.0")
        XCTAssertEqual(SubnetStore.mask(for: 30), "255.255.255.252")
        XCTAssertEqual(SubnetStore.usableHosts(for: 16), 65534)
        XCTAssertEqual(SubnetStore.usableHosts(for: 24), 254)
        XCTAssertEqual(SubnetStore.usableHosts(for: 30), 2)

        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SubnetStore(saveURL: directory.appendingPathComponent("subnet.json"))
        store.startRound()
        let questions = try XCTUnwrap(store.session?.questions)
        XCTAssertEqual(questions.count, 10)
        XCTAssertEqual(questions.filter { $0.kind == .mask }.count, 5)
        XCTAssertEqual(questions.filter { $0.kind == .hosts }.count, 5)
        XCTAssertEqual(Set(questions.map(\.prefix)).count, 10)
        XCTAssertTrue(questions.allSatisfy(\.isValid))
    }

    @MainActor
    func testAnsweredQuestionResumesAfterReload() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("subnet.json")
        let questions = fixedQuestions()
        let store = SubnetStore(questions: questions, saveURL: saveURL, now: fixedNow)
        store.startRound()
        store.answer(questions[0].correctAnswer)

        let restored = SubnetStore(saveURL: saveURL)
        XCTAssertEqual(restored.session?.index, 0)
        XCTAssertEqual(restored.session?.selectedAnswer, questions[0].correctAnswer)
        XCTAssertEqual(restored.session?.score, 100)
        XCTAssertEqual(restored.progress.totalXP, 40)
        restored.startRound()
        XCTAssertEqual(restored.session?.selectedAnswer, questions[0].correctAnswer)
        restored.nextQuestion()
        XCTAssertEqual(restored.currentQuestion?.prefix, questions[1].prefix)
        XCTAssertNil(SubnetStore(saveURL: saveURL).saveError)
    }

    @MainActor
    func testDuplicateAnswersAndCompletionCannotScoreTwice() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SubnetStore(questions: fixedQuestions(),
                                saveURL: directory.appendingPathComponent("subnet.json"),
                                now: fixedNow)
        store.startRound()
        store.nextQuestion()
        XCTAssertEqual(store.session?.index, 0)
        let first = try XCTUnwrap(store.currentQuestion)
        store.answer("invalid")
        XCTAssertNil(store.session?.selectedAnswer)
        store.answer(first.correctAnswer)
        store.answer(try XCTUnwrap(first.choices.first { $0 != first.correctAnswer }))
        XCTAssertEqual(store.progress.totalXP, 40)
        XCTAssertEqual(store.session?.score, 100)

        store.nextQuestion()
        let second = try XCTUnwrap(store.currentQuestion)
        store.answer(try XCTUnwrap(second.choices.first { $0 != second.correctAnswer }))
        store.nextQuestion()
        store.nextQuestion()
        store.answer(second.correctAnswer)
        XCTAssertEqual(store.session?.isComplete, true)
        XCTAssertEqual(store.session?.score, 100)
        XCTAssertEqual(store.progress.totalXP, 95)
        XCTAssertEqual(store.progress.completedRounds, 1)
        XCTAssertEqual(store.progress.bestScore, 100)
        XCTAssertEqual(store.progress.answeredQuestions, 2)
        XCTAssertEqual(store.progress.correctAnswers, 1)
    }

    @MainActor
    func testElapsedTimerAcrossReloadAndSlowAnswerEarnsNoBonus() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("subnet.json")
        let questions = fixedQuestions()
        let start = Date(timeIntervalSince1970: 1_000)
        var clock = start
        let original = SubnetStore(questions: questions, saveURL: saveURL, now: { clock })
        original.startRound()
        clock = start.addingTimeInterval(31)
        let restored = SubnetStore(questions: questions, saveURL: saveURL, now: { clock })
        XCTAssertEqual(restored.session?.timing?.startedAt, start)
        restored.answer(questions[0].correctAnswer)
        restored.answer(questions[0].correctAnswer)
        XCTAssertEqual(restored.session?.timing?.earnedBonus, 0)
        XCTAssertEqual(restored.progress.totalXP, 25)
        restored.nextQuestion()
        XCTAssertEqual(restored.session?.timing?.startedAt, clock)
        clock = clock.addingTimeInterval(10)
        restored.answer(questions[1].correctAnswer)
        XCTAssertEqual(restored.session?.timing?.earnedBonus, 15)
        XCTAssertEqual(restored.session?.speedBonusTotal, 15)
        XCTAssertEqual(restored.progress.totalXP, 65)
    }

    @MainActor
    func testLegacyUnansweredSessionStartsOnePersistedTimer() throws {
        struct LegacySave: Encodable {
            let progress = PlayerProgress()
            let session: SubnetSession
        }
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("subnet.json")
        try JSONEncoder().encode(LegacySave(session: SubnetSession(
            questions: fixedQuestions()))).write(to: saveURL)
        let start = Date(timeIntervalSince1970: 1_000)
        let first = SubnetStore(saveURL: saveURL, now: { start })
        XCTAssertEqual(first.session?.timing?.startedAt, start)
        let later = start.addingTimeInterval(40)
        let second = SubnetStore(saveURL: saveURL, now: { later })
        XCTAssertEqual(second.session?.timing?.startedAt, start)
        XCTAssertEqual(second.session?.timing?.availableBonus(at: later), 0)
        XCTAssertNil(second.saveError)
    }

    @MainActor
    func testCorruptSaveIsPreservedUntilResetAndBackedUp() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("subnet.json")
        let corrupt = Data("broken JSON".utf8)
        try corrupt.write(to: saveURL)
        let store = SubnetStore(saveURL: saveURL)
        XCTAssertNotNil(store.saveError)
        store.startRound()
        XCTAssertNil(store.session)
        XCTAssertEqual(try Data(contentsOf: saveURL), corrupt)

        store.resetProgress()
        XCTAssertNil(store.saveError)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .contains { $0.hasPrefix("subnet-progress.corrupt.") })
        store.startRound()
        XCTAssertEqual(store.session?.questions.count, 10)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SubnetStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func fixedNow() -> Date { Date(timeIntervalSince1970: 1_000) }

    private func fixedQuestions() -> [SubnetQuestion] {
        [
            SubnetQuestion(prefix: 24, kind: .mask,
                           prompt: "Maske für /24?",
                           choices: ["255.255.255.0", "255.255.0.0", "255.255.255.128", "255.255.255.192"],
                           correctAnswer: "255.255.255.0", explanation: "24 Netzbits."),
            SubnetQuestion(prefix: 30, kind: .hosts,
                           prompt: "Hosts für /30?",
                           choices: ["2", "4", "6", "8"],
                           correctAnswer: "2", explanation: "Vier Adressen minus zwei.")
        ]
    }
}
