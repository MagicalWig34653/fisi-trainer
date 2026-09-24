// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var progress = PlayerProgress()
    @Published private(set) var session: GameSession?
    @Published private(set) var saveError: String?
    @Published private(set) var learning: [String: LearningRecord] = [:]

    var learningFocus: [String] {
        let topics: [(String, Double)] = PortService.catalog.flatMap { service in
            QuestionKind.allCases.compactMap { kind -> (String, Double)? in
                let record = learning[AdaptiveLearning.portKey(serviceID: service.id, kind: kind)]
                guard let record, record.needsPractice else { return nil }
                let label: String
                switch kind {
                case .port: label = "Port"
                case .service: label = "Dienst"
                case .transport: label = "Transport"
                }
                return ("\(service.name) · \(label)", record.selectionWeight)
            }
        }
        let ranked = topics.sorted { left, right in
            if left.1 == right.1 { return left.0 < right.0 }
            return left.1 > right.1
        }
        return ranked.prefix(3).map { $0.0 }
    }

    var currentQuestion: Question? {
        guard let session, !session.isComplete else { return nil }
        return session.questions[session.index]
    }

    private struct SavedGame: Codable {
        let progress: PlayerProgress
        let session: GameSession?
        let learning: [String: LearningRecord]?
    }

    private let saveURL: URL
    private let fixedQuestions: [Question]?
    private let now: () -> Date
    private var maySave = true

    init(questions: [Question]? = nil, saveURL: URL? = nil,
         now: @escaping () -> Date = Date.init) {
        fixedQuestions = questions
        self.now = now
        self.saveURL = saveURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FiSiTrainer", isDirectory: true)
            .appendingPathComponent("progress.json")
        load()
    }

    func startRound() {
        guard maySave else { return }
        guard session == nil || session?.isComplete == true else { return }
        let questions = fixedQuestions ?? makeQuestions()
        guard !questions.isEmpty else { return }
        var newSession = GameSession(questions: questions)
        newSession.timing = QuestionTiming(startedAt: now())
        newSession.speedBonusTotal = 0
        session = newSession
        save()
    }

    func answer(_ choice: Int) {
        guard maySave, var session, !session.isComplete,
              session.selectedAnswer == nil,
              session.questions[session.index].choices.contains(choice) else { return }

        let correct = choice == session.questions[session.index].correctAnswer
        let question = session.questions[session.index]
        let key = AdaptiveLearning.portKey(serviceID: question.service.id, kind: question.kind)
        var record = learning[key, default: LearningRecord()]
        record.record(correct: correct)
        learning[key] = record
        let answerDate = now()
        var timing = session.timing ?? QuestionTiming(startedAt: answerDate)
        timing.answeredAt = max(answerDate, timing.startedAt)
        let bonus = correct ? timing.availableBonus(at: timing.answeredAt!) : 0
        timing.earnedBonus = bonus
        session.timing = timing
        session.speedBonusTotal = (session.speedBonusTotal ?? 0) + bonus
        session.selectedAnswer = choice
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
        self.session = session
        save()
    }

    func nextQuestion() {
        guard maySave, var session, !session.isComplete,
              session.selectedAnswer != nil else { return }

        session.index += 1
        session.selectedAnswer = nil
        if session.isComplete {
            session.timing = nil
            progress.completedRounds += 1
            progress.totalXP += 50
            progress.bestScore = max(progress.bestScore, session.score)
        } else {
            session.timing = QuestionTiming(startedAt: now())
        }
        self.session = session
        save()
    }

    func resetProgress() {
        if !maySave && FileManager.default.fileExists(atPath: saveURL.path) {
            let backupURL = saveURL.deletingLastPathComponent()
                .appendingPathComponent("progress.corrupt.\(UUID().uuidString).json")
            do {
                try FileManager.default.moveItem(at: saveURL, to: backupURL)
            } catch {
                saveError = "Beschädigten Spielstand konnte ich nicht sichern: \(error.localizedDescription)"
                return
            }
        }
        maySave = true
        progress = PlayerProgress()
        learning = [:]
        session = nil
        saveError = nil
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            let saved = try JSONDecoder().decode(SavedGame.self, from: data)
            guard Self.isValid(saved) else {
                throw CocoaError(.coderInvalidValue)
            }
            progress = saved.progress
            session = saved.session
            learning = saved.learning ?? [:]
            if var session, !session.isComplete, session.selectedAnswer == nil,
               session.timing == nil {
                session.timing = QuestionTiming(startedAt: now())
                self.session = session
                save()
            }
        } catch {
            maySave = false
            saveError = "Spielstand konnte nicht gelesen werden: \(error.localizedDescription)"
        }
    }

    private func save() {
        guard maySave else { return }
        do {
            try FileManager.default.createDirectory(
                at: saveURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(SavedGame(
                progress: progress, session: session, learning: learning))
            try data.write(to: saveURL, options: .atomic)
            saveError = nil
        } catch {
            saveError = "Spielstand konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    private func makeQuestions() -> [Question] {
        let kinds: [QuestionKind] = ([QuestionKind.port, .service, .transport] +
            Array(repeating: .port, count: 3) +
            Array(repeating: .service, count: 2) +
            Array(repeating: .transport, count: 2)).shuffled()
        var generator = SystemRandomNumberGenerator()
        var available = PortService.catalog
        let selected = kinds.compactMap { kind -> (PortService, QuestionKind)? in
            let service = AdaptiveLearning.weightedSample(available, count: 1,
                using: &generator) { service in
                learning[AdaptiveLearning.portKey(serviceID: service.id, kind: kind)]?
                    .selectionWeight ?? LearningRecord().selectionWeight
            }.first
            guard let service else { return nil }
            available.removeAll { $0.id == service.id }
            return (service, kind)
        }
        return selected.map { service, kind in
            switch kind {
            case .port:
                let choices = ([service.port] + PortService.catalog
                    .filter { $0.port != service.port }
                    .map(\.port).shuffled().prefix(3)).shuffled()
                return Question(service: service, choices: choices,
                                correctAnswer: service.port, questionKind: .port)
            case .service:
                let options = ([service] + PortService.catalog
                    .filter { $0.port != service.port }
                    .shuffled().prefix(3)).shuffled()
                return Question(service: service, choices: options.map(\.port),
                                correctAnswer: service.port, questionKind: .service,
                                labels: options.map(\.name))
            case .transport:
                let labels = ["TCP", "UDP", "TCP und UDP"]
                let answer: Int
                switch service.transport {
                case Transport.tcp.rawValue: answer = 0
                case Transport.udp.rawValue: answer = 1
                default: answer = 2
                }
                let choices = [0, 1, 2].shuffled()
                return Question(service: service, choices: choices,
                                correctAnswer: answer, questionKind: .transport,
                                labels: choices.map { labels[$0] })
            }
        }
    }

    private static func isValid(_ saved: SavedGame) -> Bool {
        let progress = saved.progress
        guard progress.totalXP >= 0, progress.completedRounds >= 0,
              progress.bestScore >= 0, progress.correctAnswers >= 0,
              progress.answeredQuestions >= progress.correctAnswers else { return false }
        guard saved.learning?.values.allSatisfy(\.isValid) ?? true else { return false }
        guard let session = saved.session else { return true }
        guard !session.questions.isEmpty, (0...session.questions.count).contains(session.index),
              session.score >= 0, session.correctCount >= 0, session.streak >= 0 else { return false }
        if session.isComplete && session.selectedAnswer != nil { return false }
        if let answer = session.selectedAnswer,
           !session.questions[session.index].choices.contains(answer) { return false }
        if let total = session.speedBonusTotal, total < 0 { return false }
        if let timing = session.timing {
            guard timing.isValid else { return false }
            if session.isComplete { return false }
            if session.selectedAnswer == nil {
                guard timing.answeredAt == nil, timing.earnedBonus == nil else { return false }
            } else {
                guard timing.answeredAt != nil, timing.earnedBonus != nil else { return false }
            }
        }
        return session.questions.allSatisfy(\.isValid)
    }
}
