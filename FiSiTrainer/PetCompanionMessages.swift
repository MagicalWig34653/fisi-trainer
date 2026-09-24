// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Prepared copy rotates by an explicit turn, so SwiftUI redraws never change a message.
enum PetCompanionMessages {
    static func greeting(after result: Bool?, turn: Int) -> String {
        let choices: [String]
        switch result {
        case .some(true):
            choices = [
                "Gut gelöst. Schau dir an, warum die Antwort passt.",
                "Das sitzt. Bereit für die nächste Aufgabe?",
                "Stark gemacht. Dieses Wissen kannst du gleich wieder nutzen."
            ]
        case .some(false):
            choices = [
                "Noch nicht ganz. Der Hinweis hilft dir beim nächsten Versuch.",
                "Fehler zeigen, was du üben kannst. Schau dir die Erklärung an.",
                "Bleib dran. Geh die Aufgabe Schritt für Schritt durch."
            ]
        case .none:
            choices = [
                "Ich bin dabei. Hol dir einen Hinweis, wenn du feststeckst.",
                "Lies die Aufgabe in Ruhe. Ein Tipp ist jederzeit bereit.",
                "Nimm dir Zeit für den nächsten Schritt. Ich helfe dir gern."
            ]
        }
        return choices[positiveIndex(turn, count: choices.count)]
    }

    static func motivation(turn: Int) -> String {
        let choices = [
            "Du musst nicht alles sofort wissen. Prüfe zuerst, was du schon sicher weißt.",
            "Ein Schritt nach dem anderen reicht. Fang mit dem Teil an, den du erkennst.",
            "Bleib dran. Auch ein falscher Versuch hilft dir, die Regel besser zu verstehen.",
            "Nimm dir einen Moment. Mit dem Hinweis findest du einen guten Einstieg."
        ]
        return choices[positiveIndex(turn, count: choices.count)]
    }

    private static func positiveIndex(_ turn: Int, count: Int) -> Int {
        let remainder = turn % count
        return remainder >= 0 ? remainder : remainder + count
    }
}
