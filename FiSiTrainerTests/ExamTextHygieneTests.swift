// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import XCTest
@testable import FiSiTrainer

/// Verhindert, dass interne Arbeitsnotizen aus dem IHK-Import („zum Gegenlesen“, „im Scan“, „OCR“,
/// „vermutlich“) wieder in Lerntexte gelangen. Geprüft werden alle Aufgaben-, Options-, Paar-,
/// Lücken- und Erklärungstexte aller Karten in `ExamCatalog.all`.
///
/// Bewusste Ausnahmen:
/// - Treffer nur als ganzes Wort: „Portscan“, „Virenscanner“ oder „Scanner“ sind Fachbegriffe und
///   werden nicht gemeldet, weil vor bzw. nach „scan“ ein Buchstabe steht.
/// - „WLAN-Scan“ ist der Fachbegriff aus 2024S GA2 4c (Aufgabentext der IHK) und steht in `allowedPhrases`.
/// Regel für Lerntexte: `Documentation/IHK-IMPORT.md`, Abschnitt „Formulierungsregel“.
final class ExamTextHygieneTests: XCTestCase {
    private static let allowedPhrases = ["WLAN-Scan"]

    /// „gegen(ge)lesen“ auch als Wortteil, die übrigen Begriffe nur als ganzes Wort (Groß/klein egal).
    private static let pattern = try! NSRegularExpression(
        pattern: #"gegen(ge)?les|(?<![\p{L}\d])(scans?|ocr|vermutlich\p{L}*)(?![\p{L}\d])"#,
        options: [.caseInsensitive])

    func testNoInternalReviewNotesInLearningTexts() {
        var findings: [String] = []
        for card in ExamCatalog.all {
            for text in Self.texts(of: card) {
                var cleaned = text
                for phrase in Self.allowedPhrases {
                    cleaned = cleaned.replacingOccurrences(of: phrase, with: "")
                }
                let range = NSRange(cleaned.startIndex..., in: cleaned)
                for match in Self.pattern.matches(in: cleaned, range: range) {
                    let word = (cleaned as NSString).substring(with: match.range)
                    findings.append("\(card.id): „\(word)“")
                }
            }
        }
        XCTAssertTrue(findings.isEmpty, "Interne Notizen in Lerntexten:\n" + findings.joined(separator: "\n"))
    }

    func testPatternCatchesNotesAndSparesTechnicalTerms() {
        func hits(_ text: String) -> Int {
            Self.pattern.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
        }
        XCTAssertEqual(hits("(Zum Gegenlesen: siehe Original.)"), 1)
        XCTAssertEqual(hits("Im Scan nicht lesbar."), 1)
        XCTAssertEqual(hits("Die OCR las IW."), 1)
        XCTAssertEqual(hits("Vermutlich ist 99,99 % gemeint."), 1)
        XCTAssertEqual(hits("Ein Portscan wird vom Virenscanner erkannt."), 0)
    }

    private static func texts(of card: ExamCard) -> [String] {
        switch card {
        case let .choice(_, _, prompt, options, explanation):
            return [prompt, explanation] + options
        case let .statement(_, _, text, _, explanation):
            return [text, explanation]
        case let .multiple(_, _, prompt, correct, wrong, explanation):
            return [prompt, explanation] + correct + wrong
        case let .match(_, _, prompt, pairs, extra, explanation):
            return [prompt, explanation] + pairs.flatMap { [$0.0, $0.1] } + extra
        case let .order(_, _, prompt, steps, explanation):
            return [prompt, explanation] + steps
        case let .gap(_, _, title, sentences, extra, explanation):
            return [title, explanation] + sentences.flatMap { [$0.0, $0.1] } + extra
        case let .fact(_, _, group, question, answer, explanation):
            return [group, question, answer, explanation]
        }
    }
}
