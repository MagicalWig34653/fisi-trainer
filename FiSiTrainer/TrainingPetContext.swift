// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

extension PetLearningContext {
    static func port(_ session: GameSession?) -> PetLearningContext {
        guard let session else {
            return .init(id: "port-ready", title: "Port-Quiz starten",
                         hint: "Beginne mit den bekannten Diensten. Du kannst mit den Tasten 1–4 antworten.",
                         explanation: nil, wasCorrect: nil)
        }
        guard !session.isComplete else {
            return .init(id: "port-finished-\(session.score)", title: "Port-Runde abgeschlossen",
                         hint: "Schau in die Port-Referenz und wiederhole die Dienste, bei denen du unsicher warst.",
                         explanation: "\(session.correctCount) von \(session.questions.count) Antworten waren richtig.",
                         wasCorrect: nil)
        }
        let question = session.questions[session.index]
        let hint: String
        switch question.kind {
        case .port:
            hint = "Der Dienst wird dafür verwendet: \(question.service.hint). Überlege, welchen Standardport du mit dieser Aufgabe verbindest, und vergleiche die angebotenen Zahlen."
        case .service:
            let candidates = question.choices.map(question.answerLabel).joined(separator: ", ")
            hint = "Zur Auswahl stehen \(candidates). Suche den Dienst für diesen Zweck: \(serviceClue(question.service))."
        case .transport:
            hint = "TCP stellt eine zuverlässige Verbindung bereit. UDP überträgt Datagramme ohne Verbindungsaufbau. Manche Dienste nutzen je nach Aufgabe oder Version beides."
        }
        let answered = session.selectedAnswer != nil
        let identity = session.questions.map { "\($0.service.id)-\($0.kind.rawValue)" }.joined(separator: ",")
        return .init(id: "port:\(identity):\(session.index)",
                     title: "\(question.title) – \(question.prompt)", hint: hint,
                     explanation: answered ? "Richtige Antwort: \(question.answerLabel(question.correctAnswer)). \(question.service.name): Port \(question.service.port), \(question.service.transport). \(question.service.hint)" : nil,
                     wasCorrect: session.selectedAnswer.map { $0 == question.correctAnswer })
    }

    static func subnet(_ session: SubnetSession?) -> PetLearningContext {
        guard let session else {
            return .init(id: "subnet-ready", title: "Subnetz-Sprint starten",
                         hint: "IPv4-Adressen haben 32 Bits. Das Präfix beschreibt, wie viele davon zum Netz gehören.",
                         explanation: nil, wasCorrect: nil)
        }
        guard !session.isComplete else {
            return .init(id: "subnet-finished-\(session.score)", title: "Subnetz-Runde abgeschlossen",
                         hint: "Schreibe dir die Zweierpotenzen auf und übe die Präfixe, bei denen du gezögert hast.",
                         explanation: "\(session.correctCount) von \(session.questions.count) Antworten waren richtig.",
                         wasCorrect: nil)
        }
        let question = session.questions[session.index]
        let hint = question.kind == .mask
            ? "Bei /\(question.prefix) verteilst du \(question.prefix) Netzbits auf vier Oktette. Jede volle Achtergruppe ergibt 255; die restlichen Bits addierst du von links mit 128, 64, 32, 16, 8, 4, 2 und 1."
            : "Bei /\(question.prefix) bleiben 32 − \(question.prefix) Hostbits. Rechne 2 hoch diese Zahl und ziehe 2 für Netz- und Broadcastadresse ab."
        let identity = session.questions.map { "\($0.prefix)-\($0.kind.rawValue)" }.joined(separator: ",")
        return .init(id: "subnet:\(identity):\(session.index)",
                     title: question.prompt, hint: hint,
                     explanation: session.selectedAnswer == nil ? nil : question.explanation,
                     wasCorrect: session.selectedAnswer.map { $0 == question.correctAnswer })
    }

    private static func serviceClue(_ service: PortService) -> String {
        switch service.id {
        case "mysql", "postgresql", "mssql":
            return "eine relationale Datenbankverbindung; überlege, welcher Datenbankserver diesen Standardport verwendet"
        case "imaps": return "verschlüsseltes Verwalten von E-Mails auf dem Server"
        case "pop3s": return "verschlüsseltes Abrufen von E-Mails"
        case "netbios-ns": return "die Namensauflösung in älteren Windows-Netzwerken"
        case "rpcbind": return "das Zuordnen von entfernten Prozeduraufrufen zu Dienstports"
        case "dhcp-client": return "den Empfang einer automatisch zugewiesenen IP-Konfiguration am Client"
        default: return service.hint
        }
    }
}
