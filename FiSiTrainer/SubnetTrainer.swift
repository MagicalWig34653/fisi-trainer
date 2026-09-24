// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import SwiftUI

enum SubnetQuestionKind: String, Codable {
    case mask, hosts
}

struct SubnetQuestion: Codable {
    let prefix: Int
    let kind: SubnetQuestionKind
    let prompt: String
    let choices: [String]
    let correctAnswer: String
    let explanation: String

    var isValid: Bool {
        (16...30).contains(prefix) && choices.count == 4 &&
        Set(choices).count == 4 && choices.contains(correctAnswer) &&
        correctAnswer == (kind == .mask
            ? SubnetStore.mask(for: prefix)
            : String(SubnetStore.usableHosts(for: prefix))) &&
        !prompt.isEmpty && !explanation.isEmpty
    }
}

struct SubnetSession: Codable {
    let questions: [SubnetQuestion]
    var index = 0
    var selectedAnswer: String? = nil
    var score = 0
    var correctCount = 0
    var timing: QuestionTiming? = nil
    var speedBonusTotal: Int? = nil

    var isComplete: Bool { index >= questions.count }
}

@MainActor
final class SubnetStore: ObservableObject {
    @Published private(set) var progress = PlayerProgress()
    @Published private(set) var session: SubnetSession?
    @Published private(set) var saveError: String?
    @Published private(set) var learning: [String: LearningRecord] = [:]

    var learningFocus: [String] {
        let topics: [(String, Double)] = (16...30).flatMap { prefix in
            [SubnetQuestionKind.mask, .hosts].compactMap { kind -> (String, Double)? in
                let record = learning[AdaptiveLearning.subnetKey(prefix: prefix, kind: kind)]
                guard let record, record.needsPractice else { return nil }
                return ("/\(prefix) · \(kind == .mask ? "Maske" : "Hosts")",
                        record.selectionWeight)
            }
        }
        let ranked = topics.sorted { left, right in
            if left.1 == right.1 { return left.0 < right.0 }
            return left.1 > right.1
        }
        return ranked.prefix(3).map { $0.0 }
    }

    var currentQuestion: SubnetQuestion? {
        guard let session, !session.isComplete else { return nil }
        return session.questions[session.index]
    }

    private struct SavedGame: Codable {
        let progress: PlayerProgress
        let session: SubnetSession?
        let learning: [String: LearningRecord]?
    }

    private let saveURL: URL
    private let fixedQuestions: [SubnetQuestion]?
    private let now: () -> Date
    private var maySave = true

    init(questions: [SubnetQuestion]? = nil, saveURL: URL? = nil,
         now: @escaping () -> Date = Date.init) {
        fixedQuestions = questions
        self.now = now
        self.saveURL = saveURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FiSiTrainer", isDirectory: true)
            .appendingPathComponent("subnet-progress.json")
        load()
    }

    func startRound() {
        guard maySave, session == nil || session?.isComplete == true else { return }
        let questions = fixedQuestions ?? makeQuestions()
        guard !questions.isEmpty, questions.allSatisfy(\.isValid) else { return }
        var newSession = SubnetSession(questions: questions)
        newSession.timing = QuestionTiming(startedAt: now())
        newSession.speedBonusTotal = 0
        session = newSession
        save()
    }

    func answer(_ choice: String) {
        guard maySave, var session, !session.isComplete,
              session.selectedAnswer == nil,
              session.questions[session.index].choices.contains(choice) else { return }
        let correct = choice == session.questions[session.index].correctAnswer
        let question = session.questions[session.index]
        let key = AdaptiveLearning.subnetKey(prefix: question.prefix, kind: question.kind)
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
            session.correctCount += 1
            session.score += 100
            progress.correctAnswers += 1
            progress.totalXP += 25 + bonus
        } else {
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
                .appendingPathComponent("subnet-progress.corrupt.\(UUID().uuidString).json")
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
            let saved = try JSONDecoder().decode(SavedGame.self, from: Data(contentsOf: saveURL))
            guard Self.isValid(saved) else { throw CocoaError(.coderInvalidValue) }
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
            saveError = "Subnetz-Spielstand konnte nicht gelesen werden: \(error.localizedDescription)"
        }
    }

    private func save() {
        guard maySave else { return }
        do {
            try FileManager.default.createDirectory(
                at: saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(SavedGame(
                progress: progress, session: session, learning: learning))
            try data.write(to: saveURL, options: .atomic)
            saveError = nil
        } catch {
            saveError = "Subnetz-Spielstand konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    nonisolated static func mask(for prefix: Int) -> String {
        precondition((16...30).contains(prefix))
        let bits = UInt32.max << (32 - prefix)
        return (0..<4).map { String((bits >> (24 - $0 * 8)) & 255) }.joined(separator: ".")
    }

    nonisolated static func usableHosts(for prefix: Int) -> Int {
        precondition((16...30).contains(prefix))
        return (1 << (32 - prefix)) - 2
    }

    private func makeQuestions() -> [SubnetQuestion] {
        let kinds: [SubnetQuestionKind] =
            (Array(repeating: .mask, count: 5) + Array(repeating: .hosts, count: 5)).shuffled()
        var generator = SystemRandomNumberGenerator()
        var available = Array(16...30)
        let selected = kinds.compactMap { kind -> (Int, SubnetQuestionKind)? in
            let prefix = AdaptiveLearning.weightedSample(available, count: 1,
                using: &generator) { prefix in
                learning[AdaptiveLearning.subnetKey(prefix: prefix, kind: kind)]?
                    .selectionWeight ?? LearningRecord().selectionWeight
            }.first
            guard let prefix else { return nil }
            available.removeAll { $0 == prefix }
            return (prefix, kind)
        }
        return selected.map { prefix, kind in
            let candidates = (16...30).filter { $0 != prefix }
                .sorted { abs($0 - prefix) < abs($1 - prefix) }
            let other = Array(candidates.prefix(3))
            switch kind {
            case .mask:
                let answer = Self.mask(for: prefix)
                return SubnetQuestion(
                    prefix: prefix, kind: kind,
                    prompt: "Welche Subnetzmaske gehört zu /\(prefix)?",
                    choices: ([answer] + other.map { Self.mask(for: $0) }).shuffled(),
                    correctAnswer: answer,
                    explanation: "/\(prefix) bedeutet \(prefix) gesetzte Netzbits. Die Maske lautet \(answer).")
            case .hosts:
                let answer = String(Self.usableHosts(for: prefix))
                return SubnetQuestion(
                    prefix: prefix, kind: kind,
                    prompt: "Wie viele nutzbare Host-Adressen hat ein IPv4-/\(prefix)-Netz?",
                    choices: ([answer] + other.map { String(Self.usableHosts(for: $0)) }).shuffled(),
                    correctAnswer: answer,
                    explanation: "32 − \(prefix) = \(32 - prefix) Hostbits. " +
                        "2^\(32 - prefix) − 2 = \(answer) nutzbare Adressen " +
                        "(Netz- und Broadcast-Adresse abgezogen).")
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
              session.correctCount >= 0, session.correctCount <= session.questions.count,
              session.score == session.correctCount * 100,
              session.questions.allSatisfy(\.isValid) else { return false }
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
        if session.isComplete { return session.selectedAnswer == nil }
        return session.selectedAnswer == nil ||
            session.questions[session.index].choices.contains(session.selectedAnswer!)
    }
}

private enum SubnetStyle {
    static let surface = Color(red: 0.078, green: 0.113, blue: 0.151)
    static let raised = Color(red: 0.103, green: 0.145, blue: 0.183)
    static let primary = Color(red: 0.94, green: 0.97, blue: 0.96)
    static let muted = Color(red: 0.53, green: 0.61, blue: 0.64)
    static let accent = Color(red: 0.76, green: 0.97, blue: 0.32)
    static let red = Color(red: 1.0, green: 0.45, blue: 0.43)
}

struct SubnetTrainerView: View {
    @EnvironmentObject private var store: SubnetStore
    @State private var showingResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 9) {
                Text("NETZWERKE · IPV4")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2).foregroundStyle(SubnetStyle.accent)
                Text("Subnetz-Sprint")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("Trainiere CIDR-Präfixe, Subnetzmasken und nutzbare Host-Adressen.")
                    .foregroundStyle(SubnetStyle.muted)
            }

            HStack(spacing: 12) {
                stat("SUBNETZ-XP", "\(store.progress.totalXP)")
                stat("RUNDEN", "\(store.progress.completedRounds)")
                stat("BESTLEISTUNG", "\(store.progress.bestScore)")
            }
            Button("Subnetz-Fortschritt zurücksetzen") { showingResetConfirmation = true }
                .font(.system(size: 11)).foregroundStyle(SubnetStyle.muted)
                .buttonStyle(.plain)

            if let error = store.saveError {
                VStack(alignment: .leading, spacing: 10) {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(SubnetStyle.red)
                    Text("Der vorhandene Spielstand bleibt erhalten. Eine beschädigte Datei " +
                         "wird beim Zurücksetzen zuerst gesichert.")
                        .foregroundStyle(SubnetStyle.muted)
                }
                .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(SubnetStyle.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
            }

            if let session = store.session {
                if session.isComplete { completion(session) }
                else if let question = store.currentQuestion { questionCard(session, question) }
            } else {
                intro
            }

            Text("Bei /16 bis /30 gilt: nutzbare Hosts = 2^(32 − Präfix) − 2; " +
                 "Netz- und Broadcast-Adresse sind abgezogen.")
                .font(.system(size: 12)).foregroundStyle(SubnetStyle.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 650, maxWidth: 850, alignment: .leading)
        .foregroundStyle(SubnetStyle.primary)
        .confirmationDialog("Subnetz-Fortschritt zurücksetzen?",
                            isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Fortschritt löschen", role: .destructive) { store.resetProgress() }
        } message: {
            Text("Deine Subnetz-XP, Bestleistung und gespeicherten Runden werden gelöscht. " +
                 "Ein beschädigter Spielstand wird zuvor gesichert.")
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("10 Fragen · Masken und Hostzahlen")
                .font(.system(size: 22, weight: .bold))
            Text("+25 XP für richtig, dazu bis zu +15 Tempo-XP; +5 XP für falsch " +
                 "und +50 XP für eine abgeschlossene Runde. Die Zeit läuft auch weiter, wenn du die App schließt.")
                .foregroundStyle(SubnetStyle.muted)
            Text("Schwächere Themen kommen häufiger dran; alle Präfixe bleiben im Mix.")
                .foregroundStyle(SubnetStyle.muted)
            if !store.learningFocus.isEmpty {
                Text("Dein Fokus: \(store.learningFocus.joined(separator: ", "))")
                    .foregroundStyle(SubnetStyle.accent)
            }
            Text("Beispiel: /24 bedeutet 24 Netzbits und 8 Hostbits. Die Maske ist 255.255.255.0.")
                .foregroundStyle(SubnetStyle.muted)
            Button("Runde starten ↵") { store.startRound() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(SubnetPrimaryButtonStyle())
        }
        .padding(28).frame(maxWidth: .infinity, alignment: .leading)
        .background(SubnetStyle.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func questionCard(_ session: SubnetSession, _ question: SubnetQuestion) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("FRAGE \(session.index + 1) / \(session.questions.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(SubnetStyle.accent)
                Spacer()
                Text("\(session.score) PUNKTE").foregroundStyle(SubnetStyle.muted)
            }
            ProgressView(value: Double(session.index), total: Double(session.questions.count))
                .tint(SubnetStyle.accent)
            if let timing = session.timing {
                QuestionTimerView(timing: timing, answered: session.selectedAnswer != nil)
                    .foregroundStyle(SubnetStyle.accent)
            }
            Text(question.prompt).font(.system(size: 24, weight: .bold))
            Text("Antwort mit 1–4 wählen")
                .font(.system(size: 11)).foregroundStyle(SubnetStyle.muted)
            VStack(spacing: 9) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                    Button { store.answer(choice) } label: {
                        HStack {
                            Text("\(index + 1)").font(.system(.body, design: .monospaced))
                                .foregroundStyle(SubnetStyle.muted).frame(width: 24)
                            Text(choice).font(.system(size: 17, weight: .semibold, design: .monospaced))
                            Spacer()
                            if session.selectedAnswer != nil && choice == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding(15)
                        .foregroundStyle(choiceColor(choice, session: session, question: question))
                        .background(SubnetStyle.raised, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: [])
                    .disabled(session.selectedAnswer != nil)
                }
            }
            if let selected = session.selectedAnswer {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selected == question.correctAnswer
                         ? "Richtig! +\(25 + (session.timing?.earnedBonus ?? 0)) XP"
                         : "Leider falsch. +5 XP")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(selected == question.correctAnswer ? SubnetStyle.accent : SubnetStyle.red)
                    Text(question.explanation).foregroundStyle(SubnetStyle.muted)
                    Button(session.index == session.questions.count - 1
                           ? "Ergebnis anzeigen ↵" : "Nächste Frage ↵") { store.nextQuestion() }
                        .keyboardShortcut(.return, modifiers: [])
                        .buttonStyle(SubnetPrimaryButtonStyle())
                }
            }
        }
        .padding(28).frame(maxWidth: .infinity, alignment: .leading)
        .background(SubnetStyle.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func completion(_ session: SubnetSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Runde abgeschlossen")
                .font(.system(size: 25, weight: .bold))
            Text("\(session.correctCount) von \(session.questions.count) richtig · " +
                 "\(session.score) Punkte · +50 Abschluss-XP")
                .foregroundStyle(SubnetStyle.muted)
            Text("+\(session.speedBonusTotal ?? 0) Tempo-XP in dieser Runde")
                .foregroundStyle(SubnetStyle.accent)
            Button("Neue Runde starten ↵") { store.startRound() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(SubnetPrimaryButtonStyle())
        }
        .padding(28).frame(maxWidth: .infinity, alignment: .leading)
        .background(SubnetStyle.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1).foregroundStyle(SubnetStyle.muted)
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17).background(SubnetStyle.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private func choiceColor(_ choice: String, session: SubnetSession,
                             question: SubnetQuestion) -> Color {
        guard let selected = session.selectedAnswer else { return SubnetStyle.primary }
        if choice == question.correctAnswer { return SubnetStyle.accent }
        if choice == selected { return SubnetStyle.red }
        return SubnetStyle.muted
    }
}

private struct SubnetPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(red: 0.035, green: 0.063, blue: 0.095))
            .padding(.horizontal, 19).padding(.vertical, 11)
            .background(SubnetStyle.accent.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: 9))
    }
}
