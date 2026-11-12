// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Rechenlogik des Lernpfads: Lektionen je Thema, Tages-XP, Tagesziel und Streak.
/// Alle Funktionen bekommen Datum und Kalender übergeben, damit sie testbar sind.
struct LearnPathProgress: Codable, Equatable {
    static let lessonsPerTopic = 5
    static let defaultGoalXP = 100
    static let maxFreezes = 2
    static let freezeInterval = 7

    /// Fertige Lektionen je Thema (`ExamTopic.rawValue`).
    var completedLessons: [String: Int] = [:]
    /// Verdiente XP je Kalendertag (`yyyy-MM-dd`).
    var dailyXP: [String: Int] = [:]
    /// Tage, an denen das Tagesziel erreicht wurde.
    var metDays: Set<String> = []
    /// Tage, die ein Streak-Schutz überbrückt hat.
    var frozenDays: Set<String> = []
    var goalXP = LearnPathProgress.defaultGoalXP
    var streakFreezes = 0
    /// Summen-XP beim letzten Abgleich; nil, solange noch nichts beobachtet wurde.
    var lastTotalXP: Int?
    /// Bereits belohnte Streak-Meilensteine (7, 30, 100 Tage); jeder zählt einmalig.
    var reachedMilestones: Set<Int> = []
    /// Bindungspunkte fürs Haustier, die noch nicht verbucht sind (Tagesziel, Meilensteine).
    var pendingBond = 0

    static let milestones: [(days: Int, bond: Int)] = [(7, 10), (30, 25), (100, 60)]
    static let goalBond = 2

    init() {}

    /// Ältere Spielstände kennen die neueren Felder nicht und bleiben lesbar.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        completedLessons = try values.decodeIfPresent([String: Int].self, forKey: .completedLessons) ?? [:]
        dailyXP = try values.decodeIfPresent([String: Int].self, forKey: .dailyXP) ?? [:]
        metDays = try values.decodeIfPresent(Set<String>.self, forKey: .metDays) ?? []
        frozenDays = try values.decodeIfPresent(Set<String>.self, forKey: .frozenDays) ?? []
        goalXP = try values.decodeIfPresent(Int.self, forKey: .goalXP) ?? Self.defaultGoalXP
        streakFreezes = try values.decodeIfPresent(Int.self, forKey: .streakFreezes) ?? 0
        lastTotalXP = try values.decodeIfPresent(Int.self, forKey: .lastTotalXP)
        reachedMilestones = try values.decodeIfPresent(Set<Int>.self, forKey: .reachedMilestones) ?? []
        pendingBond = try values.decodeIfPresent(Int.self, forKey: .pendingBond) ?? 0
    }

    // MARK: Lektionen

    func completedCount(for topic: ExamTopic) -> Int {
        min(max(completedLessons[topic.rawValue] ?? 0, 0), Self.lessonsPerTopic)
    }

    /// Index der nächsten Lektion (0 bis 4) oder nil, wenn das Thema fertig ist.
    func nextLesson(for topic: ExamTopic) -> Int? {
        let done = completedCount(for: topic)
        return done < Self.lessonsPerTopic ? done : nil
    }

    func isTopicDone(_ topic: ExamTopic) -> Bool { nextLesson(for: topic) == nil }

    mutating func completeLesson(topic: ExamTopic) {
        guard nextLesson(for: topic) != nil else { return }
        completedLessons[topic.rawValue] = completedCount(for: topic) + 1
    }

    var totalCompletedLessons: Int {
        ExamTopic.allCases.reduce(0) { $0 + completedCount(for: $1) }
    }

    // MARK: Tage

    static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private func previousDay(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -1, to: date) ?? date.addingTimeInterval(-86_400)
    }

    private func isCovered(_ key: String) -> Bool { metDays.contains(key) || frozenDays.contains(key) }

    func xp(on date: Date, calendar: Calendar) -> Int {
        dailyXP[Self.dayKey(date, calendar: calendar)] ?? 0
    }

    func isGoalMet(on date: Date, calendar: Calendar) -> Bool {
        metDays.contains(Self.dayKey(date, calendar: calendar))
    }

    // MARK: Tagesziel

    static let goalChoices: [(title: String, xp: Int)] = [("Locker", 50), ("Normal", 100), ("Intensiv", 200)]

    /// Ändert das Tagesziel. Bereits erreichte Tage bleiben erreicht; heute zählt ab sofort das neue Ziel.
    mutating func setGoal(_ xp: Int, now: Date, calendar: Calendar) {
        guard Self.goalChoices.contains(where: { $0.xp == xp }), xp != goalXP else { return }
        goalXP = xp
        let today = Self.dayKey(now, calendar: calendar)
        if !metDays.contains(today), (dailyXP[today] ?? 0) >= xp {
            bridgeGap(before: now, calendar: calendar)
            metDays.insert(today)
            goalReached(now: now, calendar: calendar)
        }
    }

    // MARK: XP und Streak

    /// Gleicht die Summen-XP aller Spiele ab. Der erste Aufruf zählt keine Alt-XP, ein sinkender
    /// Wert (Zurücksetzen eines Spiels) setzt nur die Basis neu.
    mutating func observeTotalXP(_ total: Int, now: Date, calendar: Calendar) {
        guard let last = lastTotalXP else {
            lastTotalXP = total
            return
        }
        lastTotalXP = total
        if total > last { addXP(total - last, now: now, calendar: calendar) }
    }

    mutating func addXP(_ amount: Int, now: Date, calendar: Calendar) {
        guard amount > 0 else { return }
        let today = Self.dayKey(now, calendar: calendar)
        dailyXP[today, default: 0] += amount
        if (dailyXP[today] ?? 0) >= goalXP, !metDays.contains(today) {
            bridgeGap(before: now, calendar: calendar)
            metDays.insert(today)
            if currentStreak(now: now, calendar: calendar) % Self.freezeInterval == 0 {
                streakFreezes = min(streakFreezes + 1, Self.maxFreezes)
            }
            goalReached(now: now, calendar: calendar)
        }
    }

    /// Das Tagesziel wurde heute erstmals erreicht: Bindungspunkte fürs Haustier, dazu einmalig je Meilenstein.
    private mutating func goalReached(now: Date, calendar: Calendar) {
        pendingBond += Self.goalBond
        let streak = currentStreak(now: now, calendar: calendar)
        for milestone in Self.milestones where streak >= milestone.days && !reachedMilestones.contains(milestone.days) {
            reachedMilestones.insert(milestone.days)
            pendingBond += milestone.bond
        }
    }

    // MARK: Woche

    enum DayState: Equatable { case met, frozen, open, future }

    struct WeekDay: Equatable {
        let key: String
        let label: String
        let isToday: Bool
        let state: DayState
    }

    private static let weekdayLabels = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]

    /// Die sieben Tage der laufenden Woche (Montag bis Sonntag) mit Stand des Tagesziels.
    func week(now: Date, calendar: Calendar) -> [WeekDay] {
        let weekday = calendar.component(.weekday, from: now)   // 1 = Sonntag
        let offsetToMonday = (weekday + 5) % 7
        let todayKey = Self.dayKey(now, calendar: calendar)
        return (0..<7).map { index in
            let date = calendar.date(byAdding: .day, value: index - offsetToMonday, to: now)
                ?? now.addingTimeInterval(Double(index - offsetToMonday) * 86_400)
            let key = Self.dayKey(date, calendar: calendar)
            let state: DayState = metDays.contains(key) ? .met : frozenDays.contains(key) ? .frozen
                : (index > offsetToMonday ? .future : .open)
            let label = Self.weekdayLabels[(calendar.component(.weekday, from: date) + 6) % 7]
            return WeekDay(key: key, label: label, isToday: key == todayKey, state: state)
        }
    }

    /// Überbrückt genau einen verpassten Tag vor `now` mit einem Streak-Schutz.
    private mutating func bridgeGap(before now: Date, calendar: Calendar) {
        let yesterday = previousDay(now, calendar: calendar)
        let dayBefore = previousDay(yesterday, calendar: calendar)
        let yKey = Self.dayKey(yesterday, calendar: calendar)
        guard streakFreezes > 0, !isCovered(yKey),
              isCovered(Self.dayKey(dayBefore, calendar: calendar)) else { return }
        frozenDays.insert(yKey)
        streakFreezes -= 1
    }

    /// Aktuelle Serie von Tagen mit erreichtem Tagesziel. Ist das Ziel heute noch offen, zählt
    /// die Serie bis gestern; ein verfügbarer Schutz hält sie über einen verpassten Tag.
    func currentStreak(now: Date, calendar: Calendar) -> Int {
        var day = now
        if !isCovered(Self.dayKey(day, calendar: calendar)) {
            day = previousDay(day, calendar: calendar)
        }
        var count = 0
        var bridged = false
        var guardCounter = 0
        while guardCounter < 4000 {
            guardCounter += 1
            let key = Self.dayKey(day, calendar: calendar)
            if metDays.contains(key) {
                count += 1
            } else if frozenDays.contains(key) {
                // überbrückt, zählt nicht mit
            } else if streakFreezes > 0, !bridged, count == 0,
                      isCovered(Self.dayKey(previousDay(day, calendar: calendar), calendar: calendar)) {
                bridged = true   // gestern verpasst, Schutz hält die Serie
            } else {
                break
            }
            day = previousDay(day, calendar: calendar)
        }
        return count
    }
}

/// Hält den Fortschritt im Lernpfad und startet Lektionen über den `ExamStore`.
@MainActor
final class LearnPathStore: ObservableObject {
    @Published private(set) var progress = LearnPathProgress()
    @Published private(set) var saveError: String?

    private let saveURL: URL
    private let now: () -> Date
    private let calendar: Calendar
    private var maySave = true
    /// Die laufende Lektion: Thema und Startzeit der Runde im `ExamStore`.
    private var pending: (topic: ExamTopic, startedAt: Date)?

    init(saveURL: URL? = nil, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
        self.saveURL = saveURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FiSiTrainer", isDirectory: true)
            .appendingPathComponent("learnpath-progress.json")
        load()
    }

    var streak: Int { progress.currentStreak(now: now(), calendar: calendar) }
    var todayXP: Int { progress.xp(on: now(), calendar: calendar) }
    var goalXP: Int { progress.goalXP }
    func setGoal(_ xp: Int) {
        progress.setGoal(xp, now: now(), calendar: calendar)
        save()
    }
    var week: [LearnPathProgress.WeekDay] { progress.week(now: now(), calendar: calendar) }
    var goalMetToday: Bool { progress.isGoalMet(on: now(), calendar: calendar) }

    /// Startet die nächste Lektion eines Themas. Läuft schon eine Prüfungsquiz-Runde, wird sie
    /// nur weitergeführt und zählt nicht als Lektion. Gibt zurück, ob eine neue Runde begann.
    @discardableResult
    func startLesson(topic: ExamTopic, exam: ExamStore) -> Bool {
        guard progress.nextLesson(for: topic) != nil, !exam.hasActiveSession(.quiz) else { return false }
        exam.start(mode: .quiz, subject: topic.subject, topic: topic, lesson: true)
        guard let session = exam.session(for: .quiz), !session.isComplete, session.topic == topic else { return false }
        pending = (topic, session.startedAt)
        return true
    }

    /// Wertet eine beendete Runde aus: Gehört sie zur laufenden Lektion, wird diese fertig.
    func roundFinished(_ session: ExamSession?) {
        guard let session, session.isComplete, session.mode == .quiz,
              let pending, pending.topic == session.topic, pending.startedAt == session.startedAt else { return }
        self.pending = nil
        progress.completeLesson(topic: pending.topic)
        save()
    }

    /// Verbucht offene Bindungspunkte beim gewählten Haustier. Bleibt etwas offen (kein Haustier,
    /// beschädigter Spielstand), wird es beim nächsten Mal erneut versucht.
    func settleBond(into rewards: RewardStore) {
        let amount = progress.pendingBond
        guard amount > 0, rewards.addBond(amount) else { return }
        progress.pendingBond = 0
        save()
    }

    func observeTotalXP(_ total: Int) {
        let before = progress
        progress.observeTotalXP(total, now: now(), calendar: calendar)
        if progress != before { save() }
    }

    // MARK: Persistenz

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let saved = try JSONDecoder().decode(LearnPathProgress.self, from: Data(contentsOf: saveURL))
            guard saved.goalXP > 0, saved.streakFreezes >= 0, saved.pendingBond >= 0,
                  saved.streakFreezes <= LearnPathProgress.maxFreezes,
                  saved.dailyXP.values.allSatisfy({ $0 >= 0 }) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            progress = saved
        } catch {
            // Defekte Datei: nicht überschreiben, sondern beiseitelegen.
            maySave = true
            let backup = saveURL.deletingLastPathComponent()
                .appendingPathComponent("learnpath-progress.corrupt.\(UUID().uuidString).json")
            try? FileManager.default.moveItem(at: saveURL, to: backup)
            saveError = "Lernpfad-Spielstand war beschädigt und wurde gesichert."
        }
    }

    private func save() {
        guard maySave else { return }
        do {
            try FileManager.default.createDirectory(
                at: saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(progress).write(to: saveURL, options: .atomic)
        } catch {
            saveError = "Lernpfad-Spielstand konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }
}
