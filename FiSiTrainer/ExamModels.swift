// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Subject areas of the exam trainer. Raw values are persistence keys.
enum ExamSubject: String, Codable, CaseIterable, Identifiable {
    case wiso, it

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wiso: "Wirtschafts- und Sozialkunde"
        case .it: "IT-Fachwissen"
        }
    }

    var shortTitle: String {
        switch self {
        case .wiso: "WiSo"
        case .it: "IT"
        }
    }
}

/// Topics group the catalog. Raw values are persistence keys.
enum ExamTopic: String, Codable, CaseIterable, Identifiable {
    case ausbildung, arbeitsrecht, schutz, mitbestimmung, sozial, unternehmen, recht, wirtschaft, nachhaltigkeit
    case netze, sicherheit, systeme

    var id: String { rawValue }

    var subject: ExamSubject {
        switch self {
        case .netze, .sicherheit, .systeme: .it
        default: .wiso
        }
    }

    var title: String {
        switch self {
        case .ausbildung: "Ausbildung & Weiterbildung"
        case .arbeitsrecht: "Arbeitsvertrag & Kündigung"
        case .schutz: "Arbeits- & Jugendschutz"
        case .mitbestimmung: "Betriebsrat & Tarifrecht"
        case .sozial: "Sozialversicherung & Steuern"
        case .unternehmen: "Unternehmen & Rechtsformen"
        case .recht: "Rechtsgeschäfte & Verbraucher"
        case .wirtschaft: "Markt & Wirtschaftspolitik"
        case .nachhaltigkeit: "Nachhaltigkeit & Umwelt"
        case .netze: "Netzwerke & OSI"
        case .sicherheit: "IT-Sicherheit & Datenschutz"
        case .systeme: "Speicher, Backup & Betrieb"
        }
    }

    var symbol: String {
        switch self {
        case .ausbildung: "graduationcap.fill"
        case .arbeitsrecht: "signature"
        case .schutz: "cross.case.fill"
        case .mitbestimmung: "person.3.fill"
        case .sozial: "shield.lefthalf.filled"
        case .unternehmen: "building.2.fill"
        case .recht: "books.vertical.fill"
        case .wirtschaft: "chart.line.uptrend.xyaxis"
        case .nachhaltigkeit: "leaf.fill"
        case .netze: "network"
        case .sicherheit: "lock.shield.fill"
        case .systeme: "externaldrive.fill"
        }
    }

    /// A method hint for the companion that never contains a solution.
    var studyHint: String {
        switch self {
        case .ausbildung: "Überlege, was das Berufsbildungsgesetz regelt und welche Pflichten Ausbildende und Auszubildende jeweils haben."
        case .arbeitsrecht: "Prüfe, welches Gesetz greift: BGB (Kündigung, Fristen), KSchG, TzBfG, EFZG, BUrlG, MuSchG oder AGG."
        case .schutz: "Prüfe zuerst das Alter der Person und damit das passende Schutzgesetz. Frag dann, wer für die Maßnahme verantwortlich ist."
        case .mitbestimmung: "Frag dich, wer hier Vertragspartner ist und auf welcher Ebene die Regel gilt: Gesetz, Tarifvertrag, Betrieb oder Einzelvertrag."
        case .sozial: "Überlege, welches Lebensrisiko abgesichert wird und wer dafür zuständig ist."
        case .unternehmen: "Achte auf Haftung, Kapital, Geschäftsführung und Eintragungen. Bei Zusammenschlüssen: Was passiert mit der Selbstständigkeit?"
        case .recht: "Prüfe Schritt für Schritt: Wer handelt, ist die Person geschäftsfähig, welche Form ist vorgeschrieben und wer hat welche Rechte an der Sache?"
        case .wirtschaft: "Denke an Angebot und Nachfrage, Kaufkraft, Konjunkturphasen und die Ziele des Stabilitätsgesetzes."
        case .nachhaltigkeit: "Nachhaltigkeit hat eine ökologische, ökonomische und soziale Seite. Was schont Ressourcen dauerhaft?"
        case .netze: "Überlege, auf welcher Schicht ein Gerät oder Protokoll arbeitet und welche Adressen es auswertet."
        case .sicherheit: "Frag, welches Schutzziel betroffen ist und ob personenbezogene Daten im Spiel sind."
        case .systeme: "Rechne Kapazitäten schrittweise und überlege bei Sicherungen, worauf sich jede Sicherung bezieht."
        }
    }

    static func topics(for subject: ExamSubject) -> [ExamTopic] {
        allCases.filter { $0.subject == subject }
    }
}

/// Authored catalog entries. Correct answers are listed first; rounds shuffle them.
enum ExamCard {
    /// Single choice. `options[0]` is correct.
    case choice(id: String, topic: ExamTopic, prompt: String, options: [String], explanation: String)
    /// A statement that is either true or false.
    case statement(id: String, topic: ExamTopic, text: String, isTrue: Bool, explanation: String)
    /// Several correct answers among distractors.
    case multiple(id: String, topic: ExamTopic, prompt: String, correct: [String], wrong: [String], explanation: String)
    /// Each left item belongs to one right label. Right labels may repeat.
    case match(id: String, topic: ExamTopic, prompt: String, pairs: [(String, String)], extra: [String], explanation: String)
    /// Steps in their correct order.
    case order(id: String, topic: ExamTopic, prompt: String, steps: [String], explanation: String)
    /// Sentences containing `___` and the word for that gap.
    case gap(id: String, topic: ExamTopic, title: String, sentences: [(String, String)], extra: [String], explanation: String)
    /// A short fact whose answer is compared with other answers of the same group.
    case fact(id: String, topic: ExamTopic, group: String, question: String, answer: String, explanation: String)

    var id: String {
        switch self {
        case .choice(let id, _, _, _, _), .statement(let id, _, _, _, _),
             .multiple(let id, _, _, _, _, _), .match(let id, _, _, _, _, _),
             .order(let id, _, _, _, _), .gap(let id, _, _, _, _, _),
             .fact(let id, _, _, _, _, _): id
        }
    }

    var topic: ExamTopic {
        switch self {
        case .choice(_, let topic, _, _, _), .statement(_, let topic, _, _, _),
             .multiple(_, let topic, _, _, _, _), .match(_, let topic, _, _, _, _),
             .order(_, let topic, _, _, _), .gap(_, let topic, _, _, _, _),
             .fact(_, let topic, _, _, _, _): topic
        }
    }
}

/// Game modes. Raw values are persistence keys.
enum ExamMode: String, Codable, CaseIterable, Identifiable {
    case quiz, truefalse, multiple, match, order, gap, facts, calc, exam

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiz: "Prüfungsquiz"
        case .truefalse: "Richtig oder falsch?"
        case .multiple: "Alle finden"
        case .match: "Zuordnen"
        case .order: "Reihenfolge"
        case .gap: "Lückentext"
        case .facts: "Zahlen & Fristen"
        case .calc: "Rechentraining"
        case .exam: "Prüfungssimulation"
        }
    }

    var summary: String {
        switch self {
        case .quiz: "Gebundene Aufgaben wie in der Prüfung: eine von fünf Antworten ist richtig."
        case .truefalse: "Blitzrunde mit 15 Aussagen. Schnell entscheiden, Erklärung lesen, weiter."
        case .multiple: "„Nennen Sie …“-Aufgaben: Finde alle zutreffenden Antworten."
        case .match: "Ordne Begriffe, Fälle und Beispiele richtig zu."
        case .order: "Bringe Abläufe wie Tarifrunde, Kündigung oder DHCP in die richtige Reihenfolge."
        case .gap: "Setze Fachbegriffe in kurze Texte ein, wie bei den ungebundenen Aufgaben."
        case .facts: "Fristen, Altersgrenzen und Zahlen, die in der Prüfung immer wieder vorkommen."
        case .calc: "Reallohn, Kündigungsfrist, Kennzahlen, RAID oder Übertragungszeit – mit neuen Zahlen in jeder Runde."
        case .exam: "30 gemischte Aufgaben mit Punkten und IHK-Note. Die Auflösung gibt es am Ende."
        }
    }

    var symbol: String {
        switch self {
        case .quiz: "checklist"
        case .truefalse: "hand.thumbsup.fill"
        case .multiple: "checkmark.square.fill"
        case .match: "arrow.left.arrow.right"
        case .order: "list.number"
        case .gap: "text.insert"
        case .facts: "calendar.badge.clock"
        case .calc: "function"
        case .exam: "doc.text.magnifyingglass"
        }
    }

    var roundLength: Int {
        switch self {
        case .quiz, .calc: 10
        case .truefalse: 15
        case .multiple: 8
        case .match: 6
        case .order, .gap: 5
        case .facts: 12
        case .exam: 30
        }
    }

    var completionBonus: Int { self == .exam ? 100 : 50 }
}

/// A playable, persisted task. Answers are option indices (choice) or per-item indices.
struct ExamTask: Codable, Equatable {
    enum Kind: String, Codable {
        /// One option is correct.
        case single
        /// `solution` lists all correct option indices.
        case multiple
        /// `solution[i]` is the option index for `items[i]`.
        case match
        /// `items` are shown shuffled; `solution` lists item indices in correct order.
        case order
    }

    let id: String
    let kind: Kind
    let topic: ExamTopic
    let prompt: String
    let items: [String]
    let options: [String]
    let solution: [Int]
    let explanation: String

    var isValid: Bool {
        guard !id.isEmpty, !prompt.isEmpty, !explanation.isEmpty,
              options.allSatisfy({ !$0.isEmpty }), items.allSatisfy({ !$0.isEmpty }) else { return false }
        switch kind {
        case .single:
            return (2...6).contains(options.count) && Set(options).count == options.count &&
                solution.count == 1 && options.indices.contains(solution[0]) && items.isEmpty
        case .multiple:
            return (3...9).contains(options.count) && Set(options).count == options.count &&
                !solution.isEmpty && solution.count < options.count &&
                Set(solution).count == solution.count && solution.allSatisfy(options.indices.contains) &&
                items.isEmpty
        case .match:
            return (2...6).contains(items.count) && (2...8).contains(options.count) &&
                Set(options).count == options.count && solution.count == items.count &&
                solution.allSatisfy(options.indices.contains)
        case .order:
            return (3...8).contains(items.count) && options.isEmpty &&
                solution.sorted() == Array(items.indices)
        }
    }

    /// Whether a submitted answer has the right shape for this task.
    func accepts(_ answer: [Int]) -> Bool {
        switch kind {
        case .single:
            return answer.count == 1 && options.indices.contains(answer[0])
        case .multiple:
            return !answer.isEmpty && Set(answer).count == answer.count &&
                answer.allSatisfy(options.indices.contains)
        case .match:
            return answer.count == items.count && answer.allSatisfy(options.indices.contains)
        case .order:
            return answer.sorted() == Array(items.indices)
        }
    }

    /// Share of the task that was solved, used for partial credit in the exam simulation.
    func credit(for answer: [Int]) -> Double {
        guard accepts(answer) else { return 0 }
        switch kind {
        case .single:
            return answer == solution ? 1 : 0
        case .multiple:
            let chosen = Set(answer), correct = Set(solution)
            let hits = chosen.intersection(correct).count
            let misses = chosen.subtracting(correct).count
            return max(0, Double(hits - misses)) / Double(correct.count)
        case .match, .order:
            let hits = zip(answer, solution).filter { $0 == $1 }.count
            return Double(hits) / Double(solution.count)
        }
    }

    func isCorrect(_ answer: [Int]) -> Bool {
        switch kind {
        case .multiple: accepts(answer) && Set(answer) == Set(solution)
        default: accepts(answer) && answer == solution
        }
    }

    /// Human-readable form of an answer, used in reviews.
    func describe(_ answer: [Int]) -> String {
        switch kind {
        case .single, .multiple:
            let chosen = kind == .multiple ? answer.sorted() : answer
            return chosen.compactMap { options.indices.contains($0) ? options[$0] : nil }
                .joined(separator: " · ")
        case .match:
            return zip(items, answer).map { item, option in
                "\(item) → \(options.indices.contains(option) ? options[option] : "–")"
            }.joined(separator: "\n")
        case .order:
            return answer.enumerated().compactMap { position, item in
                items.indices.contains(item) ? "\(position + 1). \(items[item])" : nil
            }.joined(separator: "\n")
        }
    }

    var solutionText: String { describe(solution) }
}

/// IHK grading scale for written exams (100-point scale).
enum ExamGrade {
    static func grade(forPercent percent: Double) -> (note: Int, title: String) {
        let points = Int(percent.rounded())
        switch points {
        case 92...: return (1, "sehr gut")
        case 81...: return (2, "gut")
        case 67...: return (3, "befriedigend")
        case 50...: return (4, "ausreichend")
        case 30...: return (5, "mangelhaft")
        default: return (6, "ungenügend")
        }
    }
}
