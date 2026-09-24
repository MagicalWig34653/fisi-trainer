// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import AVFoundation
import SwiftUI

struct PetChatView: View {
    let pet: PetKind
    let context: PetLearningContext?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var intelligence = PetIntelligence()
    @State private var speaker = AVSpeechSynthesizer()
    @FocusState private var inputFocused: Bool
    @State private var input = ""
    @State private var messages: [PetChatMessage] = []
    @State private var isResponding = false
    @State private var errorText: String?
    @State private var requestTask: Task<Void, Never>?
    @State private var conversationID = UUID()

    init(pet: PetKind, context: PetLearningContext? = nil) {
        self.pet = pet
        self.context = context
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            Text(context == nil
                                 ? "Frag dein Pet etwas zum Lernen."
                                 : "Frag nach einem Hinweis zu dieser Aufgabe.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 28)
                        }
                        ForEach(messages) { message in
                            messageRow(message)
                                .id(message.id)
                        }
                        if isResponding {
                            HStack(spacing: 8) {
                                ProgressView().controlSize(.small)
                                Text("\(pet.name) denkt nach …")
                                    .foregroundStyle(.secondary)
                            }
                            .id("thinking")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: isResponding) { _, responding in
                    if responding {
                        withAnimation { proxy.scrollTo("thinking", anchor: .bottom) }
                    }
                }
            }

            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Label(intelligence.availabilityText,
                      systemImage: intelligence.isAvailable ? "lock.shield" : "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !intelligence.isAvailable {
                    Button("Erneut prüfen", systemImage: "arrow.clockwise") {
                        intelligence.refreshAvailability()
                        if intelligence.isAvailable { inputFocused = true }
                    }
                    .font(.caption)
                }

                if !intelligence.isAvailable, let context, !context.hint.isEmpty {
                    Text("Hinweis aus Lernmaterial (ohne KI): \(context.hint)")
                        .font(.callout)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }

                if let errorText {
                    Text(errorText)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                HStack {
                    TextField("Nachricht an \(pet.name)", text: $input)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                        .onSubmit(send)
                        .onChange(of: input) { _, newValue in
                            if newValue.count > 1_000 { input = String(newValue.prefix(1_000)) }
                        }
                        .disabled(!intelligence.isAvailable || isResponding)
                        .accessibilityLabel("Nachricht an \(pet.name)")
                    Button("Senden", action: send)
                        .disabled(!intelligence.isAvailable || isResponding ||
                                  input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Text("Antworten werden lokal erzeugt und können Fehler enthalten.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 440, idealWidth: 520, minHeight: 420, idealHeight: 540)
        .onAppear {
            intelligence.refreshAvailability()
            DispatchQueue.main.async { inputFocused = true }
        }
        .onDisappear {
            cancelRequest()
            speaker.stopSpeaking(at: .immediate)
        }
        .onChange(of: pet) { _, _ in resetConversation() }
        .onChange(of: context) { _, _ in resetConversation() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: pet.symbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Chat mit \(pet.name)").font(.headline)
                if let context {
                    Text(context.title).font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button("Schließen") {
                cancelRequest()
                dismiss()
            }
        }
        .padding()
    }

    private func messageRow(_ message: PetChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }
            VStack(alignment: .leading, spacing: 3) {
                Text(message.role == .user ? "Du" : "\(pet.name) · lokale KI")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(message.text)
                    .textSelection(.enabled)
                if message.role == .pet {
                    HStack(spacing: 8) {
                        Button("Vorlesen", systemImage: "speaker.wave.2") {
                            speaker.stopSpeaking(at: .immediate)
                            let utterance = AVSpeechUtterance(string: message.text)
                            utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
                            speaker.speak(utterance)
                        }
                        .accessibilityLabel("Antwort von \(pet.name) vorlesen")
                        Button("Stopp", systemImage: "stop.fill") {
                            speaker.stopSpeaking(at: .immediate)
                        }
                        .accessibilityLabel("Vorlesen stoppen")
                    }
                    .font(.caption)
                }
            }
            .padding(10)
            .background(message.role == .user ? Color.accentColor.opacity(0.15) :
                        Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
            if message.role == .pet { Spacer(minLength: 48) }
        }
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard intelligence.isAvailable, !isResponding, !text.isEmpty else { return }
        let history = messages
        let requestID = conversationID
        input = ""
        errorText = nil
        messages.append(PetChatMessage(role: .user, text: text))
        isResponding = true
        requestTask = Task {
            defer {
                if requestID == conversationID {
                    isResponding = false
                    requestTask = nil
                    inputFocused = true
                }
            }
            do {
                let answer = try await intelligence.respond(to: text, pet: pet,
                                                            context: context, history: history)
                guard !Task.isCancelled, requestID == conversationID else { return }
                messages.append(PetChatMessage(role: .pet, text: answer))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, requestID == conversationID else { return }
                errorText = error.localizedDescription
                intelligence.refreshAvailability()
            }
        }
    }

    private func cancelRequest() {
        conversationID = UUID()
        requestTask?.cancel()
        requestTask = nil
        isResponding = false
    }

    private func resetConversation() {
        cancelRequest()
        speaker.stopSpeaking(at: .immediate)
        messages = []
        input = ""
        errorText = nil
        intelligence.refreshAvailability()
        DispatchQueue.main.async { inputFocused = true }
    }
}
