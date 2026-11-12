// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Prepared copy rotates by an explicit turn, so SwiftUI redraws never change a message.
enum PetCompanionMessages {
    /// Freude über das Tagesziel; `streak` nennt die Serie, wenn sie schon länger läuft.
    static func dayGoal(streak: Int, turn: Int) -> String {
        if streak >= 100 { return "\(streak) Tage in Folge! Das ist eine echte Gewohnheit." }
        if streak >= 30 { return "\(streak) Tage am Stück. Ich bin richtig stolz auf dich." }
        if streak >= 7 { return "\(streak) Tage in Folge, das Tagesziel steht auch heute." }
        let choices = [
            "Tagesziel geschafft. Jede weitere Aufgabe ist Bonus.",
            "Das Tagesziel steht. Dein Streak lebt, ich freue mich mit dir.",
            "Geschafft für heute. Morgen machen wir weiter."
        ]
        return choices[positiveIndex(turn, count: choices.count)]
    }

    static func greeting(after result: Bool?, turn: Int, goalMet: Bool = false, streak: Int = 0) -> String {
        // Am erreichten Tagesziel wechselt der Gruß zwischen Aufgabenbezug und Freude über das Ziel.
        if goalMet, result != false, turn % 2 == 1 { return dayGoal(streak: streak, turn: turn / 2) }
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
