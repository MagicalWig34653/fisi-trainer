// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// One round of the exam trainer, played in a single mode.
struct ExamSession: Codable {
    let mode: ExamMode
    let subject: ExamSubject
    let topic: ExamTopic?
    let tasks: [ExamTask]
    var index = 0
    var answers: [[Int]] = []
    var score = 0
    var correctCount = 0
    var credit: Double = 0
    var streak = 0
    var timing: QuestionTiming? = nil
    var speedBonusTotal = 0
    let startedAt: Date
    var finishedAt: Date? = nil

    var isComplete: Bool { index >= tasks.count }
    var currentTask: ExamTask? { isComplete ? nil : tasks[index] }
    var isCurrentAnswered: Bool { !isComplete && answers.count > index }
    var currentAnswer: [Int]? { isCurrentAnswered ? answers[index] : nil }
    var percent: Double { tasks.isEmpty ? 0 : credit / Double(tasks.count) * 100 }
    /// Whether the resolution (solution and explanation) for the current task may be shown.
    /// Exam-simulation mode never pauses for a resolution before the round ends.
    var showsResolution: Bool { mode != .exam && isCurrentAnswered }
}

/// A finished exam simulation, kept for the history list.
struct ExamResult: Codable, Equatable {
    let date: Date
    let subject: ExamSubject
    let percent: Double
    let duration: TimeInterval

    var grade: (note: Int, title: String) { ExamGrade.grade(forPercent: percent) }
}

@MainActor
final class ExamStore: ObservableObject {
    @Published private(set) var progress = PlayerProgress()
    @Published private(set) var sessions: [ExamMode: ExamSession] = [:]
    @Published private(set) var learning: [String: LearningRecord] = [:]
    @Published private(set) var examHistory: [ExamResult] = []
    @Published private(set) var saveError: String?

    private struct SavedGame: Codable {
        let progress: PlayerProgress
        let sessions: [String: ExamSession]
        let learning: [String: LearningRecord]?
        let examHistory: [ExamResult]?
    }

    private let saveURL: URL
    private let catalog: [ExamCard]
    private let fixedTasks: [ExamTask]?
    private let now: () -> Date
    private var maySave = true

    init(saveURL: URL? = nil, now: @escaping () -> Date = Date.init,
         catalog: [ExamCard] = ExamCatalog.all, fixedTasks: [ExamTask]? = nil) {
        self.catalog = catalog
        self.fixedTasks = fixedTasks
        self.now = now
        self.saveURL = saveURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FiSiTrainer", isDirectory: true)
            .appendingPathComponent("exam-progress.json")
        load()
    }

    func session(for mode: ExamMode) -> ExamSession? { sessions[mode] }

    func hasActiveSession(_ mode: ExamMode) -> Bool {
        guard let session = sessions[mode] else { return false }
        return !session.isComplete
    }

    func start(mode: ExamMode, subject: ExamSubject, topic: ExamTopic?) {
        guard maySave, !hasActiveSession(mode) else { return }
        let effectiveTopic = mode == .exam ? nil : topic
        var generator = SystemRandomNumberGenerator()
        let tasks = fixedTasks ?? ExamTaskFactory.makeRound(
            mode: mode, subject: subject, topic: effectiveTopic, catalog: catalog,
            using: &generator
        ) { [learning] id in
            learning[Self.learningKey(id)]?.selectionWeight ?? LearningRecord().selectionWeight
        }
        guard !tasks.isEmpty else { return }
        var session = ExamSession(mode: mode, subject: subject, topic: effectiveTopic,
                                  tasks: tasks, startedAt: now())
        session.timing = QuestionTiming(startedAt: now())
        sessions[mode] = session
        save()
    }

    func answer(_ answer: [Int], mode: ExamMode) {
        guard maySave, var session = sessions[mode], !session.isComplete,
              !session.isCurrentAnswered, let task = session.currentTask,
              task.accepts(answer) else { return }

        let correct = task.isCorrect(answer)
        let key = Self.learningKey(task.id)
        var record = learning[key, default: LearningRecord()]
        record.record(correct: correct)
        learning[key] = record

        let answerDate = now()
        var timing = session.timing ?? QuestionTiming(startedAt: answerDate)
        let answeredAt = max(answerDate, timing.startedAt)
        timing.answeredAt = answeredAt
        let bonus = correct ? timing.availableBonus(at: answeredAt) : 0
        timing.earnedBonus = bonus
        session.timing = timing
        session.speedBonusTotal += bonus
        session.answers.append(answer)
        session.credit += task.credit(for: answer)

        progress.answeredQuestions += 1
        if correct {
            session.streak += 1
            session.correctCount += 1
            session.score += 100 + min(max(session.streak - 1, 0) * 10, 50)
            progress.correctAnswers += 1
            progress.totalXP += 25 + bonus
        } else {
            session.streak = 0
            progress.totalXP += 5
        }

        if mode == .exam {
            session.index += 1
            if session.isComplete {
                finishExam(&session, mode: mode)
            } else {
                session.timing = QuestionTiming(startedAt: now())
            }
        }

        sessions[mode] = session
        save()
    }

    func next(mode: ExamMode) {
        guard maySave, var session = sessions[mode], !session.isComplete,
              session.isCurrentAnswered else { return }
        session.index += 1
        if session.isComplete {
            session.timing = nil
            session.finishedAt = now()
            progress.completedRounds += 1
            progress.totalXP += mode.completionBonus
            progress.bestScore = max(progress.bestScore, session.score)
        } else {
            session.timing = QuestionTiming(startedAt: now())
        }
        sessions[mode] = session
        save()
    }

    func abandon(mode: ExamMode) {
        guard maySave, sessions[mode] != nil else { return }
        sessions[mode] = nil
        save()
    }

    func resetProgress() {
        if !maySave && FileManager.default.fileExists(atPath: saveURL.path) {
            let backupURL = saveURL.deletingLastPathComponent()
                .appendingPathComponent("exam-progress.corrupt.\(UUID().uuidString).json")
            do {
                try FileManager.default.moveItem(at: saveURL, to: backupURL)
            } catch {
                saveError = "Beschädigten Spielstand konnte ich nicht sichern: \(error.localizedDescription)"
                return
            }
        }
        maySave = true
        progress = PlayerProgress()
        sessions = [:]
        learning = [:]
        examHistory = []
        saveError = nil
        save()
    }

    func learningFocus(subject: ExamSubject) -> [String] {
        let entries: [(id: String, weight: Double, topic: ExamTopic, title: String)] =
            learning.compactMap { key, record in
                guard key.hasPrefix("exam:"), record.needsPractice else { return nil }
                let id = String(key.dropFirst("exam:".count))
                guard let info = Self.taskInfo(for: id, catalog: catalog),
                      info.topic.subject == subject else { return nil }
                return (id, record.selectionWeight, info.topic, info.title)
            }
        let ranked = entries.sorted { left, right in
            if left.weight == right.weight { return left.id < right.id }
            return left.weight > right.weight
        }
        return ranked.prefix(3).map { "\($0.topic.title) · \($0.title)" }
    }

    func topicAccuracy(_ topic: ExamTopic) -> Double? {
        var attempts = 0
        var correct = 0
        for (key, record) in learning {
            guard key.hasPrefix("exam:") else { continue }
            let id = String(key.dropFirst("exam:".count))
            guard let info = Self.taskInfo(for: id, catalog: catalog), info.topic == topic else { continue }
            attempts += record.attempts
            correct += record.correct
        }
        guard attempts > 0 else { return nil }
        return Double(correct) / Double(attempts)
    }

    nonisolated static func learningKey(_ taskID: String) -> String { "exam:\(taskID)" }

    private func finishExam(_ session: inout ExamSession, mode: ExamMode) {
        session.timing = nil
        let finishDate = now()
        session.finishedAt = finishDate
        progress.completedRounds += 1
        progress.totalXP += mode.completionBonus
        progress.bestScore = max(progress.bestScore, session.score)
        let duration = max(0, finishDate.timeIntervalSince(session.startedAt))
        let result = ExamResult(date: finishDate, subject: session.subject,
                                percent: session.percent, duration: duration)
        examHistory.insert(result, at: 0)
        if examHistory.count > 20 { examHistory.removeLast(examHistory.count - 20) }
    }

    /// Maps a learning key's task id back to its topic and a short display title.
    private static func taskInfo(for id: String, catalog: [ExamCard]) -> (topic: ExamTopic, title: String)? {
        if let calculation = ExamCalculation.allCases.first(where: { $0.id == id }) {
            return (calculation.topic, calculation.title)
        }
        if let card = catalog.first(where: { $0.id == id }) {
            return (card.topic, truncate(cardTitle(card)))
        }
        return nil
    }

    private static func cardTitle(_ card: ExamCard) -> String {
        switch card {
        case .choice(_, _, let prompt, _, _): prompt
        case .statement(_, _, let text, _, _): text
        case .multiple(_, _, let prompt, _, _, _): prompt
        case .match(_, _, let prompt, _, _, _): prompt
        case .order(_, _, let prompt, _, _): prompt
        case .gap(_, _, let title, _, _, _): title
        case .fact(_, _, _, let question, _, _): question
        }
    }

    private static func truncate(_ text: String, limit: Int = 40) -> String {
        guard text.count > limit else { return text }
        let cut = text.index(text.startIndex, offsetBy: limit)
        return text[..<cut].trimmingCharacters(in: .whitespaces) + "…"
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            let saved = try JSONDecoder().decode(SavedGame.self, from: data)
            guard Self.isValid(saved) else { throw CocoaError(.coderInvalidValue) }
            progress = saved.progress
            sessions = Dictionary(uniqueKeysWithValues: saved.sessions.compactMap { key, session in
                ExamMode(rawValue: key).map { ($0, session) }
            })
            learning = saved.learning ?? [:]
            examHistory = saved.examHistory ?? []
            var didResumeTiming = false
            for (mode, var session) in sessions {
                if !session.isComplete, !session.isCurrentAnswered, session.timing == nil {
                    session.timing = QuestionTiming(startedAt: now())
                    sessions[mode] = session
                    didResumeTiming = true
                }
            }
            if didResumeTiming { save() }
        } catch {
            maySave = false
            saveError = "Prüfungs-Spielstand konnte nicht gelesen werden: \(error.localizedDescription)"
        }
    }

    private func save() {
        guard maySave else { return }
        do {
            try FileManager.default.createDirectory(
                at: saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let sessionsByKey = Dictionary(uniqueKeysWithValues: sessions.map { ($0.key.rawValue, $0.value) })
            let data = try JSONEncoder().encode(SavedGame(
                progress: progress, sessions: sessionsByKey, learning: learning, examHistory: examHistory))
            try data.write(to: saveURL, options: .atomic)
            saveError = nil
        } catch {
            saveError = "Prüfungs-Spielstand konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    private static func isValid(_ saved: SavedGame) -> Bool {
        let progress = saved.progress
        guard progress.totalXP >= 0, progress.completedRounds >= 0,
              progress.bestScore >= 0, progress.correctAnswers >= 0,
              progress.answeredQuestions >= progress.correctAnswers else { return false }
        guard saved.learning?.values.allSatisfy(\.isValid) ?? true else { return false }
        guard (saved.examHistory?.count ?? 0) <= 20 else { return false }
        guard saved.examHistory?.allSatisfy({
            $0.percent >= 0 && $0.percent <= 100 && $0.duration >= 0 &&
                $0.date.timeIntervalSinceReferenceDate.isFinite
        }) ?? true else { return false }
        for (key, session) in saved.sessions {
            guard let mode = ExamMode(rawValue: key), isValid(session, mode: mode) else { return false }
        }
        return true
    }

    private static func isValid(_ session: ExamSession, mode: ExamMode) -> Bool {
        guard session.mode == mode, !session.tasks.isEmpty, session.tasks.allSatisfy(\.isValid),
              (0...session.tasks.count).contains(session.index),
              session.score >= 0, session.correctCount >= 0, session.correctCount <= session.tasks.count,
              session.credit >= -0.0001, session.credit <= Double(session.tasks.count) + 0.0001,
              session.streak >= 0, session.streak <= session.tasks.count,
              session.speedBonusTotal >= 0 else { return false }

        let allowedCounts: Set<Int> = (mode == .exam || session.isComplete)
            ? [session.index]
            : [session.index, session.index + 1]
        guard allowedCounts.contains(session.answers.count),
              session.answers.count <= session.tasks.count else { return false }
        for index in session.answers.indices {
            guard session.tasks[index].accepts(session.answers[index]) else { return false }
        }

        if session.isComplete {
            guard session.finishedAt != nil else { return false }
        } else {
            guard session.finishedAt == nil else { return false }
        }

        if let timing = session.timing {
            guard timing.isValid else { return false }
            if session.isComplete { return false }
            if session.isCurrentAnswered {
                guard timing.answeredAt != nil, timing.earnedBonus != nil else { return false }
            } else {
                guard timing.answeredAt == nil, timing.earnedBonus == nil else { return false }
            }
        }
        return true
    }
}
