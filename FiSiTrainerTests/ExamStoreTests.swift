// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

final class ExamStoreTests: XCTestCase {
    @MainActor
    func testNonExamStartAnswerNextAndCompletion() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let tasks = fixedTasks()
        let store = ExamStore(saveURL: directory.appendingPathComponent("exam.json"),
                              now: fixedNow, fixedTasks: tasks)

        store.start(mode: .quiz, subject: .it, topic: nil)
        XCTAssertEqual(store.session(for: .quiz)?.tasks.count, 3)
        XCTAssertTrue(store.hasActiveSession(.quiz))

        store.answer([0], mode: .quiz)
        XCTAssertEqual(store.progress.totalXP, 40)
        XCTAssertTrue(store.session(for: .quiz)!.isCurrentAnswered)

        // Answering again must not score a second time.
        store.answer([0], mode: .quiz)
        XCTAssertEqual(store.progress.totalXP, 40)
        store.answer([1], mode: .quiz)
        XCTAssertEqual(store.progress.totalXP, 40)

        store.next(mode: .quiz)
        XCTAssertEqual(store.session(for: .quiz)?.index, 1)
        XCTAssertFalse(store.session(for: .quiz)!.isCurrentAnswered)

        store.answer([1], mode: .quiz)
        XCTAssertEqual(store.progress.totalXP, 45)
        store.next(mode: .quiz)

        store.answer([0], mode: .quiz)
        XCTAssertEqual(store.progress.totalXP, 85)
        store.next(mode: .quiz)

        let finished = try XCTUnwrap(store.session(for: .quiz))
        XCTAssertTrue(finished.isComplete)
        XCTAssertNotNil(finished.finishedAt)
        XCTAssertEqual(finished.score, 200)
        XCTAssertEqual(store.progress.completedRounds, 1)
        XCTAssertEqual(store.progress.totalXP, 135)
        XCTAssertEqual(store.progress.bestScore, 200)
    }

    @MainActor
    func testExamModeAnswersWithoutResolutionAndProducesResult() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let tasks = fixedTasks()
        let store = ExamStore(saveURL: directory.appendingPathComponent("exam.json"),
                              now: fixedNow, fixedTasks: tasks)

        store.start(mode: .exam, subject: .it, topic: nil)
        XCTAssertEqual(store.session(for: .exam)?.index, 0)

        store.answer([0], mode: .exam)
        // Exam mode advances immediately; there is no resolution to view.
        XCTAssertEqual(store.session(for: .exam)?.index, 1)
        XCTAssertFalse(store.session(for: .exam)!.isCurrentAnswered)
        XCTAssertTrue(store.examHistory.isEmpty)

        store.answer([1], mode: .exam)
        XCTAssertEqual(store.session(for: .exam)?.index, 2)

        store.answer([0], mode: .exam)
        let finished = try XCTUnwrap(store.session(for: .exam))
        XCTAssertTrue(finished.isComplete)

        let result = try XCTUnwrap(store.examHistory.first)
        XCTAssertEqual(store.examHistory.count, 1)
        XCTAssertEqual(result.subject, .it)
        XCTAssertEqual(result.percent, 2.0 / 3.0 * 100, accuracy: 0.001)
        XCTAssertEqual(result.grade.note, 3)
        XCTAssertEqual(result.grade.title, "befriedigend")
        XCTAssertEqual(store.progress.completedRounds, 1)
        XCTAssertEqual(store.progress.totalXP, 185)
        XCTAssertEqual(store.progress.bestScore, finished.score)
    }

    @MainActor
    func testExamHistoryKeepsAtMostTwentyNewestFirst() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let tasks = fixedTasks()
        let store = ExamStore(saveURL: directory.appendingPathComponent("exam.json"),
                              now: fixedNow, fixedTasks: tasks)
        for _ in 0..<22 {
            store.start(mode: .exam, subject: .it, topic: nil)
            for task in tasks { store.answer(task.solution, mode: .exam) }
        }
        XCTAssertEqual(store.examHistory.count, 20)
    }

    @MainActor
    func testSessionResumesMidRoundAfterReload() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("exam.json")
        let tasks = fixedTasks()
        let store = ExamStore(saveURL: saveURL, now: fixedNow, fixedTasks: tasks)
        store.start(mode: .quiz, subject: .it, topic: nil)
        store.answer([0], mode: .quiz)

        let restored = ExamStore(saveURL: saveURL, now: fixedNow)
        let session = try XCTUnwrap(restored.session(for: .quiz))
        XCTAssertEqual(session.index, 0)
        XCTAssertEqual(session.answers, [[0]])
        XCTAssertEqual(session.tasks.map(\.id), tasks.map(\.id))
        XCTAssertEqual(restored.progress.totalXP, 40)
        XCTAssertNil(restored.saveError)

        restored.next(mode: .quiz)
        XCTAssertEqual(restored.session(for: .quiz)?.index, 1)
    }

    @MainActor
    func testCorruptSaveIsPreservedUntilResetAndBackedUp() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let saveURL = directory.appendingPathComponent("exam.json")
        let corrupt = Data("not json".utf8)
        try corrupt.write(to: saveURL)

        let store = ExamStore(saveURL: saveURL, now: fixedNow, fixedTasks: fixedTasks())
        XCTAssertNotNil(store.saveError)
        store.start(mode: .quiz, subject: .it, topic: nil)
        XCTAssertNil(store.session(for: .quiz))
        XCTAssertEqual(try Data(contentsOf: saveURL), corrupt)

        store.resetProgress()
        XCTAssertNil(store.saveError)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .contains { $0.hasPrefix("exam-progress.corrupt.") })
        store.start(mode: .quiz, subject: .it, topic: nil)
        XCTAssertEqual(store.session(for: .quiz)?.tasks.count, 3)
    }

    @MainActor
    func testAbandonDiscardsSessionButKeepsEarnedXP() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ExamStore(saveURL: directory.appendingPathComponent("exam.json"),
                              now: fixedNow, fixedTasks: fixedTasks())
        store.start(mode: .quiz, subject: .it, topic: nil)
        store.answer([0], mode: .quiz)
        XCTAssertEqual(store.progress.totalXP, 40)

        store.abandon(mode: .quiz)
        XCTAssertNil(store.session(for: .quiz))
        XCTAssertFalse(store.hasActiveSession(.quiz))
        XCTAssertEqual(store.progress.totalXP, 40)

        store.start(mode: .quiz, subject: .it, topic: nil)
        XCTAssertEqual(store.session(for: .quiz)?.index, 0)
    }

    @MainActor
    func testShowsResolutionOnlyOutsideExamModeAfterAnswering() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ExamStore(saveURL: directory.appendingPathComponent("exam.json"),
                              now: fixedNow, fixedTasks: fixedTasks())

        store.start(mode: .exam, subject: .it, topic: nil)
        XCTAssertFalse(store.session(for: .exam)!.showsResolution)
        store.answer([0], mode: .exam)
        // Exam-simulation mode never reveals a resolution mid-round, even once answered.
        XCTAssertFalse(store.session(for: .exam)!.showsResolution)

        store.start(mode: .quiz, subject: .it, topic: nil)
        XCTAssertFalse(store.session(for: .quiz)!.showsResolution)
        store.answer([0], mode: .quiz)
        XCTAssertTrue(store.session(for: .quiz)!.showsResolution)
    }

    @MainActor
    func testModesRunIndependently() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ExamStore(saveURL: directory.appendingPathComponent("exam.json"),
                              now: fixedNow, fixedTasks: fixedTasks())
        store.start(mode: .quiz, subject: .it, topic: nil)
        store.start(mode: .truefalse, subject: .it, topic: nil)

        store.answer([0], mode: .quiz)
        store.next(mode: .quiz)

        XCTAssertEqual(store.session(for: .quiz)?.index, 1)
        XCTAssertEqual(store.session(for: .truefalse)?.index, 0)
        XCTAssertFalse(store.session(for: .truefalse)!.isCurrentAnswered)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExamStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func fixedNow() -> Date { Date(timeIntervalSince1970: 1_000) }

    private func fixedTasks() -> [ExamTask] {
        (0..<3).map { index in
            ExamTask(id: "fixture-\(index)", kind: .single, topic: .netze,
                     prompt: "Testfrage \(index)?", items: [],
                     options: ["Richtig \(index)", "Falsch \(index)"], solution: [0],
                     explanation: "Erklärung \(index).")
        }
    }
}
