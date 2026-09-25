// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

private enum LabStyle {
    static let background = Color(red: 0.035, green: 0.063, blue: 0.095)
    static let sidebar = Color(red: 0.054, green: 0.086, blue: 0.122)
    static let surface = Color(red: 0.078, green: 0.113, blue: 0.151)
    static let raised = Color(red: 0.103, green: 0.145, blue: 0.183)
    static let border = Color.white.opacity(0.085)
    static let primary = Color(red: 0.94, green: 0.97, blue: 0.96)
    static let muted = Color(red: 0.53, green: 0.61, blue: 0.64)
    static let accent = Color(red: 0.76, green: 0.97, blue: 0.32)
    static let red = Color(red: 1.0, green: 0.45, blue: 0.43)
}

private enum LabPage: String, CaseIterable {
    case dashboard = "Übersicht"
    case game = "Port-Quiz"
    case subnet = "Subnetz-Sprint"
    case exam = "Prüfungswissen"
    case rewards = "Level & Haustiere"
    case reference = "Port-Referenz"

    var symbol: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .game: "bolt.fill"
        case .subnet: "square.split.2x2"
        case .exam: "graduationcap.fill"
        case .rewards: "pawprint.fill"
        case .reference: "list.bullet.rectangle"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var rewards: RewardStore
    @EnvironmentObject private var subnetStore: SubnetStore
    @EnvironmentObject private var examStore: ExamStore
    @State private var page: LabPage = .dashboard
    @State private var showingResetConfirmation = false
    @State private var newLevel: Int?
    @State private var openExamMode: ExamMode?

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle()
                .fill(LabStyle.border)
                .frame(width: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topBar

                    if let level = newLevel {
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                            Text("Level \(level) erreicht! Entdecke deine Belohnungen.")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Button("Ansehen") { page = .rewards; newLevel = nil }
                                .buttonStyle(LabSecondaryButtonStyle())
                            Button { newLevel = nil } label: { Image(systemName: "xmark") }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Level-Hinweis schließen")
                        }
                        .foregroundStyle(LabStyle.accent)
                        .padding(16)
                        .background(LabStyle.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 48)
                        .padding(.top, 20)
                    }

                    if let error = store.saveError {
                        HStack(alignment: .top, spacing: 11) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(LabStyle.red)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(error)
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Falls das Training blockiert ist, kannst du den Fortschritt zurücksetzen.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(LabStyle.muted)
                            }
                            Spacer(minLength: 12)
                            Button("Zurücksetzen") { showingResetConfirmation = true }
                                .buttonStyle(LabSecondaryButtonStyle())
                        }
                        .padding(16)
                        .background(LabStyle.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(LabStyle.red.opacity(0.25)))
                        .padding(.horizontal, 48)
                        .padding(.top, 20)
                    }

                    Group {
                        switch page {
                        case .dashboard: dashboard
                        case .game: game
                        case .subnet: SubnetTrainerView()
                        case .exam: ExamArenaView(openMode: $openExamMode)
                        case .rewards: RewardsView()
                        case .reference: reference
                        }
                    }
                    .frame(maxWidth: 1050, alignment: .leading)
                    .padding(.horizontal, 48)
                    .padding(.top, 40)
                    .padding(.bottom, 64)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if page == .game || page == .subnet || page == .exam {
                    if let pet = rewards.selectedPet {
                        PetCompanionView(pet: pet, context: petContext)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(LabStyle.sidebar)
                    } else {
                        HStack {
                            Label("Ab Level 2 begleitet dich deine Katze beim Lernen.", systemImage: "pawprint")
                            Spacer()
                            Button("Level-Roadmap") { page = .rewards }
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(LabStyle.muted)
                        .padding(16)
                        .background(LabStyle.sidebar)
                    }
                }
            }
            .background(LabStyle.background)
        }
        .background(LabStyle.background)
        .foregroundStyle(LabStyle.primary)
        .frame(minWidth: 1000, minHeight: 700)
        .preferredColorScheme(.dark)
        .onChange(of: rewards.level) { previous, current in
            if current > previous { newLevel = current }
        }
        .confirmationDialog(
            "Port-Quiz-Fortschritt zurücksetzen?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Fortschritt löschen", role: .destructive) {
                store.resetProgress()
                page = .dashboard
            }
        } message: {
            Text("Deine Port-Quiz-XP, Bestleistung und laufende Runde werden gelöscht. Der Subnetz-Sprint bleibt erhalten.")
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "network")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(LabStyle.accent)
                    .frame(width: 35, height: 35)
                VStack(alignment: .leading, spacing: 1) {
                    Text("FiSi LAB")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(1.3)
                    Text("FiSi Trainer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LabStyle.muted)
                }
            }
            .padding(.horizontal, 23)
            .padding(.top, 30)

            Text("LERNBEREICH")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(LabStyle.muted)
                .padding(.horizontal, 25)
                .padding(.top, 54)
                .padding(.bottom, 15)

            ForEach(LabPage.allCases, id: \.self) { item in
                Button {
                    page = item
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 20)
                        Text(item.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                        Spacer(minLength: 0)
                        if item == .game, let session = store.session, !session.isComplete {
                            Circle()
                                .fill(LabStyle.accent)
                                .frame(width: 6, height: 6)
                        }
                        if item == .exam, ExamMode.allCases.contains(where: { examStore.hasActiveSession($0) }) {
                            Circle()
                                .fill(LabStyle.accent)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundStyle(page == item ? LabStyle.accent : LabStyle.muted)
                    .padding(.horizontal, 14)
                    .frame(height: 43)
                    .background(page == item ? LabStyle.accent.opacity(0.11) : .clear,
                                in: RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 11)
                .padding(.bottom, 4)
            }

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Image(systemName: "sparkle")
                        .foregroundStyle(LabStyle.accent)
                    Text("LEVEL \(rewards.level)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1)
                }
                Text(rewards.rankTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LabStyle.accent)
                Text("\(rewards.totalXP % 250) / 250 XP bis Level \(rewards.level + 1)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LabStyle.muted)
                ProgressView(value: Double(rewards.totalXP % 250), total: 250)
                    .tint(LabStyle.accent)
                    .accessibilityLabel("Fortschritt zum nächsten Level")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(LabStyle.raised, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 18)

            Button {
                showingResetConfirmation = true
            } label: {
                Label("Port-Fortschritt zurücksetzen", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LabStyle.muted)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 25)
        }
        .frame(width: 230)
        .frame(maxHeight: .infinity)
        .background(LabStyle.sidebar)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Circle().fill(LabStyle.accent).frame(width: 7, height: 7)
                Text("DEIN LERNLABOR")
                    .tracking(1.4)
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(LabStyle.muted)

            Spacer()

            Image(systemName: "terminal")
                .foregroundStyle(LabStyle.accent)
            Text(page == .exam ? "FiSi / PRÜFUNGSWISSEN" : "FiSi / NETZWERKE")
                .foregroundStyle(LabStyle.muted)
        }
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .padding(.horizontal, 48)
        .frame(height: 61)
        .overlay(alignment: .bottom) { LabStyle.border.frame(height: 1) }
    }

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .top, spacing: 30) {
                VStack(alignment: .leading, spacing: 14) {
                    eyebrow("DEIN TRAININGSCENTER")
                    Text("Netzwerke verstehen.\nWissen festigen.")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .tracking(-1.8)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Dein Lernlabor für die FiSi-Prüfung: Ports, Protokolle und Subnetze – eine Runde nach der anderen.")
                        .font(.system(size: 15))
                        .foregroundStyle(LabStyle.muted)
                        .lineSpacing(5)
                        .frame(maxWidth: 530, alignment: .leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 106, weight: .ultraLight))
                    .foregroundStyle(LabStyle.accent.opacity(0.45))
                    .frame(width: 150, height: 150)
                    .accessibilityHidden(true)
            }

            Button {
                page = .rewards
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Level \(rewards.level) · \(rewards.rankTitle)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Deine Level-Roadmap, Belohnungen und 3D-Begleiter")
                            .font(.system(size: 13))
                            .foregroundStyle(LabStyle.muted)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(LabStyle.accent)
                .padding(24)
                .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 16))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            eyebrow("DEIN PORT-QUIZ-FORTSCHRITT")

            HStack(spacing: 12) {
                statCard("GESAMMELTE XP", value: "\(store.progress.totalXP)", symbol: "bolt.fill", accent: true)
                statCard("RUNDEN", value: "\(store.progress.completedRounds)", symbol: "checkmark.circle")
                statCard("BESTLEISTUNG", value: "\(store.progress.bestScore)", symbol: "trophy")
                statCard("TREFFERQUOTE", value: accuracy, symbol: "scope")
            }

            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 17) {
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.system(size: 31))
                        .foregroundStyle(LabStyle.accent)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(activeRound ? "Deine Runde wartet" : "Bereit für die nächste Runde?")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(activeRound
                             ? "Setze genau dort fort, wo du aufgehört hast."
                             : "Trainiere Ports, Dienste und TCP/UDP im Wechsel und sammle XP.")
                            .font(.system(size: 13))
                            .foregroundStyle(LabStyle.muted)
                    }
                    Spacer()
                }

                HStack(spacing: 13) {
                    Button {
                        if !activeRound { store.startRound() }
                        page = .game
                    } label: {
                        Label(activeRound ? "Runde fortsetzen ↵" : "Training starten ↵", systemImage: "arrow.right")
                    }
                    .buttonStyle(LabPrimaryButtonStyle())
                    .keyboardShortcut(.return, modifiers: [])

                    Button {
                        page = .reference
                    } label: {
                        Label("Ports nachschlagen", systemImage: "book.closed")
                    }
                    .buttonStyle(LabSecondaryButtonStyle())
                }
            }
            .padding(27)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(LabStyle.border))

            Button {
                page = .subnet
            } label: {
                HStack(spacing: 18) {
                    Image(systemName: "square.split.2x2")
                        .font(.system(size: 28))
                        .foregroundStyle(LabStyle.accent)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subnetz-Sprint")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Trainiere IPv4-Präfixe, Subnetzmasken und nutzbare Hostadressen.")
                            .font(.system(size: 13))
                            .foregroundStyle(LabStyle.muted)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(27)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(LabStyle.border))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                page = .exam
            } label: {
                HStack(spacing: 18) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(LabStyle.accent)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prüfungswissen: WiSo & IT")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Neun Spielarten zu Wirtschafts- und Sozialkunde sowie IT-Fachwissen, plus Prüfungssimulation.")
                            .font(.system(size: 13))
                            .foregroundStyle(LabStyle.muted)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(27)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(LabStyle.border))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

        }
    }

    private var game: some View {
        VStack(alignment: .leading, spacing: 27) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Training, das mitlernt", systemImage: "brain")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LabStyle.accent)
                Text(store.learningFocus.isEmpty
                     ? "Mit jeder Antwort lernt der Trainer deine Stärken kennen. Unsichere Themen kommen in neuen Runden häufiger vor."
                     : "Dein aktueller Übungsfokus: " + store.learningFocus.joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(LabStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 10) {
                    eyebrow("TRAININGSMODUS / PORT-QUIZ")
                    Text("Ports, Dienste & Protokolle")
                        .font(.system(size: 37, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                }
                Spacer()
                if let session = store.session, !session.isComplete {
                    Label("\(session.score) PUNKTE", systemImage: "bolt.fill")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(LabStyle.accent)
                }
            }

            if let session = store.session {
                if session.isComplete {
                    completion(session)
                } else if let question = store.currentQuestion {
                    questionCard(question, session: session)
                } else {
                    emptyGame
                }
            } else {
                emptyGame
            }
        }
    }

    private var emptyGame: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "network")
                .font(.system(size: 43))
                .foregroundStyle(LabStyle.accent)
            Text("Starte dein Port-Training")
                .font(.system(size: 23, weight: .bold, design: .rounded))
            Text("Zehn Fragen zu Ports, Diensten und Transportprotokollen. Antworte mit 1–4, weiter geht es mit Return.")
                .foregroundStyle(LabStyle.muted)
            Button("Runde starten ↵") { store.startRound() }
                .buttonStyle(LabPrimaryButtonStyle())
                .keyboardShortcut(.return, modifiers: [])
        }
        .frame(maxWidth: .infinity, minHeight: 330, alignment: .leading)
        .padding(32)
        .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func questionCard(_ question: Question, session: GameSession) -> some View {
        let answered = session.selectedAnswer != nil
        return VStack(alignment: .leading, spacing: 25) {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    eyebrow("FRAGE \(String(format: "%02d", session.index + 1)) / \(String(format: "%02d", session.questions.count))")
                    Spacer()
                    if session.streak > 1 {
                        Label("\(session.streak) SERIE", systemImage: "flame.fill")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(LabStyle.accent)
                    }
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(LabStyle.raised)
                        Capsule().fill(LabStyle.accent)
                            .frame(width: proxy.size.width * CGFloat(session.index + 1) / CGFloat(max(session.questions.count, 1)))
                    }
                }
                .frame(height: 5)
            }

            if let timing = session.timing {
                QuestionTimerView(timing: timing, answered: answered)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text(question.kind == .service ? "STANDARDPORT" : "NETZWERKDIENST")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.7)
                    .foregroundStyle(LabStyle.muted)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(question.title)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .tracking(-1)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(question.context)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(LabStyle.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(LabStyle.accent.opacity(0.12), in: Capsule())
                        .fixedSize()
                }
                Text(question.prompt)
                    .font(.system(size: 14))
                    .foregroundStyle(LabStyle.muted)
            }
            .padding(.vertical, 10)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                ForEach(0..<((question.choices.count + 1) / 2), id: \.self) { row in
                    GridRow {
                        ForEach(Array(question.choices.enumerated()).filter { $0.offset / 2 == row }, id: \.offset) { index, port in
                            Button {
                                store.answer(port)
                            } label: {
                                HStack(spacing: 15) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(answerColor(port, question: question, selected: session.selectedAnswer))
                                        .frame(width: 28, height: 28)
                                        .background(LabStyle.background, in: RoundedRectangle(cornerRadius: 7))
                                    Text(question.answerLabel(port))
                                        .font(.system(size: question.kind == .port ? 20 : 15, weight: .semibold, design: .rounded))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                    if answered && port == question.correctAnswer {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(LabStyle.accent)
                                    } else if answered && port == session.selectedAnswer {
                                        Image(systemName: "xmark.circle.fill").foregroundStyle(LabStyle.red)
                                    }
                                }
                                .foregroundStyle(LabStyle.primary)
                                .padding(.horizontal, 16)
                                .frame(height: 72)
                                .background(answerBackground(port, question: question, selected: session.selectedAnswer),
                                            in: RoundedRectangle(cornerRadius: 11))
                                .overlay(RoundedRectangle(cornerRadius: 11)
                                    .strokeBorder(answerColor(port, question: question, selected: session.selectedAnswer).opacity(answered ? 0.55 : 0.14)))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(answered)
                            .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: [])
                            .help("Taste \(index + 1)")
                            .accessibilityLabel("Antwort \(index + 1): \(question.answerLabel(port))")
                        }
                    }
                }
            }

            if answered {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: session.selectedAnswer == question.correctAnswer ? "checkmark.seal.fill" : "info.circle.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(session.selectedAnswer == question.correctAnswer ? LabStyle.accent : LabStyle.red)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.selectedAnswer == question.correctAnswer ? "Richtig verbunden!" : "Richtig ist: \(question.answerLabel(question.correctAnswer)).")
                            .font(.system(size: 15, weight: .bold))
                        Text("+\(session.selectedAnswer == question.correctAnswer ? 25 + (session.timing?.earnedBonus ?? 0) : 5) XP")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LabStyle.accent)
                        Text("\(question.service.name) · Port \(question.service.port) · \(question.service.transport)\n\(question.service.hint)")
                            .font(.system(size: 13))
                            .foregroundStyle(LabStyle.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(17)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LabStyle.raised, in: RoundedRectangle(cornerRadius: 11))

                Button(session.index + 1 == session.questions.count ? "Ergebnis ansehen ↵" : "Nächste Frage ↵") {
                    store.nextQuestion()
                }
                .buttonStyle(LabPrimaryButtonStyle())
                .keyboardShortcut(.return, modifiers: [])
            } else {
                Text("Tasten 1–\(question.choices.count): Antwort wählen · Return: nach der Auflösung weiter")
                    .font(.system(size: 12))
                    .foregroundStyle(LabStyle.muted)
            }
        }
        .padding(30)
        .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(LabStyle.border))
    }

    private func completion(_ session: GameSession) -> some View {
        VStack(alignment: .leading, spacing: 23) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 43))
                .foregroundStyle(LabStyle.accent)
            eyebrow("RUNDE ABGESCHLOSSEN")
            Text("Stark trainiert!")
                .font(.system(size: 37, weight: .bold, design: .rounded))
            Text("Jede Runde bringt dich näher an sichere Port-Kenntnisse.")
                .font(.system(size: 14))
                .foregroundStyle(LabStyle.muted)

            HStack(spacing: 14) {
                resultValue("PUNKTE", "\(session.score)")
                resultValue("RICHTIG", "\(session.correctCount) / \(session.questions.count)")
                resultValue("GESAMT-XP", "\(store.progress.totalXP)")
            }
            .padding(.vertical, 11)

            Text("Davon \(session.speedBonusTotal ?? 0) zusätzliche Tempo-XP in dieser Runde.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LabStyle.accent)

            HStack(spacing: 12) {
                Button("Neue Runde starten ↵") { store.startRound() }
                    .buttonStyle(LabPrimaryButtonStyle())
                    .keyboardShortcut(.return, modifiers: [])
                Button("Zur Übersicht") { page = .dashboard }
                    .buttonStyle(LabSecondaryButtonStyle())
            }
        }
        .padding(34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(LabStyle.border))
    }

    private var reference: some View {
        VStack(alignment: .leading, spacing: 24) {
            eyebrow("SPICKZETTEL / NETZWERKE")
            Text("Port-Referenz")
                .font(.system(size: 37, weight: .bold, design: .rounded))
                .tracking(-1.2)
            Text("\(PortService.catalog.count) Dienste mit Standardports und gebräuchlichen Transportprotokollen. TCP / UDP bedeutet: Beide werden genutzt, je nach Variante des Dienstes.")
                .font(.system(size: 14))
                .foregroundStyle(LabStyle.muted)

            VStack(spacing: 0) {
                HStack {
                    Text("DIENST").frame(maxWidth: .infinity, alignment: .leading)
                    Text("PROTOKOLL").frame(width: 120, alignment: .leading)
                    Text("PORT").frame(width: 90, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(LabStyle.muted)
                .padding(.horizontal, 22)
                .frame(height: 43)

                ForEach(PortService.catalog) { service in
                    VStack(spacing: 0) {
                        LabStyle.border.frame(height: 1)
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(service.name)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(service.hint)
                                    .font(.system(size: 11))
                                    .foregroundStyle(LabStyle.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(service.transport)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(LabStyle.muted)
                                .frame(width: 120, alignment: .leading)
                            Text("\(service.port)")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(LabStyle.accent)
                                .frame(width: 90, alignment: .trailing)
                        }
                        .padding(.horizontal, 22)
                        .frame(minHeight: 63)
                    }
                }
            }
            .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(LabStyle.border))
        }
    }

    private var petContext: PetLearningContext {
        switch page {
        case .game: .port(store.session)
        case .subnet: .subnet(subnetStore.session)
        case .exam:
            .exam(openExamMode.flatMap { examStore.session(for: $0) }, mode: openExamMode ?? .quiz)
        default: .port(store.session)
        }
    }

    private var activeRound: Bool {
        guard let session = store.session else { return false }
        return !session.isComplete
    }

    private var accuracy: String {
        let answered = store.progress.answeredQuestions
        guard answered > 0 else { return "—" }
        return "\(Int((Double(store.progress.correctAnswers) / Double(answered) * 100).rounded())) %"
    }

    private func eyebrow(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(1.7)
            .foregroundStyle(LabStyle.accent)
    }

    private func statCard(_ label: String, value: String, symbol: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent ? LabStyle.accent : LabStyle.muted)
            VStack(alignment: .leading, spacing: 5) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(0.7)
                    .foregroundStyle(LabStyle.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(19)
        .frame(height: 127)
        .background(LabStyle.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(LabStyle.border))
    }

    private func resultValue(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(LabStyle.muted)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(LabStyle.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LabStyle.raised, in: RoundedRectangle(cornerRadius: 11))
    }

    private func answerColor(_ port: Int, question: Question, selected: Int?) -> Color {
        guard let selected else { return LabStyle.muted }
        if port == question.correctAnswer { return LabStyle.accent }
        if port == selected { return LabStyle.red }
        return LabStyle.muted
    }

    private func answerBackground(_ port: Int, question: Question, selected: Int?) -> Color {
        guard let selected else { return LabStyle.raised }
        if port == question.correctAnswer { return LabStyle.accent.opacity(0.13) }
        if port == selected { return LabStyle.red.opacity(0.12) }
        return LabStyle.raised.opacity(0.55)
    }
}

private struct LabPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(LabStyle.background)
            .padding(.horizontal, 20)
            .frame(height: 42)
            .background(configuration.isPressed ? LabStyle.accent.opacity(0.8) : LabStyle.accent,
                        in: RoundedRectangle(cornerRadius: 9))
    }
}

private struct LabSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(LabStyle.primary)
            .padding(.horizontal, 19)
            .frame(height: 42)
            .background(configuration.isPressed ? LabStyle.raised : LabStyle.surface,
                        in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(LabStyle.border))
    }
}
