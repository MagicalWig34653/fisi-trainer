// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import XCTest
@testable import FiSiTrainer

final class PetIntelligenceTests: XCTestCase {
    @MainActor
    func testRepeatedOpeningIsRemovedButNewExplanationRemains() {
        let previous = "TCP überträgt Daten geordnet."
        let history = [PetChatMessage(role: .pet, text: previous)]
        XCTAssertEqual(PetIntelligence.removingRepeatedOpening(
            from: previous + " Fehlende Daten werden erneut übertragen.", history: history),
                       "Fehlende Daten werden erneut übertragen.")
        XCTAssertTrue(PetIntelligence.removingRepeatedOpening(from: previous, history: history).isEmpty)
        XCTAssertEqual(PetIntelligence.removingRepeatedOpening(from: "Ein neuer Aspekt.", history: history),
                       "Ein neuer Aspekt.")
        XCTAssertEqual(PetIntelligence.removingRepeatedOpening(
            from: "Java ist eine Programmiersprache.", history: [.init(role: .pet, text: "Ja")]),
                       "Java ist eine Programmiersprache.")
    }

    @MainActor
    func testOpenQuestionExposesHintButNotExplanation() {
        let context = PetLearningContext(id: "subnet-1", title: "Subnetz berechnen",
                                         hint: "Zähle die Hostbits.",
                                         explanation: "Die Lösung ist /26.")
        let prompt = PetIntelligence.prompt(for: "Hilf mir", context: context)

        XCTAssertTrue(prompt.contains("Subnetz berechnen"))
        XCTAssertTrue(prompt.contains("Zähle die Hostbits."))
        XCTAssertTrue(prompt.contains("nur Hinweise geben, keine Lösung nennen"))
        XCTAssertFalse(prompt.contains("Die Lösung ist /26."))
        XCTAssertFalse(PetIntelligence.instructions(for: .cat).contains("Vor der Abgabe"))
    }

    @MainActor
    func testSubmittedQuestionCanUseExplanationAndResult() {
        let context = PetLearningContext(id: "subnet-1", title: "Subnetz berechnen",
                                         hint: "Zähle die Hostbits.",
                                         explanation: "Die Lösung ist /26.",
                                         wasCorrect: false)
        let prompt = PetIntelligence.prompt(for: "Warum?", context: context)

        XCTAssertTrue(prompt.contains("Antwort wurde als falsch bewertet."))
        XCTAssertTrue(prompt.contains("Die Lösung ist /26."))
    }

    @MainActor
    func testHistoryAndCurrentInputAreBounded() {
        let history = (0..<9).map {
            PetChatMessage(role: .user, text: "Nachricht-\($0)")
        }
        let prompt = PetIntelligence.prompt(for: String(repeating: "x", count: 1_500),
                                            context: nil, history: history)

        XCTAssertFalse(prompt.contains("Nachricht-0"))
        XCTAssertFalse(prompt.contains("Nachricht-2"))
        XCTAssertTrue(prompt.contains("Nachricht-3"))
        XCTAssertTrue(prompt.contains("Nachricht-8"))
        XCTAssertTrue(prompt.hasSuffix(String(repeating: "x", count: 1_000)))
        XCTAssertFalse(prompt.contains(String(repeating: "x", count: 1_001)))
    }

    @MainActor
    func testPetPersonalitiesStayDistinct() {
        XCTAssertTrue(PetIntelligence.instructions(for: .cat).contains("Katze"))
        XCTAssertTrue(PetIntelligence.instructions(for: .fox).contains("Fuchs"))
        XCTAssertTrue(PetIntelligence.instructions(for: .dragon).contains("Drache"))
        XCTAssertTrue(PetIntelligence.instructions(for: .cat).contains("keine Tierlaute"))
        XCTAssertFalse(PetIntelligence.instructions(for: .cat).contains("Miau"))
        XCTAssertTrue(PetIntelligence.instructions(for: .cat).contains("Keine Metaphern"))
    }

    @MainActor
    func testFreeChatHasNoExerciseRule() {
        let prompt = PetIntelligence.prompt(for: "Wie geht es dir?", context: nil)

        XCTAssertTrue(prompt.contains("Freies Gespräch ohne aktuelle Lernaufgabe"))
        XCTAssertFalse(prompt.contains("keine Lösung nennen"))
        XCTAssertFalse(prompt.contains("Hinweis aus Lernmaterial"))
    }

    @MainActor
    func testRecentPetAnswerPromptsForNewConcreteAspect() {
        let history = [
            PetChatMessage(role: .user, text: "Was ist DNS?"),
            PetChatMessage(role: .pet, text: "DNS übersetzt Namen in IP-Adressen.")
        ]
        let prompt = PetIntelligence.prompt(for: "Und wie funktioniert das?",
                                            context: nil, history: history)

        XCTAssertTrue(prompt.contains("DNS übersetzt Namen in IP-Adressen."))
        XCTAssertTrue(prompt.contains("neuen konkreten Aspekt ohne Wiederholung"))
        XCTAssertTrue(prompt.hasSuffix("Und wie funktioniert das?"))
    }

    @MainActor
    func testNetworkingFactsSeparateReliabilityFromEncryption() {
        let history = [
            PetChatMessage(role: .user, text: "Warum nutzt SSH TCP?"),
            PetChatMessage(role: .pet, text: "TCP macht die Verschlüsselung sicher.")
        ]
        let prompt = PetIntelligence.prompt(for: "Warum genau?", context: nil, history: history)

        XCTAssertTrue(prompt.contains("TCP selbst verschlüsselt nicht"))
        XCTAssertTrue(prompt.contains("die Verschlüsselung kommt aus SSH"))
        XCTAssertTrue(prompt.contains("QUIC über UDP"))
        XCTAssertTrue(prompt.contains("Korrigiere fachliche Fehler"))
    }

    @MainActor
    func testOpenExerciseDoesNotReceiveAnswerFacts() {
        let context = PetLearningContext(id: "ssh", title: "Warum nutzt SSH TCP?",
                                         hint: "Denke an die Reihenfolge der Daten.")
        let prompt = PetIntelligence.prompt(for: "Hilf mir", context: context)

        XCTAssertTrue(prompt.contains("nur Hinweise geben, keine Lösung nennen"))
        XCTAssertFalse(prompt.contains("Geprüfte Grundlagen"))
    }
}
