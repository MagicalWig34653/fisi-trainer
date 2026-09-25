// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Generators for the "Rechentraining" mode. Each case builds a fresh, uniquely solvable
/// calculation task with new, realistic numbers on every call, using the supplied RNG so
/// rounds stay deterministic for a given seed.
enum ExamCalculation: String, CaseIterable, Identifiable {
    // WiSo
    case reallohn, inflationsrate, kuendigungsfrist, jugendurlaub, urlaubstage, betriebsrat
    case svanteil, nettolohn, produktivitaet, wirtschaftlichkeit, rentabilitaet, zinsen, skonto
    // IT
    case raid, uebertragung, bildspeicher, einheiten, subnetze, usv, stromkosten, verfuegbarkeit

    var id: String { "calc-\(rawValue)" }

    var topic: ExamTopic {
        switch self {
        case .reallohn, .inflationsrate: .wirtschaft
        case .kuendigungsfrist, .urlaubstage: .arbeitsrecht
        case .jugendurlaub: .schutz
        case .betriebsrat: .mitbestimmung
        case .svanteil, .nettolohn: .sozial
        case .produktivitaet, .wirtschaftlichkeit, .rentabilitaet: .unternehmen
        case .zinsen, .skonto: .recht
        case .raid, .bildspeicher, .einheiten, .usv, .verfuegbarkeit: .systeme
        case .uebertragung, .subnetze: .netze
        case .stromkosten: .nachhaltigkeit
        }
    }

    var title: String {
        switch self {
        case .reallohn: "Reallohn"
        case .inflationsrate: "Inflationsrate"
        case .kuendigungsfrist: "Kündigungsfrist"
        case .jugendurlaub: "Jugendurlaub"
        case .urlaubstage: "Urlaubstage"
        case .betriebsrat: "Betriebsratsgröße"
        case .svanteil: "Sozialversicherung"
        case .nettolohn: "Nettolohn"
        case .produktivitaet: "Produktivität"
        case .wirtschaftlichkeit: "Wirtschaftlichkeit"
        case .rentabilitaet: "Rentabilität"
        case .zinsen: "Zinsrechnung"
        case .skonto: "Skonto & Rabatt"
        case .raid: "RAID-Kapazität"
        case .uebertragung: "Übertragungszeit"
        case .bildspeicher: "Bildspeicherbedarf"
        case .einheiten: "Speichereinheiten"
        case .subnetze: "Subnetzanzahl"
        case .usv: "USV-Scheinleistung"
        case .stromkosten: "Stromkosten"
        case .verfuegbarkeit: "Verfügbarkeit"
        }
    }

    func makeTask<RNG: RandomNumberGenerator>(using generator: inout RNG) -> ExamTask {
        switch self {
        case .reallohn: Self.makeReallohn(id: id, topic: topic, using: &generator)
        case .inflationsrate: Self.makeInflationsrate(id: id, topic: topic, using: &generator)
        case .kuendigungsfrist: Self.makeKuendigungsfrist(id: id, topic: topic, using: &generator)
        case .jugendurlaub: Self.makeJugendurlaub(id: id, topic: topic, using: &generator)
        case .urlaubstage: Self.makeUrlaubstage(id: id, topic: topic, using: &generator)
        case .betriebsrat: Self.makeBetriebsrat(id: id, topic: topic, using: &generator)
        case .svanteil: Self.makeSvanteil(id: id, topic: topic, using: &generator)
        case .nettolohn: Self.makeNettolohn(id: id, topic: topic, using: &generator)
        case .produktivitaet: Self.makeProduktivitaet(id: id, topic: topic, using: &generator)
        case .wirtschaftlichkeit: Self.makeWirtschaftlichkeit(id: id, topic: topic, using: &generator)
        case .rentabilitaet: Self.makeRentabilitaet(id: id, topic: topic, using: &generator)
        case .zinsen: Self.makeZinsen(id: id, topic: topic, using: &generator)
        case .skonto: Self.makeSkonto(id: id, topic: topic, using: &generator)
        case .raid: Self.makeRaid(id: id, topic: topic, using: &generator)
        case .uebertragung: Self.makeUebertragung(id: id, topic: topic, using: &generator)
        case .bildspeicher: Self.makeBildspeicher(id: id, topic: topic, using: &generator)
        case .einheiten: Self.makeEinheiten(id: id, topic: topic, using: &generator)
        case .subnetze: Self.makeSubnetze(id: id, topic: topic, using: &generator)
        case .usv: Self.makeUsv(id: id, topic: topic, using: &generator)
        case .stromkosten: Self.makeStromkosten(id: id, topic: topic, using: &generator)
        case .verfuegbarkeit: Self.makeVerfuegbarkeit(id: id, topic: topic, using: &generator)
        }
    }
}

// MARK: - Shared helpers

extension ExamCalculation {
    static let names = ["Aylin", "Jonas", "Mara", "Tom", "Lea", "Finn", "Nora", "Elif", "Kai", "Sema"]
    static let companies = ["NetzWerk Nord GmbH", "BüroTechnik Söhnke GmbH", "GrünLicht Systeme GmbH",
                            "Pixelwerk GmbH", "Hafenkontor AG", "Feinmechanik Bode GmbH"]

    /// German genitive form of a name, e.g. "Toms", but "Jonas'" for names already ending in s.
    static func genitive(_ name: String) -> String {
        name.hasSuffix("s") ? "\(name)’" : "\(name)s"
    }

    /// Builds a single-choice task from a correct value and candidate distractors.
    /// Distractors are deduplicated against the correct string and each other; if fewer
    /// than three remain, padded fallback values guarantee four unique options.
    static func choiceTask<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, prompt: String, correct: String, distractors: [String],
        explanation: String, using generator: inout RNG
    ) -> ExamTask {
        var options = [correct]
        for candidate in distractors {
            if options.count == 4 { break }
            if !options.contains(candidate) { options.append(candidate) }
        }
        var suffix = 1
        while options.count < 4 {
            let padded = "\(correct) (\(suffix))"
            if !options.contains(padded) { options.append(padded) }
            suffix += 1
        }
        let shuffled = options.shuffled(using: &generator)
        let solutionIndex = shuffled.firstIndex(of: correct)!
        return ExamTask(id: id, kind: .single, topic: topic, prompt: prompt, items: [],
                        options: shuffled, solution: [solutionIndex], explanation: explanation)
    }

    static func formatDuration(_ seconds: Double) -> String {
        if seconds >= 120 {
            let minutes = seconds / 60
            let decimals = minutes.rounded() == minutes ? 0 : 1
            return ExamNumber.format(minutes, decimals: decimals) + " min"
        }
        let decimals = seconds.rounded() == seconds ? 0 : 1
        return ExamNumber.format(seconds, decimals: decimals) + " s"
    }
}

// MARK: - WiSo

extension ExamCalculation {
    private static func makeReallohn<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let steps10 = stride(from: 5, through: 50, by: 5).map { $0 }
        let a10 = steps10.randomElement(using: &generator)!
        let b10 = steps10.randomElement(using: &generator)!
        let a = Double(a10) / 10.0
        let b = Double(b10) / 10.0
        let diff = Double(a10 - b10) / 10.0

        func describe(_ value: Double) -> String {
            if value > 0.05 { return "Der Reallohn steigt um ca. \(ExamNumber.format(value, decimals: 1)) %." }
            if value < -0.05 { return "Der Reallohn sinkt um ca. \(ExamNumber.format(abs(value), decimals: 1)) %." }
            return "Der Reallohn bleibt (näherungsweise) gleich."
        }

        let correct = describe(diff)
        let distractors = [describe(-diff), describe(Double(a10 + b10) / 10.0), describe(a), describe(-b)]
        let prompt = "Der Nominallohn eines Arbeitnehmers steigt um \(ExamNumber.format(a, decimals: 1)) %, " +
            "die Inflationsrate liegt im selben Zeitraum bei \(ExamNumber.format(b, decimals: 1)) %. " +
            "Wie verändert sich der Reallohn näherungsweise?"
        let explanation = "Näherungsformel: Reallohnänderung ≈ Nominallohnänderung − Inflationsrate = " +
            "\(ExamNumber.format(a, decimals: 1)) % − \(ExamNumber.format(b, decimals: 1)) % = " +
            "\(ExamNumber.signedPercent(diff)). \(correct)"
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeInflationsrate<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let xs = stride(from: 100, through: 400, by: 20).map { $0 }
        let rates10 = [10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 100]
        let x = xs.randomElement(using: &generator)!
        let rate10 = rates10.randomElement(using: &generator)!
        let xD = Double(x)
        let y = xD + xD * Double(rate10) / 1000.0
        let correctRate = Double(rate10) / 10.0

        func percentString(_ value: Double) -> String { ExamNumber.format(value, decimals: 1) + " %" }

        let correct = percentString(correctRate)
        let avgBase = (xD + y) / 2
        let distractors = [
            percentString((y - xD) / y * 100),
            percentString((y - xD) / avgBase * 100),
            percentString(y - xD),
            percentString(correctRate + 1.0)
        ]
        let prompt = "Der Warenkorb kostete im Vorjahr \(ExamNumber.euro(xD)), aktuell kostet er " +
            "\(ExamNumber.euro(y)). Wie hoch ist die Inflationsrate?"
        let explanation = "Inflationsrate = (aktueller Preis − Vorjahrespreis) / Vorjahrespreis · 100 = " +
            "(\(ExamNumber.euro(y)) − \(ExamNumber.euro(xD))) / \(ExamNumber.euro(xD)) · 100 = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    static func noticePeriod(years: Int) -> String {
        switch years {
        case ..<2: return "4 Wochen zum 15. oder zum Ende eines Kalendermonats"
        case 2..<5: return "1 Monat zum Ende eines Kalendermonats"
        case 5..<8: return "2 Monate zum Ende eines Kalendermonats"
        case 8..<10: return "3 Monate zum Ende eines Kalendermonats"
        case 10..<12: return "4 Monate zum Ende eines Kalendermonats"
        case 12..<15: return "5 Monate zum Ende eines Kalendermonats"
        case 15..<20: return "6 Monate zum Ende eines Kalendermonats"
        default: return "7 Monate zum Ende eines Kalendermonats"
        }
    }

    private static let allNoticePeriods = [
        "2 Wochen", "4 Wochen zum 15. oder zum Ende eines Kalendermonats",
        "1 Monat zum Ende eines Kalendermonats", "2 Monate zum Ende eines Kalendermonats",
        "3 Monate zum Ende eines Kalendermonats", "4 Monate zum Ende eines Kalendermonats",
        "5 Monate zum Ende eines Kalendermonats", "6 Monate zum Ende eines Kalendermonats",
        "7 Monate zum Ende eines Kalendermonats"
    ]

    private static func makeKuendigungsfrist<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let years = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 25, 30]
            .randomElement(using: &generator)!
        let name = names.randomElement(using: &generator)!
        let company = companies.randomElement(using: &generator)!
        let variant = (0...2).randomElement(using: &generator)!

        let prompt: String
        let correct: String
        let explanation: String
        switch variant {
        case 0:
            correct = noticePeriod(years: years)
            prompt = "\(name) arbeitet seit \(years) Jahren bei der \(company). Der Arbeitgeber kündigt das " +
                "Arbeitsverhältnis ordentlich. Welche Kündigungsfrist gilt nach § 622 Abs. 2 BGB?"
            explanation = "Nach § 622 Abs. 2 BGB verlängert sich die vom Arbeitgeber einzuhaltende Frist mit der " +
                "Betriebszugehörigkeit. Bei \(years) Jahren gilt: \(correct)."
        case 1:
            correct = noticePeriod(years: 0)
            prompt = "\(name) kündigt sein/ihr Arbeitsverhältnis bei der \(company) nach \(years) Jahren " +
                "ordentlich. Welche Kündigungsfrist muss dabei eingehalten werden?"
            explanation = "Für die Kündigung durch Arbeitnehmer:innen gilt unabhängig von der " +
                "Betriebszugehörigkeit die Grundfrist des § 622 Abs. 1 BGB: \(correct). " +
                "Die verlängerten Fristen des Abs. 2 gelten nur für Kündigungen des Arbeitgebers."
        default:
            correct = "2 Wochen"
            prompt = "\(name) befindet sich noch in der vereinbarten Probezeit bei der \(company). Welche " +
                "Kündigungsfrist gilt während der Probezeit (sofern nichts anderes vereinbart ist)?"
            explanation = "Während einer vereinbarten Probezeit von bis zu 6 Monaten beträgt die " +
                "Kündigungsfrist nach § 622 Abs. 3 BGB nur \(correct), für beide Seiten."
        }
        let distractors = allNoticePeriods.filter { $0 != correct }.shuffled(using: &generator)
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct,
                          distractors: Array(distractors.prefix(3)), explanation: explanation, using: &generator)
    }

    static func youthVacation(ageAtYearStart: Int) -> Int {
        if ageAtYearStart < 16 { return 30 }
        if ageAtYearStart < 17 { return 27 }
        if ageAtYearStart < 18 { return 25 }
        return 24
    }

    private static let monthNames = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August",
                                     "September", "Oktober", "November", "Dezember"]

    private static func makeJugendurlaub<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let n = (15...19).randomElement(using: &generator)!
        let month = (2...12).randomElement(using: &generator)!
        let day = (1...28).randomElement(using: &generator)!
        let name = names.randomElement(using: &generator)!
        let company = companies.randomElement(using: &generator)!
        let ageAtYearStart = n - 1
        let correctDays = youthVacation(ageAtYearStart: ageAtYearStart)
        let correct = "\(correctDays) Werktage"
        let distractors = [30, 27, 25, 24].filter { $0 != correctDays }.map { "\($0) Werktage" }
        let prompt = "\(name), Auszubildende(r) bei der \(company), wird am \(day). \(monthNames[month - 1]) " +
            "\(n) Jahre alt. Wie viele Werktage Mindesturlaub stehen ihr/ihm in diesem Kalenderjahr laut " +
            "Gesetz mindestens zu?"
        let explanation = "Zu Beginn des Kalenderjahres ist \(name) noch \(ageAtYearStart) Jahre alt. Das " +
            "Jugendarbeitsschutzgesetz staffelt den Mindesturlaub: noch nicht 16 Jahre → 30 Werktage, noch " +
            "nicht 17 → 27 Werktage, noch nicht 18 → 25 Werktage, ab 18 gilt das Bundesurlaubsgesetz mit " +
            "24 Werktagen. Damit stehen \(name) \(correct) zu."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeUrlaubstage<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let xs = [12, 18, 24, 30, 36, 42, 48, 54, 60]
        let x = xs.randomElement(using: &generator)!
        let arbeitstage = x * 5 / 6
        let correct = "\(arbeitstage) Arbeitstage"
        let invertedRaw = Int((Double(x) * 6.0 / 5.0).rounded())
        let distractors = [
            "\(x) Arbeitstage",
            "\(invertedRaw) Arbeitstage",
            "\(max(arbeitstage - 6, 1)) Arbeitstage",
            "\(max(x - 6, 1)) Arbeitstage"
        ]
        let prompt = "Im Tarifvertrag sind \(x) Urlaubstage vereinbart (Werktage, Montag bis Samstag). Wie " +
            "viele Arbeitstage sind das bei einer üblichen 5-Tage-Woche?"
        let explanation = "Werktage (Mo–Sa) werden mit 5/6 auf Arbeitstage (5-Tage-Woche) umgerechnet: " +
            "\(x) · 5 / 6 = \(arbeitstage) Arbeitstage."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    static func councilSize(voters: Int) -> Int {
        switch voters {
        case ..<5: return 0
        case 5...20: return 1
        case 21...50: return 3
        case 51...100: return 5
        case 101...200: return 7
        case 201...400: return 9
        case 401...700: return 11
        case 701...1000: return 13
        default: return 15
        }
    }

    private static func makeBetriebsrat<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let sizePool = [1, 3, 5, 7, 9, 11, 13, 15]
        if Bool.random(using: &generator) {
            let n = (5...1500).randomElement(using: &generator)!
            let correctSize = councilSize(voters: n)
            let correct = "\(correctSize) Mitglieder"
            let distractors = sizePool.filter { $0 != correctSize }.shuffled(using: &generator).prefix(3)
                .map { "\($0) Mitglieder" }
            let prompt = "Ein Betrieb hat \(n) wahlberechtigte Arbeitnehmer:innen. Wie viele Mitglieder hat " +
                "der Betriebsrat nach § 9 BetrVG?"
            let explanation = "§ 9 BetrVG staffelt die Betriebsratsgröße nach der Zahl der wahlberechtigten " +
                "Arbeitnehmer:innen. Bei \(n) Wahlberechtigten besteht der Betriebsrat aus \(correctSize) Mitgliedern."
            return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct,
                              distractors: Array(distractors), explanation: explanation, using: &generator)
        } else {
            let u16 = (0...5).randomElement(using: &generator)!
            let age1617 = (5...30).randomElement(using: &generator)!
            let ab18 = (20...200).randomElement(using: &generator)!
            let wahlberechtigt = age1617 + ab18
            let total = u16 + age1617 + ab18
            let correctSize = councilSize(voters: wahlberechtigt)
            let correct = "\(correctSize) Mitglieder"
            var candidates = [councilSize(voters: total), councilSize(voters: ab18)]
                .filter { $0 != correctSize }.map { "\($0) Mitglieder" }
            candidates += sizePool.filter { $0 != correctSize }.map { "\($0) Mitglieder" }
            let prompt = "Ein Betrieb beschäftigt \(u16) Arbeitnehmer:innen unter 16 Jahren, \(age1617) im " +
                "Alter von 16 bis 17 Jahren und \(ab18) ab 18 Jahren. Wie viele Mitglieder hat der Betriebsrat " +
                "nach § 9 BetrVG?"
            let explanation = "Wahlberechtigt sind Arbeitnehmer:innen ab 16 Jahren, also \(age1617) + " +
                "\(ab18) = \(wahlberechtigt) von insgesamt \(total) Beschäftigten. Daraus ergeben sich nach " +
                "§ 9 BetrVG \(correct)."
            return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: candidates,
                              explanation: explanation, using: &generator)
        }
    }

    private static func makeSvanteil<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let bs = stride(from: 2000, through: 6000, by: 100).map { $0 }
        let b = Double(bs.randomElement(using: &generator)!)
        let correctValue = (b * 0.2115 * 100).rounded() / 100
        let distractorValues = [b * 0.423, b * 0.197, b * 0.1935]
        let correct = ExamNumber.euro(correctValue)
        let distractors = distractorValues.map { ExamNumber.euro(($0 * 100).rounded() / 100) }
        let prompt = "Bruttogehalt \(ExamNumber.euro(b)). Sozialversicherungssätze (Stand 2026, hälftige " +
            "Teilung zwischen Arbeitgeber und Arbeitnehmer): Rentenversicherung 18,6 %, " +
            "Arbeitslosenversicherung 2,6 %, Krankenversicherung 14,6 % zzgl. Zusatzbeitrag 2,9 %, " +
            "Pflegeversicherung 3,6 % (mit Kind). Wie hoch ist der Arbeitnehmeranteil?"
        let explanation = "Summe der Beitragssätze: 18,6 % + 2,6 % + 14,6 % + 2,9 % + 3,6 % = 42,3 %. Bei " +
            "hälftiger Teilung trägt die/der Arbeitnehmer:in 21,15 % von \(ExamNumber.euro(b)) = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeNettolohn<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let bs = stride(from: 2000, through: 5000, by: 100).map { $0 }
        let b = Double(bs.randomElement(using: &generator)!)
        let lstRate = [0.10, 0.12, 0.15, 0.18, 0.20].randomElement(using: &generator)!
        let lst = (b * lstRate).rounded()
        let kist = ((lst * 0.09) * 100).rounded() / 100
        let sv = ((b * 0.2115) * 100).rounded() / 100
        let netto = (((b - lst - kist - sv) * 100).rounded()) / 100
        let hasVorschuss = Bool.random(using: &generator)
        let name = names.randomElement(using: &generator)!

        if !hasVorschuss {
            let correct = ExamNumber.euro(netto)
            let candidates = [b - lst - sv, b - lst - kist, b - lst, b - kist - sv]
                .map { ExamNumber.euro(($0 * 100).rounded() / 100) }
            let prompt = "\(genitive(name)) Bruttogehalt beträgt \(ExamNumber.euro(b)). Abzüge: Lohnsteuer " +
                "\(ExamNumber.euro(lst)), Kirchensteuer \(ExamNumber.euro(kist)), " +
                "Sozialversicherungsanteil \(ExamNumber.euro(sv)). Wie hoch ist der Nettolohn?"
            let explanation = "Netto = Brutto − Lohnsteuer − Kirchensteuer − Sozialversicherung = " +
                "\(ExamNumber.euro(b)) − \(ExamNumber.euro(lst)) − \(ExamNumber.euro(kist)) − " +
                "\(ExamNumber.euro(sv)) = \(correct)."
            return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: candidates,
                              explanation: explanation, using: &generator)
        } else {
            let vorschuss = Double([100, 150, 200, 250, 300, 400, 500].randomElement(using: &generator)!)
            let auszahlung = (((netto - vorschuss) * 100).rounded()) / 100
            let correct = ExamNumber.euro(auszahlung)
            let candidates = [netto, netto + vorschuss, b - vorschuss]
                .map { ExamNumber.euro(($0 * 100).rounded() / 100) }
            let prompt = "\(genitive(name)) Bruttogehalt beträgt \(ExamNumber.euro(b)). Abzüge: Lohnsteuer " +
                "\(ExamNumber.euro(lst)), Kirchensteuer \(ExamNumber.euro(kist)), " +
                "Sozialversicherungsanteil \(ExamNumber.euro(sv)). Außerdem hat \(name) bereits einen " +
                "Vorschuss von \(ExamNumber.euro(vorschuss)) erhalten. Wie hoch ist der Auszahlungsbetrag?"
            let explanation = "Netto = \(ExamNumber.euro(b)) − \(ExamNumber.euro(lst)) − " +
                "\(ExamNumber.euro(kist)) − \(ExamNumber.euro(sv)) = \(ExamNumber.euro(netto)). Abzüglich " +
                "des Vorschusses von \(ExamNumber.euro(vorschuss)) ergibt sich der Auszahlungsbetrag " +
                "\(correct)."
            return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: candidates,
                              explanation: explanation, using: &generator)
        }
    }

    private static func makeProduktivitaet<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let hours = [10, 20, 25, 40, 50, 80, 100].randomElement(using: &generator)!
        let rate = [8, 10, 12, 15, 20, 24, 30, 40].randomElement(using: &generator)!
        let output = hours * rate
        let correct = "\(rate) Stück/h"
        let invertedRaw = Int((Double(hours) / Double(rate)).rounded())
        let distractors = ["\(hours) Stück/h", "\(output) Stück/h", "\(max(invertedRaw, 1)) Stück/h"]
        let prompt = "Ein Team produziert \(output) Stück in \(hours) Arbeitsstunden. Wie hoch ist die " +
            "Produktivität?"
        let explanation = "Produktivität = Ausbringungsmenge / Faktoreinsatzmenge = \(output) Stück / " +
            "\(hours) h = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeWirtschaftlichkeit<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let a = Double(stride(from: 1000, through: 20000, by: 500).map { $0 }.randomElement(using: &generator)!)
        let factor = [0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.2, 1.3].randomElement(using: &generator)!
        let e = (a * factor).rounded()
        let w = ((e / a) * 100).rounded() / 100
        let correct = ExamNumber.format(w, decimals: 2)
        let distractors = [a / e, (e - a) / a, w * 100].map { ExamNumber.format(($0 * 100).rounded() / 100, decimals: 2) }
        let prompt = "Ein Unternehmen hat einen Aufwand von \(ExamNumber.euro(a)) und einen Ertrag von " +
            "\(ExamNumber.euro(e)). Wie hoch ist die Wirtschaftlichkeit?"
        let explanation = "Wirtschaftlichkeit = Ertrag / Aufwand = \(ExamNumber.euro(e)) / " +
            "\(ExamNumber.euro(a)) = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeRentabilitaet<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let isEK = Bool.random(using: &generator)
        let v = Double(stride(from: 1000, through: 100_000, by: 1000).map { $0 }.randomElement(using: &generator)!)
        let rate = [2, 3, 4, 5, 6, 8, 10, 12, 15, 20].randomElement(using: &generator)!
        let g = (v * Double(rate) / 100).rounded()
        let correctRate = g / v * 100
        let correct = ExamNumber.format(correctRate, decimals: 1) + " %"
        let distractors = [
            ExamNumber.format((v / g * 100 * 100).rounded() / 100, decimals: 1) + " %",
            ExamNumber.format(((g / v) * 100).rounded() / 100, decimals: 1) + " %",
            ExamNumber.format(correctRate * 2, decimals: 1) + " %"
        ]
        let baseLabel = isEK ? "Eigenkapital" : "Umsatz"
        let metricLabel = isEK ? "Eigenkapitalrentabilität" : "Umsatzrentabilität"
        let prompt = "Ein Unternehmen erzielt einen Gewinn von \(ExamNumber.euro(g)) bei einem \(baseLabel) " +
            "von \(ExamNumber.euro(v)). Wie hoch ist die \(metricLabel)?"
        let explanation = "\(metricLabel) = Gewinn / \(baseLabel) · 100 = \(ExamNumber.euro(g)) / " +
            "\(ExamNumber.euro(v)) · 100 = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeZinsen<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let k = Double(stride(from: 500, through: 20000, by: 500).map { $0 }.randomElement(using: &generator)!)
        let p = [2, 3, 4, 5, 6, 8, 10].randomElement(using: &generator)!
        let t = [30, 60, 90, 120, 150, 180, 270, 360].randomElement(using: &generator)!
        let correctValue = k * Double(p) * Double(t) / 36000.0
        let correct = ExamNumber.euro((correctValue * 100).rounded() / 100)
        let candidates = [
            k * Double(p) * Double(t) / (100 * 365),
            k * Double(p) * Double(t) / 360,
            k * Double(p) * Double(t) / (100 * 30)
        ]
        let distractors = candidates.map { ExamNumber.euro(($0 * 100).rounded() / 100) }
        let prompt = "Ein Kapital von \(ExamNumber.euro(k)) wird für \(t) Tage mit \(p) % p. a. verzinst " +
            "(kaufmännische Zinsrechnung, Zinsjahr = 360 Tage). Wie hoch sind die Zinsen?"
        let explanation = "Zinsen = Kapital · Zinssatz · Tage / (100 · 360) = \(ExamNumber.euro(k)) · \(p) · " +
            "\(t) / 36000 = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeSkonto<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let l = Double(stride(from: 500, through: 5000, by: 250).map { $0 }.randomElement(using: &generator)!)
        let r = [5, 10, 15, 20, 25, 30].randomElement(using: &generator)!
        let s = [1, 2, 3].randomElement(using: &generator)!
        let zwischen = l * (1 - Double(r) / 100)
        let correctValue = zwischen * (1 - Double(s) / 100)
        let correct = ExamNumber.euro((correctValue * 100).rounded() / 100)
        let candidates = [zwischen, l * (1 - Double(s) / 100), l * (1 - Double(r + s) / 100)]
        let distractors = candidates.map { ExamNumber.euro(($0 * 100).rounded() / 100) }
        let prompt = "Listenpreis \(ExamNumber.euro(l)), Rabatt \(r) %, Skonto \(s) %. Wie hoch ist der " +
            "Überweisungsbetrag, wenn Rabatt und Skonto nacheinander abgezogen werden?"
        let explanation = "Nach Rabatt: \(ExamNumber.euro(l)) · (1 − \(r)/100) = \(ExamNumber.euro(zwischen)). " +
            "Nach Skonto: \(ExamNumber.euro(zwischen)) · (1 − \(s)/100) = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }
}

// MARK: - IT

extension ExamCalculation {
    static func raidCapacity(level: Int, disks: Int, size: Double) -> Double {
        switch level {
        case 0: return Double(disks) * size
        case 1: return size
        case 5: return Double(max(disks - 1, 0)) * size
        case 6: return Double(max(disks - 2, 0)) * size
        case 10: return Double(disks / 2) * size
        default: return 0
        }
    }

    private static func formatTB(_ value: Double) -> String {
        let decimals = value.rounded() == value ? 0 : 1
        return ExamNumber.format(value, decimals: decimals) + " TB"
    }

    private static func makeRaid<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let level = [0, 1, 5, 6, 10].randomElement(using: &generator)!
        let size = [0.5, 1, 2, 4, 8].randomElement(using: &generator)!
        let disks: Int
        switch level {
        case 0: disks = (2...8).randomElement(using: &generator)!
        case 1: disks = 2
        case 5: disks = (3...8).randomElement(using: &generator)!
        case 6: disks = (4...8).randomElement(using: &generator)!
        default: disks = [4, 6, 8].randomElement(using: &generator)!
        }
        let correctValue = raidCapacity(level: level, disks: disks, size: size)
        let correct = formatTB(correctValue)
        let candidates = [Double(disks) * size, Double(max(disks - 1, 0)) * size, size, Double(disks / 2) * size]
            .filter { $0 != correctValue }
        let distractors = candidates.map { formatTB($0) }
        let prompt = "Ein RAID \(level)-Verbund besteht aus \(disks) Festplatten à \(formatTB(size)). Wie " +
            "groß ist die nutzbare Kapazität?"
        let explanation: String
        switch level {
        case 0: explanation = "RAID 0 nutzt alle Platten ohne Redundanz: \(disks) · \(formatTB(size)) = \(correct)."
        case 1: explanation = "RAID 1 spiegelt die Daten, die nutzbare Kapazität entspricht einer Platte: \(correct)."
        case 5: explanation = "RAID 5 verteilt die Parität über eine Platte: (\(disks) − 1) · \(formatTB(size)) = \(correct)."
        case 6: explanation = "RAID 6 verteilt die Parität über zwei Platten: (\(disks) − 2) · \(formatTB(size)) = \(correct)."
        default: explanation = "RAID 10 spiegelt Paare und stripet darüber: \(disks) / 2 · \(formatTB(size)) = \(correct)."
        }
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeUebertragung<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let xs = [8, 16, 20, 25, 32, 40, 50, 64, 80, 100, 125, 160, 200, 250, 400, 500, 1000]
        let gbs = [1, 2, 4, 5, 8, 10, 16, 20, 25, 40, 50, 80, 100]
        var x = xs.randomElement(using: &generator)!
        var gb = gbs.randomElement(using: &generator)!
        var raw = Double(gb) * 8000.0 / Double(x)
        var attempts = 0
        while raw != raw.rounded() && attempts < 30 {
            x = xs.randomElement(using: &generator)!
            gb = gbs.randomElement(using: &generator)!
            raw = Double(gb) * 8000.0 / Double(x)
            attempts += 1
        }
        let correct = formatDuration(raw)
        let d1 = Double(gb) * 1000.0 / Double(x)
        let d2 = raw * 8
        let d3 = Double(gb) * 8000.0 / Double(x) * 1.024
        let distractors = [d1, d2, d3].map { formatDuration($0) }
        let prompt = "Eine Datei mit \(gb) GB (dezimal) wird über eine Verbindung mit \(x) Mbit/s " +
            "übertragen. Wie lange dauert die Übertragung?"
        let explanation = "Zeit = Datenmenge in Bit / Übertragungsrate = \(gb) GB · 8000 Mbit/GB / \(x) " +
            "Mbit/s = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeBildspeicher<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let w = [320, 640, 800, 1024, 1280, 1920, 2560, 3840].randomElement(using: &generator)!
        let h = [240, 480, 600, 768, 1080, 1440, 2160].randomElement(using: &generator)!
        let bits = [8, 16, 24, 32].randomElement(using: &generator)!
        let bytes = Double(w * h * bits) / 8.0
        let useMiB = Bool.random(using: &generator)
        let divisor = useMiB ? 1_048_576.0 : 1_000_000.0
        let unit = useMiB ? "MiB" : "MB (dezimal)"
        let correctValue = (bytes / divisor * 100).rounded() / 100
        let correct = ExamNumber.format(correctValue, decimals: 2) + " " + unit
        let otherDivisor = useMiB ? 1_000_000.0 : 1_048_576.0
        let candidates = [bytes / otherDivisor, bytes * 8 / divisor, Double(w * h) / divisor]
        let distractors = candidates.map { ExamNumber.format(($0 * 100).rounded() / 100, decimals: 2) + " " + unit }
        let prompt = "Ein unkomprimiertes Bild hat eine Auflösung von \(w) × \(h) Pixeln bei einer Farbtiefe " +
            "von \(bits) Bit pro Pixel. Wie groß ist der Speicherbedarf in \(unit)?"
        let explanation = "Speicherbedarf = Breite · Höhe · Farbtiefe / 8 = \(w) · \(h) · \(bits) / 8 = " +
            "\(ExamNumber.format(bytes, decimals: 0)) Byte = \(correct) (1 \(useMiB ? "MiB = 2^20 Byte" : "MB = 1.000.000 Byte"))."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeEinheiten<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let recipe = (0...5).randomElement(using: &generator)!
        let prompt: String
        let correct: String
        let distractors: [String]
        let explanation: String

        switch recipe {
        case 0:
            let n = (1...20).randomElement(using: &generator)!
            let value = Double(n) * 1_000_000_000_000.0 / 1_073_741_824.0
            let rounded = (value * 100).rounded() / 100
            correct = ExamNumber.format(rounded, decimals: 2) + " GiB"
            distractors = [Double(n) * 1000.0, value * 1.024, value / 1.024]
                .map { ExamNumber.format(($0 * 100).rounded() / 100, decimals: 2) + " GiB" }
            prompt = "Wandle \(n) TB (dezimal) in GiB um (Ergebnis auf 2 Nachkommastellen gerundet)."
            explanation = "\(n) TB = \(n) · 10^12 Byte, 1 GiB = 2^30 Byte. \(n) · 10^12 / 2^30 ≈ \(correct)."
        case 1:
            let n = (1...16).randomElement(using: &generator)!
            let value = Double(n) * 1_073_741_824.0
            correct = ExamNumber.format(value, decimals: 0) + " Byte"
            distractors = [Double(n) * 1_000_000_000.0, Double(n) * 1_048_576.0, value * 8]
                .map { ExamNumber.format($0, decimals: 0) + " Byte" }
            prompt = "Wandle \(n) GiB exakt in Byte um."
            explanation = "1 GiB = 2^30 Byte = 1.073.741.824 Byte. \(n) GiB = \(n) · 1.073.741.824 Byte = \(correct)."
        case 2:
            let n = (1...50).randomElement(using: &generator)!
            let value = Double(n) * 1_000_000_000.0 / 1_048_576.0
            let rounded = (value * 100).rounded() / 100
            correct = ExamNumber.format(rounded, decimals: 2) + " MiB"
            distractors = [Double(n) * 1000.0, value * 1.024, value / 1.024]
                .map { ExamNumber.format(($0 * 100).rounded() / 100, decimals: 2) + " MiB" }
            prompt = "Wandle \(n) GB (dezimal) in MiB um (Ergebnis auf 2 Nachkommastellen gerundet)."
            explanation = "\(n) GB = \(n) · 10^9 Byte, 1 MiB = 2^20 Byte. \(n) · 10^9 / 2^20 ≈ \(correct)."
        case 3:
            let n = (1...500).randomElement(using: &generator)!
            let value = n * 1024
            correct = ExamNumber.whole(value) + " KiB"
            distractors = [n * 1000, n * 1024 * 8, max(n / 1024, 1)]
                .map { ExamNumber.whole($0) + " KiB" }
            prompt = "Wandle \(n) MiB exakt in KiB um."
            explanation = "1 MiB = 1024 KiB. \(n) MiB = \(n) · 1024 KiB = \(correct)."
        case 4:
            let n = (1...900).randomElement(using: &generator)!
            let value = n * 1000
            correct = ExamNumber.whole(value) + " Byte"
            distractors = [n * 1024, n * 100, n]
                .map { ExamNumber.whole($0) + " Byte" }
            prompt = "Wandle \(n) KB (dezimal) exakt in Byte um."
            explanation = "1 KB = 1000 Byte (dezimal). \(n) KB = \(n) · 1000 Byte = \(correct)."
        default:
            let n = (1...9).randomElement(using: &generator)!
            let value = n * 1000
            correct = ExamNumber.whole(value) + " GB"
            distractors = [Int((Double(n) * 1_000_000_000_000.0 / 1_073_741_824.0 / 1_048_576.0 * 1000).rounded()), n * 1024, n]
                .map { ExamNumber.whole($0) + " GB" }
            prompt = "Wandle \(n) TB (dezimal) exakt in GB (dezimal) um."
            explanation = "1 TB = 1000 GB (dezimal). \(n) TB = \(n) · 1000 GB = \(correct)."
        }
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeSubnetze<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        if Bool.random(using: &generator) {
            let a = (16...27).randomElement(using: &generator)!
            let delta = (1...min(8, 30 - a)).randomElement(using: &generator)!
            let b = a + delta
            let count = 1 << delta
            let correct = ExamNumber.whole(count)
            let altDelta = delta > 1 ? delta - 1 : delta + 1
            let candidates = [1 << altDelta, 1 << (delta + 1), delta]
            let distractors = candidates.map { ExamNumber.whole($0) }
            let prompt = "Ein Netz mit dem Präfix /\(a) wird in gleich große Subnetze mit dem Präfix /\(b) " +
                "aufgeteilt. Wie viele Subnetze entstehen?"
            let explanation = "Anzahl Subnetze = 2^(neues Präfix − altes Präfix) = 2^(\(b) − \(a)) = " +
                "2^\(delta) = \(correct)."
            return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                              explanation: explanation, using: &generator)
        } else {
            let pairs = [(48, 64), (48, 56), (56, 64), (32, 48), (40, 56)]
            let (a, b) = pairs.randomElement(using: &generator)!
            let delta = b - a
            let count = 1 << delta
            let correct = ExamNumber.whole(count)
            let altDelta = delta > 1 ? delta - 1 : delta + 1
            let candidates = [1 << altDelta, 1 << (delta + 1), delta]
            let distractors = candidates.map { ExamNumber.whole($0) }
            let prompt = "Ein IPv6-Netz mit dem Präfix /\(a) wird in gleich große Subnetze mit dem Präfix " +
                "/\(b) aufgeteilt. Wie viele Subnetze entstehen?"
            let explanation = "Anzahl Subnetze = 2^(neues Präfix − altes Präfix) = 2^(\(b) − \(a)) = " +
                "2^\(delta) = \(correct)."
            return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                              explanation: explanation, using: &generator)
        }
    }

    private static func makeUsv<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let p = Double([100, 200, 300, 500, 750, 1000, 1500, 2000].randomElement(using: &generator)!)
        let cosphi = [0.5, 0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95].randomElement(using: &generator)!
        let s = p / cosphi
        let correct = ExamNumber.format((s * 10).rounded() / 10, decimals: 1) + " VA"
        let candidates = [p * cosphi, p, p / (1 - cosphi)]
        let distractors = candidates.map { ExamNumber.format(($0 * 10).rounded() / 10, decimals: 1) + " VA" }
        let prompt = "Ein Server benötigt eine Wirkleistung von \(ExamNumber.format(p, decimals: 0)) W bei " +
            "einem Leistungsfaktor cos φ = \(ExamNumber.format(cosphi, decimals: 2)). Wie groß muss die " +
            "Scheinleistung der USV mindestens sein?"
        let explanation = "Scheinleistung = Wirkleistung / cos φ = \(ExamNumber.format(p, decimals: 0)) W / " +
            "\(ExamNumber.format(cosphi, decimals: 2)) = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeStromkosten<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let p = Double([50, 100, 150, 200, 300, 500, 750, 1000, 1500, 2000, 3000].randomElement(using: &generator)!)
        let h = Double([1, 2, 3, 4, 6, 8, 10, 12, 16, 24].randomElement(using: &generator)!)
        let d = Double([1, 7, 30, 90, 180, 365].randomElement(using: &generator)!)
        let ct = Double([25, 28, 30, 32, 35, 38, 40, 42, 45].randomElement(using: &generator)!)
        let kwh = p / 1000 * h * d
        let cost = kwh * ct / 100
        let correct = ExamNumber.euro((cost * 100).rounded() / 100)
        let candidates = [p * h * d * ct / 100, kwh * ct, (p / 1000 * h) * ct / 100]
        let distractors = candidates.map { ExamNumber.euro(($0 * 100).rounded() / 100) }
        let prompt = "Ein Gerät mit \(ExamNumber.format(p, decimals: 0)) W läuft " +
            "\(ExamNumber.format(h, decimals: 0)) Stunden täglich an " +
            "\(ExamNumber.format(d, decimals: 0)) Tagen. Der Strompreis beträgt " +
            "\(ExamNumber.format(ct, decimals: 0)) ct/kWh. Wie hoch sind die Stromkosten?"
        let explanation = "Energie = Leistung / 1000 · Stunden · Tage = \(ExamNumber.format(p, decimals: 0)) " +
            "W / 1000 · \(ExamNumber.format(h, decimals: 0)) h · \(ExamNumber.format(d, decimals: 0)) = " +
            "\(ExamNumber.format(kwh, decimals: 2)) kWh. Kosten = \(ExamNumber.format(kwh, decimals: 2)) kWh " +
            "· \(ExamNumber.format(ct, decimals: 0)) ct / 100 = \(correct)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correct, distractors: distractors,
                          explanation: explanation, using: &generator)
    }

    private static func makeVerfuegbarkeit<RNG: RandomNumberGenerator>(
        id: String, topic: ExamTopic, using generator: inout RNG
    ) -> ExamTask {
        let slaOptions: [(value: Double, decimals: Int)] = [
            (90.0, 0), (95.0, 0), (98.0, 0), (99.0, 0), (99.5, 1), (99.8, 1),
            (99.9, 1), (99.95, 2), (99.99, 2), (99.999, 3)
        ]
        let (sla, slaDecimals) = slaOptions.randomElement(using: &generator)!
        let minutesPerYear = 365.0 * 24.0 * 60.0
        let downMinutes = minutesPerYear * (1 - sla / 100)
        // formatDuration expects seconds, so convert the downtime (in minutes) to seconds first.
        let correctSeconds = downMinutes * 60
        let correctFormatted = formatDuration(correctSeconds)
        let d360 = 360.0 * 24.0 * 60.0 * (1 - sla / 100) * 60
        let dWrongFraction = minutesPerYear * (sla / 100) * 60
        let dMonth = 30.0 * 24.0 * 60.0 * (1 - sla / 100) * 60
        let distractors = [d360, dWrongFraction, dMonth].map { formatDuration($0) }
        let slaText = ExamNumber.format(sla, decimals: slaDecimals)
        let prompt = "Ein SLA garantiert eine Verfügbarkeit von \(slaText) % im Jahr (365 Tage). Wie hoch " +
            "ist die maximal zulässige Ausfallzeit pro Jahr?"
        let explanation = "Ausfallzeit = 365 Tage · 24 h · (1 − \(slaText)/100) = " +
            "\(ExamNumber.format(downMinutes, decimals: 1)) min = \(correctFormatted)."
        return choiceTask(id: id, topic: topic, prompt: prompt, correct: correctFormatted,
                          distractors: distractors, explanation: explanation, using: &generator)
    }
}
