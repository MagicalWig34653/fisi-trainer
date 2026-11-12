// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import XCTest
@testable import FiSiTrainer

final class LearnPathTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func day(_ offset: Int) -> Date {
        // 2026-11-01 12:00 UTC plus Tage
        calendar.date(byAdding: .day, value: offset, to: Date(timeIntervalSince1970: 1_793_534_400))!
    }

    func testStreakCountsOnlyDaysWithGoalReached() {
        var p = LearnPathProgress()
        p.addXP(60, now: day(0), calendar: calendar)
        XCTAssertEqual(p.currentStreak(now: day(0), calendar: calendar), 0, "Ziel noch nicht erreicht")
        p.addXP(40, now: day(0), calendar: calendar)
        XCTAssertEqual(p.currentStreak(now: day(0), calendar: calendar), 1)
        p.addXP(100, now: day(1), calendar: calendar)
        XCTAssertEqual(p.currentStreak(now: day(1), calendar: calendar), 2)
    }

    func testOpenGoalTodayKeepsStreakUntilTomorrowEnds() {
        var p = LearnPathProgress()
        p.addXP(100, now: day(0), calendar: calendar)
        XCTAssertEqual(p.currentStreak(now: day(1), calendar: calendar), 1, "Heute noch offen, Streak lebt")
        XCTAssertEqual(p.currentStreak(now: day(2), calendar: calendar), 0, "Ein Tag verpasst ohne Schutz")
    }

    func testMissedDayBreaksStreakWithoutFreeze() {
        var p = LearnPathProgress()
        p.addXP(100, now: day(0), calendar: calendar)
        p.addXP(100, now: day(1), calendar: calendar)
        p.addXP(100, now: day(3), calendar: calendar)
        XCTAssertEqual(p.currentStreak(now: day(3), calendar: calendar), 1)
    }

    func testFreezeBridgesExactlyOneMissedDay() {
        var p = LearnPathProgress()
        p.streakFreezes = 1
        p.addXP(100, now: day(0), calendar: calendar)
        p.addXP(100, now: day(1), calendar: calendar)
        XCTAssertEqual(p.currentStreak(now: day(3), calendar: calendar), 2, "Anzeige: Schutz hält die Serie")
        p.addXP(100, now: day(3), calendar: calendar)
        XCTAssertEqual(p.currentStreak(now: day(3), calendar: calendar), 3)
        XCTAssertEqual(p.streakFreezes, 0)
        XCTAssertTrue(p.frozenDays.contains(LearnPathProgress.dayKey(day(2), calendar: calendar)))
    }

    func testFreezeDoesNotBridgeTwoMissedDays() {
        var p = LearnPathProgress()
        p.streakFreezes = 2
        p.addXP(100, now: day(0), calendar: calendar)
        p.addXP(100, now: day(3), calendar: calendar)
        XCTAssertEqual(p.currentStreak(now: day(3), calendar: calendar), 1)
        XCTAssertEqual(p.streakFreezes, 2, "Kein Schutz verbraucht")
    }

    func testFreezeIsEarnedAfterSevenDaysAndCapped() {
        var p = LearnPathProgress()
        for offset in 0..<7 { p.addXP(100, now: day(offset), calendar: calendar) }
        XCTAssertEqual(p.streakFreezes, 1)
        for offset in 7..<21 { p.addXP(100, now: day(offset), calendar: calendar) }
        XCTAssertEqual(p.streakFreezes, LearnPathProgress.maxFreezes)
    }

    func testObserveTotalXPIgnoresHistoryAndCountsDelta() {
        var p = LearnPathProgress()
        p.observeTotalXP(5000, now: day(0), calendar: calendar)
        XCTAssertEqual(p.xp(on: day(0), calendar: calendar), 0)
        p.observeTotalXP(5030, now: day(0), calendar: calendar)
        p.observeTotalXP(5090, now: day(0), calendar: calendar)
        XCTAssertEqual(p.xp(on: day(0), calendar: calendar), 90)
        p.observeTotalXP(100, now: day(0), calendar: calendar)   // Zurücksetzen eines Spiels
        XCTAssertEqual(p.xp(on: day(0), calendar: calendar), 90)
        p.observeTotalXP(130, now: day(0), calendar: calendar)
        XCTAssertEqual(p.xp(on: day(0), calendar: calendar), 120)
        XCTAssertTrue(p.isGoalMet(on: day(0), calendar: calendar))
    }

    func testLessonsUnlockInOrderAndStopAtFive() {
        var p = LearnPathProgress()
        XCTAssertEqual(p.nextLesson(for: .netze), 0)
        p.completeLesson(topic: .netze)
        XCTAssertEqual(p.nextLesson(for: .netze), 1)
        XCTAssertEqual(p.nextLesson(for: .sozial), 0, "Andere Themen unberührt")
        for _ in 0..<10 { p.completeLesson(topic: .netze) }
        XCTAssertNil(p.nextLesson(for: .netze))
        XCTAssertEqual(p.completedCount(for: .netze), LearnPathProgress.lessonsPerTopic)
        XCTAssertTrue(p.isTopicDone(.netze))
    }

    @MainActor
    func testOnlyPathRoundCompletesLessonAndPersists() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let examURL = dir.appendingPathComponent("exam.json")
        let pathURL = dir.appendingPathComponent("path.json")
        let exam = ExamStore(saveURL: examURL)
        let path = LearnPathStore(saveURL: pathURL, calendar: calendar)

        // Runde außerhalb des Pfads zählt nicht.
        exam.start(mode: .quiz, subject: .it, topic: .netze)
        for _ in 0..<10 {
            exam.answer([0], mode: .quiz)
            exam.next(mode: .quiz)
        }
        path.roundFinished(exam.session(for: .quiz))
        XCTAssertEqual(path.progress.completedCount(for: .netze), 0)
        exam.abandon(mode: .quiz)

        XCTAssertTrue(path.startLesson(topic: .netze, exam: exam))
        XCTAssertFalse(path.startLesson(topic: .netze, exam: exam), "Läuft schon")
        path.roundFinished(exam.session(for: .quiz))
        XCTAssertEqual(path.progress.completedCount(for: .netze), 0, "Noch nicht fertig")
        for _ in 0..<10 {
            exam.answer([0], mode: .quiz)
            exam.next(mode: .quiz)
        }
        path.roundFinished(exam.session(for: .quiz))
        XCTAssertEqual(path.progress.completedCount(for: .netze), 1)

        let reloaded = LearnPathStore(saveURL: pathURL, calendar: calendar)
        XCTAssertEqual(reloaded.progress.completedCount(for: .netze), 1)
    }

    @MainActor
    func testCorruptSaveFileIsSetAsideNotCrashing() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("path.json")
        try Data("kaputt".utf8).write(to: url)
        let store = LearnPathStore(saveURL: url, calendar: calendar)
        XCTAssertEqual(store.progress, LearnPathProgress())
        XCTAssertNotNil(store.saveError)
    }
}
