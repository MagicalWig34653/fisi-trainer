// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

private enum ExamStyle {
    static let surface = Color(red: 0.078, green: 0.113, blue: 0.151)
    static let raised = Color(red: 0.103, green: 0.145, blue: 0.183)
    static let border = Color.white.opacity(0.085)
    static let primary = Color(red: 0.94, green: 0.97, blue: 0.96)
    static let muted = Color(red: 0.53, green: 0.61, blue: 0.64)
    static let accent = Color(red: 0.76, green: 0.97, blue: 0.32)
    static let red = Color(red: 1.0, green: 0.45, blue: 0.43)
    static let background = Color(red: 0.035, green: 0.063, blue: 0.095)
}

/// The "Prüfungswissen" arena: a hub of nine practice modes over the WiSo/IT exam catalog,
/// plus a mixed-topic exam simulation. See `ExamStore` for persistence and grading rules.
struct ExamArenaView: View {
    @EnvironmentObject private var store: ExamStore
    @Binding var openMode: ExamMode?

    @State private var subject: ExamSubject = .wiso
    @State private var topic: ExamTopic?
    @State private var showingResetConfirmation = false
    @State private var showingAbandonConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let mode = openMode {
                gameView(mode: mode)
            } else {
                hub
            }
        }
        .foregroundStyle(ExamStyle.primary)
        .confirmationDialog("Prüfungswissen-Fortschritt zurücksetzen?",
                            isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Fortschritt löschen", role: .destructive) {
                store.resetProgress()
                openMode = nil
            }
        } message: {
            Text("Deine Prüfungs-XP, dein Lernfortschritt und laufende Runden werden gelöscht. " +
                 "Ein beschädigter Spielstand wird zuvor gesichert.")
        }
    }

    // MARK: - Hub

    private var hub: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 9) {
                Text("PRÜFUNGSWISSEN · WISO & IT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(ExamStyle.accent)
                Text("Prüfungswissen")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("Trainiere Wirtschafts- und Sozialkunde sowie IT-Fachwissen in neun Spielarten – " +
                     "von der gebundenen Aufgabe bis zur Prüfungssimulation.")
                    .foregroundStyle(ExamStyle.muted)
            }

            if let error = store.saveError {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(ExamStyle.red)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(error).font(.system(size: 12, weight: .semibold))
                        Text("Falls das Training blockiert ist, kannst du den Fortschritt zurücksetzen.")
                            .font(.system(size: 11)).foregroundStyle(ExamStyle.muted)
                    }
                    Spacer(minLength: 12)
                    Button("Zurücksetzen") { showingResetConfirmation = true }
                        .buttonStyle(ExamSecondaryButtonStyle())
                }
                .padding(16)
                .background(ExamStyle.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
            }

            Picker("Fach", selection: $subject) {
                ForEach(ExamSubject.allCases) { subject in
                    Text(subject.title).tag(subject)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 440)
            .labelsHidden()
            .onChange(of: subject) { _, _ in topic = nil }
            .accessibilityLabel("Fach wählen")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    topicChip(nil)
                    ForEach(ExamTopic.topics(for: subject)) { topicChip($0) }
                }
                .padding(.vertical, 2)
            }

            HStack(spacing: 12) {
                statCard("PRÜFUNGS-XP", value: "\(store.progress.totalXP)", symbol: "bolt.fill", accent: true)
                statCard("RUNDEN", value: "\(store.progress.completedRounds)", symbol: "checkmark.circle")
                statCard("TREFFERQUOTE", value: accuracy, symbol: "scope")
                statCard("LETZTE NOTE", value: lastGrade, symbol: "rosette")
            }

            let focus = store.learningFocus(subject: subject)
            if !focus.isEmpty {
                Label("Dein aktueller Übungsfokus: " + focus.joined(separator: " · "), systemImage: "brain")
                    .font(.system(size: 12))
                    .foregroundStyle(ExamStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            let counts = availableCounts
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                ForEach(ExamMode.allCases) { mode in
                    modeCard(mode, count: counts[mode, default: 0])
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Die Prüfungssimulation mischt immer alle Themen deines Fachs, unabhängig von der Themenwahl oben.")
                Text("Eigene Übungsaufgaben zu den Themen der IHK-Prüfungen – keine Originalaufgaben.")
            }
            .font(.system(size: 11))
            .foregroundStyle(ExamStyle.muted)
            .fixedSize(horizontal: false, vertical: true)

            Button("Prüfungswissen-Fortschritt zurücksetzen") { showingResetConfirmation = true }
                .font(.system(size: 11)).foregroundStyle(ExamStyle.muted)
                .buttonStyle(.plain)
        }
    }

    private func topicChip(_ chipTopic: ExamTopic?) -> some View {
        let selected = topic == chipTopic
        let accuracyValue = chipTopic.flatMap { store.topicAccuracy($0) }
        return Button {
            topic = chipTopic
        } label: {
            HStack(spacing: 6) {
                if let chipTopic { Image(systemName: chipTopic.symbol) }
                Text(chipTopic?.title ?? "Alle Themen")
                if let accuracyValue {
                    Text("\(Int((accuracyValue * 100).rounded())) %")
                        .foregroundStyle(selected ? ExamStyle.accent : ExamStyle.muted)
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(selected ? ExamStyle.accent.opacity(0.16) : ExamStyle.raised, in: Capsule())
            .foregroundStyle(selected ? ExamStyle.accent : ExamStyle.primary)
            .overlay(Capsule().strokeBorder(selected ? ExamStyle.accent.opacity(0.45) : ExamStyle.border))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(chipTopic?.title ?? "Alle Themen")
    }

    /// Available task counts for every mode at the current subject/topic, computed once per
    /// hub render instead of once per mode card.
    private var availableCounts: [ExamMode: Int] {
        Dictionary(uniqueKeysWithValues: ExamMode.allCases.map { mode in
            (mode, ExamTaskFactory.availableCount(for: mode, subject: subject, topic: mode == .exam ? nil : topic))
        })
    }

    private func modeCard(_ mode: ExamMode, count: Int) -> some View {
        let running = store.hasActiveSession(mode)
        return Button {
            openMode = mode
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: mode.symbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(ExamStyle.accent)
                    Spacer()
                    if running {
                        Text("LÄUFT")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(0.8)
                            .foregroundStyle(ExamStyle.accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(ExamStyle.accent.opacity(0.15), in: Capsule())
                    }
                }
                Text(mode.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(mode.summary)
                    .font(.system(size: 11))
                    .foregroundStyle(ExamStyle.muted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Text(count == 0 ? "Keine Aufgaben verfügbar" : "\(count) Aufgaben verfügbar")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(count == 0 ? ExamStyle.red : ExamStyle.muted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
            .background(ExamStyle.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(ExamStyle.border))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .opacity(count == 0 ? 0.5 : 1)
        .accessibilityLabel("\(mode.title). \(mode.summary) \(count) Aufgaben verfügbar." + (running ? " Eine Runde läuft bereits." : ""))
    }

    private var accuracy: String {
        let answered = store.progress.answeredQuestions
        guard answered > 0 else { return "—" }
        return "\(Int((Double(store.progress.correctAnswers) / Double(answered) * 100).rounded())) %"
    }

    private var lastGrade: String {
        guard let last = store.examHistory.first else { return "—" }
        return "\(last.grade.note)"
    }

    private func statCard(_ label: String, value: String, symbol: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent ? ExamStyle.accent : ExamStyle.muted)
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(ExamStyle.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 105)
        .background(ExamStyle.surface, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(ExamStyle.border))
    }

    // MARK: - Game

    private func gameView(mode: ExamMode) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Button {
                    openMode = nil
                } label: {
                    Label("Zum Hub", systemImage: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(ExamStyle.muted)

                Spacer()

                if let session = store.session(for: mode), !session.isComplete {
                    Button("Runde abbrechen") { showingAbandonConfirmation = true }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ExamStyle.red)
                        .accessibilityLabel("Laufende Runde abbrechen")
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("TRAININGSMODUS / \(mode.title.uppercased())")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(ExamStyle.accent)
                Text(mode.title)
                    .font(.system(size: 33, weight: .bold, design: .rounded))
                    .tracking(-1)
            }

            if let session = store.session(for: mode) {
                if session.isComplete {
                    mode == .exam ? AnyView(examCompletion(session)) : AnyView(completion(session, mode: mode))
                } else if let task = session.currentTask {
                    // `currentTask` is nil only when `isComplete` is true, which is handled above.
                    taskArea(session: session, task: task, mode: mode)
                }
            } else {
                intro(mode: mode)
            }
        }
        .confirmationDialog("Runde abbrechen?", isPresented: $showingAbandonConfirmation, titleVisibility: .visible) {
            Button("Runde abbrechen", role: .destructive) { store.abandon(mode: mode) }
        } message: {
            Text("Die laufende Runde wird verworfen. Bereits verdiente XP bleiben erhalten.")
        }
    }

    private func intro(mode: ExamMode) -> some View {
        let topicText = mode == .exam
            ? "aus allen Themen von \(subject.title)"
            : topic.map { "zum Thema \($0.title)" } ?? "aus allen Themen von \(subject.title)"
        return VStack(alignment: .leading, spacing: 15) {
            Text(mode.summary)
                .font(.system(size: 22, weight: .bold))
            Text("\(mode.roundLength) Aufgaben \(topicText).")
                .foregroundStyle(ExamStyle.muted)
            if mode == .exam {
                Text("Die Prüfungssimulation mischt immer alle Themen. Es gibt keine Auflösung während der Runde, " +
                     "nur ein Ergebnis am Ende.")
                    .foregroundStyle(ExamStyle.muted)
            }
            Text(mode == .exam
                 ? "+100 XP nach der letzten Aufgabe. Jede Aufgabe zählt zur IHK-Note."
                 : "+25 XP für richtig (plus Tempo-Bonus), +5 XP für falsch, +50 XP für die abgeschlossene Runde.")
                .foregroundStyle(ExamStyle.muted)
            Button("Runde starten ↵") {
                store.start(mode: mode, subject: subject, topic: mode == .exam ? nil : topic)
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(ExamPrimaryButtonStyle())
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ExamStyle.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func taskArea(session: ExamSession, task: ExamTask, mode: ExamMode) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("AUFGABE \(session.index + 1) / \(session.tasks.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(ExamStyle.accent)
                Spacer()
                if mode != .exam {
                    Text("\(session.score) PUNKTE").foregroundStyle(ExamStyle.muted)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
            }
            ProgressView(value: Double(session.index), total: Double(max(session.tasks.count, 1)))
                .tint(ExamStyle.accent)

            if let timing = session.timing {
                QuestionTimerView(timing: timing, answered: session.isCurrentAnswered)
                    .foregroundStyle(ExamStyle.accent)
            }
            if mode == .exam {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let elapsed = max(0, context.date.timeIntervalSince(session.startedAt))
                    let minutes = Int(elapsed) / 60
                    let seconds = Int(elapsed) % 60
                    Text(String(format: "Gesamtzeit %02d:%02d · Vorgabezeit 60 min", minutes, seconds))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(ExamStyle.muted)
                        .help("Kein Zeitlimit: Die 60 Minuten sind nur die IHK-Vorgabezeit zur Orientierung.")
                }
            }

            Text(task.topic.title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(ExamStyle.muted)
            Text(task.prompt)
                .font(.system(size: 22, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)

            Group {
                switch task.kind {
                case .single:
                    SingleTaskView(session: session, task: task, mode: mode)
                case .multiple:
                    MultipleTaskView(session: session, task: task, mode: mode)
                case .match:
                    MatchTaskView(session: session, task: task, mode: mode)
                case .order:
                    OrderTaskView(session: session, task: task, mode: mode)
                }
            }
            .id(session.index)

            if session.showsResolution, let answer = session.currentAnswer {
                resolution(session: session, task: task, mode: mode, answer: answer)
            }
        }
        .padding(30)
        .background(ExamStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(ExamStyle.border))
    }

    private func resolution(session: ExamSession, task: ExamTask, mode: ExamMode, answer: [Int]) -> some View {
        let correct = task.isCorrect(answer)
        let bonus = session.timing?.earnedBonus ?? 0
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: correct ? "checkmark.seal.fill" : "info.circle.fill")
                    .font(.system(size: 19))
                    .foregroundStyle(correct ? ExamStyle.accent : ExamStyle.red)
                VStack(alignment: .leading, spacing: 6) {
                    Text(correct ? "Richtig! +\(25 + bonus) XP" : "Leider falsch. +5 XP")
                        .font(.system(size: 15, weight: .bold))
                    if task.kind == .match || task.kind == .order {
                        Text("Lösung:\n\(task.solutionText)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(ExamStyle.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(task.explanation)
                        .font(.system(size: 13))
                        .foregroundStyle(ExamStyle.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ExamStyle.raised, in: RoundedRectangle(cornerRadius: 11))

            Button(session.index + 1 == session.tasks.count ? "Ergebnis anzeigen ↵" : "Nächste Aufgabe ↵") {
                store.next(mode: mode)
            }
            .buttonStyle(ExamPrimaryButtonStyle())
            .keyboardShortcut(.return, modifiers: [])
        }
    }

    private func completion(_ session: ExamSession, mode: ExamMode) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundStyle(ExamStyle.accent)
            Text("Runde abgeschlossen")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            HStack(spacing: 14) {
                resultValue("RICHTIG", "\(session.correctCount) / \(session.tasks.count)")
                resultValue("PUNKTE", "\(session.score)")
                resultValue("TEMPO-XP", "\(session.speedBonusTotal)")
            }
            HStack(spacing: 12) {
                Button("Neue Runde ↵") {
                    store.start(mode: mode, subject: subject, topic: topic)
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(ExamPrimaryButtonStyle())
                Button("Zur Übersicht") { openMode = nil }
                    .buttonStyle(ExamSecondaryButtonStyle())
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ExamStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(ExamStyle.border))
    }

    private func examCompletion(_ session: ExamSession) -> some View {
        let grade = ExamGrade.grade(forPercent: session.percent)
        let duration = (session.finishedAt ?? Date()).timeIntervalSince(session.startedAt)
        return VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(ExamStyle.accent)
            Text("Prüfungssimulation abgeschlossen")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            HStack(spacing: 14) {
                resultValue("ERGEBNIS", "\(Int(session.percent.rounded())) %")
                resultValue("NOTE", "\(grade.note) · \(grade.title)")
                resultValue("DAUER", formatDuration(duration))
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(session.tasks.enumerated()), id: \.offset) { index, task in
                    let answer = session.answers.indices.contains(index) ? session.answers[index] : []
                    let correct = task.isCorrect(answer)
                    VStack(alignment: .leading, spacing: 7) {
                        if index > 0 { ExamStyle.border.frame(height: 1) }
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(correct ? ExamStyle.accent : ExamStyle.red)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(index + 1). \(task.prompt)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                if !correct {
                                    Text("Deine Antwort: \(task.describe(answer))")
                                        .font(.system(size: 11))
                                        .foregroundStyle(ExamStyle.red)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("Lösung: \(task.solutionText)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(ExamStyle.accent)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(task.explanation)
                                        .font(.system(size: 11))
                                        .foregroundStyle(ExamStyle.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(ExamStyle.raised, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Button("Neue Runde ↵") {
                    store.start(mode: .exam, subject: subject, topic: nil)
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(ExamPrimaryButtonStyle())
                Button("Zur Übersicht") { openMode = nil }
                    .buttonStyle(ExamSecondaryButtonStyle())
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ExamStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(ExamStyle.border))
    }

    private func resultValue(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(ExamStyle.muted)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(ExamStyle.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ExamStyle.raised, in: RoundedRectangle(cornerRadius: 11))
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

// MARK: - Task interaction views

private struct SingleTaskView: View {
    let session: ExamSession
    let task: ExamTask
    let mode: ExamMode
    @EnvironmentObject private var store: ExamStore

    private var answered: Bool { session.showsResolution }
    private var isTrueFalse: Bool { task.options == [ExamTaskFactory.trueLabel, ExamTaskFactory.falseLabel] }

    var body: some View {
        if isTrueFalse {
            HStack(spacing: 14) {
                ForEach(Array(task.options.enumerated()), id: \.offset) { index, label in
                    optionButton(index: index, label: label, big: true)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(Array(task.options.enumerated()), id: \.offset) { index, label in
                    optionButton(index: index, label: label, big: false)
                }
            }
        }
    }

    private func optionButton(index: Int, label: String, big: Bool) -> some View {
        let selected = session.currentAnswer?.first == index
        let isSolution = task.solution.first == index
        let color: Color = answered
            ? (isSolution ? ExamStyle.accent : (selected ? ExamStyle.red : ExamStyle.muted))
            : ExamStyle.primary
        return Button {
            store.answer([index], mode: mode)
        } label: {
            HStack(spacing: 14) {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .frame(width: 26, height: 26)
                    .background(ExamStyle.background, in: RoundedRectangle(cornerRadius: 6))
                Text(label)
                    .font(.system(size: big ? 17 : 15, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if answered && isSolution {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(ExamStyle.accent)
                } else if answered && selected {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(ExamStyle.red)
                }
            }
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .frame(maxWidth: big ? .infinity : nil, minHeight: big ? 74 : 58, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(answered && isSolution ? ExamStyle.accent.opacity(0.13)
                        : answered && selected ? ExamStyle.red.opacity(0.12) : ExamStyle.raised,
                        in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(color.opacity(answered ? 0.5 : 0.14)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(answered)
        .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: [])
        .help("Taste \(index + 1)")
        .accessibilityLabel("Antwort \(index + 1): \(label)")
    }
}

private struct MultipleTaskView: View {
    let session: ExamSession
    let task: ExamTask
    let mode: ExamMode
    @EnvironmentObject private var store: ExamStore
    @State private var chosen: Set<Int> = []

    private var answered: Bool { session.showsResolution }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wähle alle zutreffenden Antworten (\(task.solution.count))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ExamStyle.muted)
            VStack(spacing: 9) {
                ForEach(Array(task.options.enumerated()), id: \.offset) { index, label in
                    optionRow(index: index, label: label)
                }
            }
            if !answered {
                Button("Prüfen ↵") { store.answer(chosen.sorted(), mode: mode) }
                    .buttonStyle(ExamPrimaryButtonStyle())
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(chosen.isEmpty)
            }
        }
    }

    private func optionRow(index: Int, label: String) -> some View {
        let selected = answered ? (session.currentAnswer?.contains(index) ?? false) : chosen.contains(index)
        let isSolution = task.solution.contains(index)
        let color: Color = answered
            ? (isSolution ? ExamStyle.accent : (selected ? ExamStyle.red : ExamStyle.muted))
            : (selected ? ExamStyle.accent : ExamStyle.primary)
        return Button {
            guard !answered else { return }
            if chosen.contains(index) { chosen.remove(index) } else { chosen.insert(index) }
        } label: {
            HStack(spacing: 14) {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .frame(width: 26, height: 26)
                    .background(ExamStyle.background, in: RoundedRectangle(cornerRadius: 6))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if answered && isSolution {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(ExamStyle.accent)
                } else if answered && selected {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(ExamStyle.red)
                } else if selected {
                    Image(systemName: "checkmark.square.fill").foregroundStyle(ExamStyle.accent)
                } else {
                    Image(systemName: "square").foregroundStyle(ExamStyle.muted)
                }
            }
            .foregroundStyle(color)
            .padding(.horizontal, 15)
            .frame(minHeight: 50, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ExamStyle.raised, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(0.3)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(answered)
        .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: [])
        .help("Taste \(index + 1): Auswahl umschalten")
        .accessibilityLabel("Option \(index + 1): \(label)" + (selected ? ", ausgewählt" : ""))
    }
}

private struct MatchTaskView: View {
    let session: ExamSession
    let task: ExamTask
    let mode: ExamMode
    @EnvironmentObject private var store: ExamStore
    @State private var selections: [Int?]

    init(session: ExamSession, task: ExamTask, mode: ExamMode) {
        self.session = session
        self.task = task
        self.mode = mode
        _selections = State(initialValue: Array(repeating: nil, count: task.items.count))
    }

    private var answered: Bool { session.showsResolution }
    private var isGap: Bool { task.prompt.contains("Setze die passenden Begriffe ein") }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(task.items.enumerated()), id: \.offset) { index, item in
                row(index: index, item: item)
            }
            if !answered {
                Button("Prüfen ↵") {
                    store.answer(selections.map { $0 ?? 0 }, mode: mode)
                }
                .buttonStyle(ExamPrimaryButtonStyle())
                .keyboardShortcut(.return, modifiers: [])
                .disabled(selections.contains(nil))
            }
        }
    }

    private func row(index: Int, item: String) -> some View {
        let chosenIndex = answered ? session.currentAnswer?[index] : selections[index]
        let isCorrect = answered && task.solution[index] == chosenIndex
        let label = chosenIndex.flatMap { task.options.indices.contains($0) ? task.options[$0] : nil }
        return HStack(alignment: .center, spacing: 12) {
            if isGap {
                gapText(item, chosenLabel: label)
            } else {
                Text(item)
                    .font(.system(size: 14, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Menu {
                ForEach(Array(task.options.enumerated()), id: \.offset) { optionIndex, optionLabel in
                    Button(optionLabel) { selections[index] = optionIndex }
                }
            } label: {
                Text(label ?? "Wählen …")
                    .font(.system(size: 13, weight: .semibold))
            }
            .disabled(answered)
            .frame(minWidth: 160)
            if answered {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? ExamStyle.accent : ExamStyle.red)
            }
        }
        .padding(13)
        .background(ExamStyle.raised, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    private func gapText(_ sentence: String, chosenLabel: String?) -> some View {
        let parts = sentence.components(separatedBy: "___")
        return (Text(parts.first ?? "")
            + Text(chosenLabel ?? "＿＿＿＿").foregroundColor(chosenLabel == nil ? ExamStyle.muted : ExamStyle.accent)
            + Text(parts.count > 1 ? parts[1] : ""))
            .font(.system(size: 14, weight: .medium))
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct OrderTaskView: View {
    let session: ExamSession
    let task: ExamTask
    let mode: ExamMode
    @EnvironmentObject private var store: ExamStore
    @State private var order: [Int] = []

    private var answered: Bool { session.showsResolution }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 9) {
                ForEach(Array(task.items.enumerated()), id: \.offset) { index, item in
                    itemButton(index: index, item: item)
                }
            }
            if !answered {
                HStack(spacing: 12) {
                    Button("Zurücksetzen") { order = [] }
                        .buttonStyle(ExamSecondaryButtonStyle())
                        .disabled(order.isEmpty)
                    Button("Prüfen ↵") { store.answer(order, mode: mode) }
                        .buttonStyle(ExamPrimaryButtonStyle())
                        .keyboardShortcut(.return, modifiers: [])
                        .disabled(order.count != task.items.count)
                }
            }
        }
    }

    private func itemButton(index: Int, item: String) -> some View {
        let position = answered ? session.currentAnswer?.firstIndex(of: index) : order.firstIndex(of: index)
        let correctPosition = task.solution.firstIndex(of: index)
        let isCorrect = answered && position == correctPosition
        let color: Color = answered
            ? (isCorrect ? ExamStyle.accent : ExamStyle.red)
            : (position != nil ? ExamStyle.accent : ExamStyle.primary)
        return Button {
            guard !answered else { return }
            if let existing = order.firstIndex(of: index) {
                order.remove(at: existing)
            } else {
                order.append(index)
            }
        } label: {
            HStack(spacing: 14) {
                Text(position != nil ? "\(position! + 1)" : "–")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .frame(width: 28, height: 28)
                    .background(ExamStyle.background, in: RoundedRectangle(cornerRadius: 7))
                Text(item)
                    .font(.system(size: 14, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if answered {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? ExamStyle.accent : ExamStyle.red)
                }
            }
            .foregroundStyle(color)
            .padding(.horizontal, 15)
            .frame(minHeight: 54, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ExamStyle.raised, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(0.3)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(answered)
        .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: [])
        .help("Taste \(index + 1): an die Reihenfolge anhängen oder entfernen")
        .accessibilityLabel("Schritt \(item)" + (position != nil ? ", Position \(position! + 1)" : ", nicht eingeordnet"))
    }
}

// MARK: - Button styles

private struct ExamPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(ExamStyle.background)
            .padding(.horizontal, 20)
            .frame(height: 42)
            .background(configuration.isPressed ? ExamStyle.accent.opacity(0.8) : ExamStyle.accent,
                        in: RoundedRectangle(cornerRadius: 9))
    }
}

private struct ExamSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(ExamStyle.primary)
            .padding(.horizontal, 19)
            .frame(height: 42)
            .background(configuration.isPressed ? ExamStyle.raised : ExamStyle.surface,
                        in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(ExamStyle.border))
    }
}
