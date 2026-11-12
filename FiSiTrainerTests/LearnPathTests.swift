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
            exam.answer(exam.session(for: .quiz)!.currentTask!.solution, mode: .quiz)
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

    func testGoalChangeAppliesToTodayAndKeepsPastDays() {
        var p = LearnPathProgress()
        p.addXP(100, now: day(0), calendar: calendar)
        p.setGoal(200, now: day(1), calendar: calendar)
        XCTAssertEqual(p.goalXP, 200)
        XCTAssertTrue(p.isGoalMet(on: day(0), calendar: calendar), "Alter Tag bleibt erreicht")
        p.addXP(150, now: day(1), calendar: calendar)
        XCTAssertFalse(p.isGoalMet(on: day(1), calendar: calendar))
        p.setGoal(100, now: day(1), calendar: calendar)
        XCTAssertTrue(p.isGoalMet(on: day(1), calendar: calendar), "Niedrigeres Ziel zählt heute sofort")
        XCTAssertEqual(p.currentStreak(now: day(1), calendar: calendar), 2)
        p.setGoal(77, now: day(1), calendar: calendar)
        XCTAssertEqual(p.goalXP, 100, "Nur Locker, Normal, Intensiv erlaubt")
    }

    @MainActor
    func testLessonRepeatsWrongTasksOnceAtTheEnd() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let exam = ExamStore(saveURL: dir.appendingPathComponent("exam.json"))
        let path = LearnPathStore(saveURL: dir.appendingPathComponent("path.json"), calendar: calendar)
        XCTAssertTrue(path.startLesson(topic: .netze, exam: exam))
        // Erste Aufgabe falsch, Rest richtig beantworten.
        var wrongTask: ExamTask?
        for i in 0..<10 {
            let task = exam.session(for: .quiz)!.currentTask!
            let right = task.solution
            if i == 0 {
                wrongTask = task
                exam.answer([(right[0] + 1) % task.options.count], mode: .quiz)
            } else {
                exam.answer(right, mode: .quiz)
            }
            exam.next(mode: .quiz)
        }
        var session = try XCTUnwrap(exam.session(for: .quiz))
        XCTAssertFalse(session.isComplete, "Wiederholung der falschen Aufgabe steht noch aus")
        XCTAssertEqual(session.tasks.count, 11)
        XCTAssertEqual(session.currentTask?.id, wrongTask?.id)
        path.roundFinished(session)
        XCTAssertEqual(path.progress.completedCount(for: .netze), 0)
        exam.answer([(session.currentTask!.solution[0] + 1) % session.currentTask!.options.count], mode: .quiz)
        exam.next(mode: .quiz)   // wieder falsch: keine zweite Wiederholung
        session = try XCTUnwrap(exam.session(for: .quiz))
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.tasks.count, 11)
        path.roundFinished(session)
        XCTAssertEqual(path.progress.completedCount(for: .netze), 1)
    }

    // MARK: Welle 3: Wiederholung

    func testReviewIntervalsGrowAndResetOnMistake() {
        let start = Date(timeIntervalSince1970: 1_793_534_400)
        var record = LearningRecord()
        record.record(correct: true, at: start)           // Stufe 1: 3 Tage
        XCTAssertFalse(record.isDue(at: start.addingTimeInterval(2 * 86_400)))
        XCTAssertTrue(record.isDue(at: start.addingTimeInterval(3 * 86_400)))
        record.record(correct: true, at: start)           // Stufe 2: 7 Tage
        XCTAssertFalse(record.isDue(at: start.addingTimeInterval(6 * 86_400)))
        XCTAssertTrue(record.isDue(at: start.addingTimeInterval(7 * 86_400)))
        record.record(correct: true, at: start)           // Stufe 3: 21 Tage
        record.record(correct: true, at: start)           // bleibt bei 21
        XCTAssertFalse(record.isDue(at: start.addingTimeInterval(20 * 86_400)))
        XCTAssertTrue(record.isDue(at: start.addingTimeInterval(21 * 86_400)))
        record.record(correct: false, at: start)          // Fehler: morgen wieder
        XCTAssertFalse(record.isDue(at: start.addingTimeInterval(86_000)))
        XCTAssertTrue(record.isDue(at: start.addingTimeInterval(86_400)))
        XCTAssertTrue(record.isValid)
    }

    func testOldSavedRecordWithoutTimestampLoadsAndIsDueOnlyWhenWeak() throws {
        let weak = try JSONDecoder().decode(LearningRecord.self, from: Data(
            #"{"attempts":2,"correct":1,"recent":[true,false]}"#.utf8))
        let strong = try JSONDecoder().decode(LearningRecord.self, from: Data(
            #"{"attempts":2,"correct":2,"recent":[true,true]}"#.utf8))
        XCTAssertTrue(weak.isValid && strong.isValid)
        XCTAssertTrue(weak.isDue(at: Date()))
        XCTAssertFalse(strong.isDue(at: Date()))
        XCTAssertFalse(LearningRecord().isDue(at: Date()))
    }

    /// Echter Katalog, echte Runden, nur die Uhr ist eingespeist.
    @MainActor
    func testReviewLessonFromDueCardsEndToEnd() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        var clock = Date(timeIntervalSince1970: 1_793_534_400)
        let url = dir.appendingPathComponent("exam.json")
        let exam = ExamStore(saveURL: url, now: { clock })
        let path = LearnPathStore(saveURL: dir.appendingPathComponent("path.json"),
                                  now: { clock }, calendar: calendar)
        XCTAssertTrue(exam.dueCards(subject: .it).isEmpty, "Ohne Antworten ist nichts fällig")
        XCTAssertFalse(exam.startReview(subject: .it))

        // Lektion: erste Aufgabe falsch (auch in der Wiederholung am Ende), Rest richtig.
        XCTAssertTrue(path.startLesson(topic: .netze, exam: exam))
        let wrongID = try XCTUnwrap(exam.session(for: .quiz)?.currentTask?.id)
        var answered = 0
        while let task = exam.session(for: .quiz)?.currentTask {
            let isWrong = task.id == wrongID
            exam.answer(isWrong ? [(task.solution[0] + 1) % task.options.count] : task.solution, mode: .quiz)
            exam.next(mode: .quiz)
            answered += 1
        }
        path.roundFinished(exam.session(for: .quiz))
        XCTAssertEqual(path.progress.completedCount(for: .netze), 1)
        XCTAssertGreaterThanOrEqual(answered, 11)
        XCTAssertTrue(exam.dueCards(subject: .it).isEmpty, "Direkt nach der Runde ist nichts fällig")

        clock = clock.addingTimeInterval(86_400 + 60)
        XCTAssertEqual(exam.dueCards(subject: .it).map(\.id), [wrongID], "Nach einem Tag nur die falsche")
        clock = clock.addingTimeInterval(3 * 86_400)
        let due = exam.dueCards(subject: .it)
        XCTAssertEqual(due.count, 10, "Nach vier Tagen sind alle zehn Karten der Lektion fällig")
        XCTAssertTrue(due.contains { $0.id == wrongID })
        XCTAssertEqual(due.map(\.id), due.map(\.id).sorted(), "Gleicher Zeitpunkt: stabile Reihenfolge nach ID")

        // Der Zustand überlebt einen Neustart.
        let reloaded = ExamStore(saveURL: url, now: { clock })
        XCTAssertEqual(reloaded.dueCards(subject: .it).count, 10)

        XCTAssertTrue(reloaded.startReview(subject: .it))
        let session = try XCTUnwrap(reloaded.session(for: .quiz))
        XCTAssertEqual(session.mode, .quiz)
        XCTAssertNil(session.topic)
        XCTAssertEqual(session.isLesson, true)
        XCTAssertEqual(Set(session.tasks.map(\.id)), Set(due.map(\.id)))
        XCTAssertFalse(reloaded.startReview(subject: .it), "Läuft schon eine Runde, startet keine zweite")

        // Wiederholung beantworten: alles richtig, danach ist nichts mehr fällig und keine Lektion zählt.
        while let task = reloaded.session(for: .quiz)?.currentTask {
            reloaded.answer(task.solution, mode: .quiz)
            reloaded.next(mode: .quiz)
        }
        let finished = try XCTUnwrap(reloaded.session(for: .quiz))
        XCTAssertTrue(finished.isComplete)
        path.roundFinished(finished)
        XCTAssertEqual(path.progress.completedCount(for: .netze), 1, "Wiederholung ist keine Lektion")
        XCTAssertTrue(reloaded.dueCards(subject: .it).isEmpty)
    }

    // MARK: Welle 5: Haustier und Belohnungen

    func testGoalAndMilestonesGiveBondOnceAndWeekShowsDays() {
        var p = LearnPathProgress()
        for offset in 0..<7 { p.addXP(100, now: day(offset), calendar: calendar) }
        let expected = 7 * LearnPathProgress.goalBond + 10
        XCTAssertEqual(p.pendingBond, expected, "Tagesziel je Tag plus Meilenstein 7")
        XCTAssertEqual(p.reachedMilestones, [7])
        p.addXP(500, now: day(6), calendar: calendar)
        XCTAssertEqual(p.pendingBond, expected, "Mehr XP am selben Tag gibt keine weiteren Punkte")
        // 2026-11-01 war ein Sonntag: Die Woche Mo 26.10. bis So 01.11. endet am Tag 0.
        let week = p.week(now: day(0), calendar: calendar)
        XCTAssertEqual(week.map(\.label), ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"])
        XCTAssertEqual(week.last?.isToday, true)
        XCTAssertEqual(week.last?.state, .met)
        XCTAssertEqual(week.first?.state, .open, "Vor dem Start der Aufzeichnung: verpasst")
        let next = p.week(now: day(2), calendar: calendar)   // Dienstag 03.11.
        XCTAssertEqual(next.filter(\.isToday).map(\.label), ["Di"])
        XCTAssertEqual(next.first?.state, .met)
    }

    func testSavedProgressFromWelle1And2StillLoads() throws {
        let json = #"{"completedLessons":{"netze":2},"dailyXP":{"2026-11-01":120},"metDays":["2026-11-01"],"frozenDays":[],"goalXP":100,"streakFreezes":1,"lastTotalXP":500}"#
        let p = try JSONDecoder().decode(LearnPathProgress.self, from: Data(json.utf8))
        XCTAssertEqual(p.completedLessons["netze"], 2)
        XCTAssertEqual(p.pendingBond, 0)
        XCTAssertTrue(p.reachedMilestones.isEmpty)
        XCTAssertEqual(try JSONDecoder().decode(LearnPathProgress.self, from: JSONEncoder().encode(p)), p)
    }

    /// Echte Stores und Dateien: Tagesziel erreicht, Bindung beim Haustier, nach Neustart erhalten.
    @MainActor
    func testGoalBondReachesPetAndSurvivesRestart() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let clock = day(0)
        let path = LearnPathStore(saveURL: dir.appendingPathComponent("path.json"), now: { clock }, calendar: calendar)
        let rewards = RewardStore(saveURL: dir.appendingPathComponent("rewards.json"), now: { clock })
        path.observeTotalXP(0)
        path.observeTotalXP(120)
        XCTAssertEqual(path.progress.pendingBond, LearnPathProgress.goalBond)
        path.settleBond(into: rewards)   // noch kein Haustier gewählt
        XCTAssertEqual(path.progress.pendingBond, LearnPathProgress.goalBond, "bleibt offen")
        rewards.updateXP((PetKind.allCases.map(\.unlockLevel).min()! - 1) * 250 + 1)
        XCTAssertNotNil(rewards.selectedPet)
        path.settleBond(into: rewards)
        XCTAssertEqual(path.progress.pendingBond, 0)
        XCTAssertEqual(rewards.bond, LearnPathProgress.goalBond)
        path.settleBond(into: rewards)
        XCTAssertEqual(rewards.bond, LearnPathProgress.goalBond, "nicht doppelt verbucht")

        let reloaded = RewardStore(saveURL: dir.appendingPathComponent("rewards.json"), now: { clock })
        XCTAssertEqual(reloaded.bond, LearnPathProgress.goalBond)
        XCTAssertFalse(reloaded.needsRecovery, "Bonus-Schlüssel gilt nicht als beschädigt")
        XCTAssertTrue(RewardSyncData(interactions: ["fox": [RewardStore.bonusBondKey: 5]]).isValid)
    }

    func testCompanionCelebratesDayGoal() {
        XCTAssertTrue(PetCompanionMessages.dayGoal(streak: 30, turn: 0).contains("30"))
        XCTAssertEqual(PetCompanionMessages.greeting(after: true, turn: 1, goalMet: true, streak: 3),
                       PetCompanionMessages.dayGoal(streak: 3, turn: 0))
        XCTAssertEqual(PetCompanionMessages.greeting(after: false, turn: 1, goalMet: true, streak: 3),
                       PetCompanionMessages.greeting(after: false, turn: 1))
    }
}
