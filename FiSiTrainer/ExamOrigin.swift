// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Herkunft einer Prüfungsaufgabe aus einer früheren IHK-Abschlussprüfung.
///
/// Die Angaben stehen nicht in den Karten selbst, sondern stecken in der Karten-ID
/// (`ihk-<teil>-<jahr><s|w>-<bereich>-<aufgabe>`, zum Beispiel `ihk-ap2-2026s-ga1-3b`).
/// So bleiben Karten-IDs stabile Speicherschlüssel, gespeicherte Stände bleiben lesbar und
/// eigene Aufgaben ohne Prüfung haben schlicht keine Herkunft (`nil`).
struct ExamOrigin: Codable, Hashable {
    enum Part: String, Codable, CaseIterable {
        case ap1, ap2

        var title: String { self == .ap1 ? "AP1" : "AP2" }
    }

    enum Term: String, Codable, CaseIterable {
        case sommer, winter

        var title: String { self == .sommer ? "Sommer" : "Winter" }
    }

    enum Ordinance: String, Codable {
        /// Ausbildungsordnung 2020 (Fachinformatiker, Prüfungen ab Winter 2021).
        case ao2020
        /// Frühere Ausbildungsordnung (Prüfungskatalog vor 2020).
        case alt

        var title: String { self == .ao2020 ? "AO 2020" : "alte AO" }
    }

    var part: Part
    /// Kalenderjahr der Prüfung; bei Winterprüfungen das Jahr, in dem sie stattfand (Winter 2019/20 = 2019).
    var year: Int
    var term: Term
    /// Prüfungsbereich, zum Beispiel „GA1“, „GA2“ oder „WiSo“.
    var area: String
    /// Aufgabe, zum Beispiel „3b“.
    var task: String

    var ordinance: Ordinance {
        year > 2021 || (year == 2021 && term == .winter) ? .ao2020 : .alt
    }

    /// Lesbare Herkunftszeile, zum Beispiel „AP2 Sommer 2026 · GA1 · Aufgabe 3b“.
    var label: String {
        "\(examTitle) · \(area) · Aufgabe \(task)"
    }

    /// Jahresangabe wie bei der IHK: Sommer „2026“, Winter „2025/26“.
    var yearText: String {
        term == .sommer ? "\(year)" : "\(year)/" + String(format: "%02d", (year + 1) % 100)
    }

    /// Kurz: „AP2 Sommer 2026“ bzw. „AP2 Winter 2025/26“.
    var examTitle: String { "\(part.title) \(term.title) \(yearText)" }

    /// Quellenangabe für das Ende der Erklärung, zum Beispiel „IHK AP2 FiSi Sommer 2026, GA1, Aufgabe 3b“.
    var sourceText: String { "IHK \(part.title) FiSi \(term.title) \(yearText), \(area), Aufgabe \(task)" }

    /// `true`, wenn die Prüfung höchstens `years` Jahre vor `referenceYear` stattfand.
    func isRecent(referenceYear: Int, years: Int = 4) -> Bool {
        year >= referenceYear - years
    }

    init(part: Part, year: Int, term: Term, area: String, task: String) {
        self.part = part
        self.year = year
        self.term = term
        self.area = area
        self.task = task
    }

    /// Liest die Herkunft aus einer Karten-ID; `nil` für eigene Aufgaben.
    init?(cardID: String) {
        let pieces = cardID.split(separator: "-", maxSplits: 4, omittingEmptySubsequences: false).map(String.init)
        guard pieces.count == 5, pieces[0] == "ihk",
              let part = Part(rawValue: pieces[1]),
              pieces[2].count == 5, let year = Int(pieces[2].dropLast()),
              let termCode = pieces[2].last,
              let term: Term = termCode == "s" ? .sommer : termCode == "w" ? .winter : nil
        else { return nil }
        let areas = ["ga1": "GA1", "ga2": "GA2", "wiso": "WiSo", "ga": "GA", "a": "Teil 1"]
        guard let area = areas[pieces[3]] else { return nil }
        self.init(part: part, year: year, term: term, area: area, task: pieces[4])
    }
}

extension ExamCard {
    /// Herkunft aus einer IHK-Prüfung; `nil` bei eigenen Aufgaben.
    var origin: ExamOrigin? { ExamOrigin(cardID: id) }
}

extension ExamTask {
    /// Herkunft aus einer IHK-Prüfung; `nil` bei eigenen und generierten Aufgaben.
    var origin: ExamOrigin? { ExamOrigin(cardID: id) }
}

/// Einstellung, welche Prüfungsaufgaben ausgewählt werden. Eigene Aufgaben (ohne Herkunft) bleiben immer erlaubt.
struct ExamOriginFilter: Codable, Equatable {
    /// Nur Prüfungen der letzten vier Jahre.
    var onlyRecent = false
    /// Nur AP1 oder nur AP2; `nil` = beide.
    var part: ExamOrigin.Part?

    static let all = ExamOriginFilter()
    static let recentYears = 4
    static let defaultsKey = "examOriginFilter"

    func allows(_ origin: ExamOrigin?, referenceYear: Int = Calendar.current.component(.year, from: Date())) -> Bool {
        guard let origin else { return true }
        if let part, origin.part != part { return false }
        if onlyRecent, !origin.isRecent(referenceYear: referenceYear, years: Self.recentYears) { return false }
        return true
    }

    static func load(from defaults: UserDefaults = .standard) -> ExamOriginFilter {
        guard let data = defaults.data(forKey: defaultsKey),
              let filter = try? JSONDecoder().decode(ExamOriginFilter.self, from: data) else { return .all }
        return filter
    }

    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: Self.defaultsKey) }
    }
}
