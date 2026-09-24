// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

/// A small companion beside an active exercise. AI requests happen only after a button press.
struct PetCompanionView: View {
    let pet: PetKind
    let context: PetLearningContext

    @EnvironmentObject private var rewards: RewardStore

    @StateObject private var intelligence = PetIntelligence()
    @State private var responseTask: Task<Void, Never>?
    @State private var responseGeneration = 0
    @State private var response: String?
    @State private var responseLabel: String?
    @State private var responseError: String?
    @State private var isLoading = false
    @State private var showingChat = false
    @State private var interaction: PetInteraction?
    @State private var interactionID = 0
    @State private var greetingTurn = 0
    @State private var motivationTurn = 0
    @State private var recentHistory: [PetChatMessage] = []

    private let background = Color(red: 0.078, green: 0.113, blue: 0.151)
    private let raised = Color(red: 0.103, green: 0.145, blue: 0.183)
    private let muted = Color(red: 0.53, green: 0.61, blue: 0.64)
    private let accent = Color(red: 0.76, green: 0.97, blue: 0.32)

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            PetHabitatView(pet: pet, interaction: interaction, interactionID: interactionID,
                           outfit: rewards.outfit(for: pet), toy: rewards.toy(for: pet))
                .frame(width: 140, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("\(pet.name), dein 3D-Begleiter")

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    Image(systemName: pet.symbol)
                        .foregroundStyle(accent)
                    Text(pet.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("· \(context.title)")
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundStyle(muted)
                    Spacer(minLength: 0)
                    Text("BEGLEITER")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(muted)
                        .help(intelligence.availabilityText)
                    if isLoading { ProgressView().controlSize(.small) }
                }

                if let response {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(responseLabel ?? "Vorbereiteter Tipp")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent)
                            .help(responseError ?? intelligence.availabilityText)
                        ScrollView {
                            Text(response)
                                .font(.system(size: 12))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 52)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Vorbereitete Begleitung")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent)
                        Text(greeting)
                            .font(.system(size: 12))
                            .lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
                    actionButton(context.wasCorrect == nil ? "Tipp" : "Erklärung", symbol: "lightbulb") { showPreparedTip() }
                    actionButton("Mut machen", symbol: "heart.fill") { requestMotivation() }
                    actionButton(context.wasCorrect == nil ? "KI-Tipp" : "KI-Erklärung", symbol: "sparkles") { requestAIHint() }
                    actionButton("Plaudern", symbol: "bubble.left.and.bubble.right") {
                        showingChat = true
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.09)))
        .foregroundStyle(.white)
        .sheet(isPresented: $showingChat) {
            PetChatView(pet: pet, context: context)
        }
        .onAppear { intelligence.refreshAvailability() }
        .onChange(of: context.id) { _, _ in clearForNewContext() }
        .onChange(of: pet) { _, _ in clearForNewContext() }
        .onChange(of: context.wasCorrect) { _, result in
            cancelResponse()
            response = nil
            responseLabel = nil
            responseError = nil
            greetingTurn += 1
            guard let result else { return }
            interaction = result ? .play : .pet
            interactionID += 1
        }
        .onDisappear { cancelResponse() }
    }

    private var greeting: String {
        PetCompanionMessages.greeting(after: context.wasCorrect, turn: greetingTurn)
    }

    private func actionButton(_ title: String, symbol: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(raised, in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private func showPreparedTip() {
        cancelResponse()
        responseError = nil
        responseLabel = context.wasCorrect == nil ? "Vorbereiteter Tipp" : "Erklärung aus Lernmaterial"
        response = context.wasCorrect == nil ? context.hint : (context.explanation ?? context.hint)
    }

    private func requestMotivation() {
        cancelResponse()
        responseError = nil
        responseLabel = "Vorbereitete Ermutigung"
        response = PetCompanionMessages.motivation(turn: motivationTurn)
        motivationTurn += 1
    }

    private func requestAIHint() {
        let hasAnswered = context.wasCorrect != nil
        requestAI(
            prompt: hasAnswered
                ? "Erkläre die richtige Lösung dieser Aufgabe anhand der bekannten Erklärung in ein bis zwei konkreten Sätzen. Vermeide eine wörtliche Wiederholung deiner letzten Antwort."
                : "Gib einen konkreten Denkanstoß zur aktuellen Aufgabe, ohne die Lösung zu verraten. Vermeide eine wörtliche Wiederholung deiner letzten Antwort.",
            fallback: hasAnswered ? (context.explanation ?? context.hint) : context.hint,
            fallbackLabel: hasAnswered ? "Erklärung aus Lernmaterial" : "Vorbereiteter Tipp"
        )
    }

    private func requestAI(prompt: String, fallback: String, fallbackLabel: String) {
        cancelResponse()
        intelligence.refreshAvailability()
        guard intelligence.isAvailable else {
            responseError = intelligence.availabilityText
            responseLabel = "KI nicht verfügbar · \(fallbackLabel)"
            response = fallback
            return
        }

        let generation = responseGeneration
        let requestContext = context
        let requestPet = pet
        let requestHistory = Array(recentHistory.suffix(6))
        isLoading = true
        responseError = nil
        responseLabel = "Lokale KI antwortet …"
        response = nil
        responseTask = Task { @MainActor in
            do {
                let answer = try await intelligence.respond(to: prompt, pet: requestPet,
                                                            context: requestContext,
                                                            history: requestHistory)
                guard !Task.isCancelled, generation == responseGeneration,
                      requestContext == context, requestPet == pet else { return }
                responseLabel = "Von lokaler KI erstellt"
                response = answer
                let updatedHistory = Array((requestHistory + [
                    PetChatMessage(role: .user, text: prompt),
                    PetChatMessage(role: .pet, text: answer)
                ]).suffix(6))
                recentHistory = updatedHistory
                isLoading = false
            } catch {
                guard !Task.isCancelled, generation == responseGeneration,
                      requestContext == context, requestPet == pet else { return }
                responseError = error.localizedDescription
                responseLabel = "KI gerade nicht verfügbar · \(fallbackLabel)"
                response = fallback
                isLoading = false
                intelligence.refreshAvailability()
            }
        }
    }

    private func clearForNewContext() {
        cancelResponse()
        response = nil
        responseLabel = nil
        responseError = nil
        recentHistory = []
        greetingTurn += 1
        interaction = nil
    }

    private func cancelResponse() {
        responseTask?.cancel()
        responseTask = nil
        responseGeneration += 1
        isLoading = false
    }
}
