// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Builds playable tasks from the authored catalog and the calculation generators.
enum ExamTaskFactory {
    static let trueLabel = "Richtig"
    static let falseLabel = "Falsch"

    /// Catalog entries that a mode can use. Calculations come from generators instead.
    static func cards(for mode: ExamMode, subject: ExamSubject, topic: ExamTopic?,
                      catalog: [ExamCard] = ExamCatalog.all,
                      filter: ExamOriginFilter = .all) -> [ExamCard] {
        catalog.filter { card in
            guard card.topic.subject == subject, topic == nil || card.topic == topic,
                  filter.allows(card.origin) else { return false }
            switch (mode, card) {
            case (.quiz, .choice), (.truefalse, .statement), (.multiple, .multiple),
                 (.match, .match), (.order, .order), (.gap, .gap), (.facts, .fact): return true
            default: return false
            }
        }
    }

    static func calculations(subject: ExamSubject, topic: ExamTopic?) -> [ExamCalculation] {
        ExamCalculation.allCases.filter {
            $0.topic.subject == subject && (topic == nil || $0.topic == topic)
        }
    }

    /// Number of different tasks a mode can offer; zero means the mode is unavailable.
    static func availableCount(for mode: ExamMode, subject: ExamSubject, topic: ExamTopic?,
                               catalog: [ExamCard] = ExamCatalog.all,
                               filter: ExamOriginFilter = .all) -> Int {
        switch mode {
        case .calc: calculations(subject: subject, topic: topic).count
        case .exam: cards(for: .quiz, subject: subject, topic: nil, catalog: catalog, filter: filter).count
        default: cards(for: mode, subject: subject, topic: topic, catalog: catalog, filter: filter).count
        }
    }

    static func makeRound<RNG: RandomNumberGenerator>(
        mode: ExamMode, subject: ExamSubject, topic: ExamTopic?,
        catalog: [ExamCard] = ExamCatalog.all, filter: ExamOriginFilter = .all,
        using generator: inout RNG,
        weight: (String) -> Double
    ) -> [ExamTask] {
        switch mode {
        case .calc:
            return calculationTasks(count: mode.roundLength, subject: subject, topic: topic,
                                    using: &generator, weight: weight)
        case .exam:
            return examTasks(subject: subject, catalog: catalog, filter: filter, using: &generator, weight: weight)
        default:
            let pool = cards(for: mode, subject: subject, topic: topic, catalog: catalog, filter: filter)
            let selected = AdaptiveLearning.weightedSample(pool, count: mode.roundLength,
                                                           using: &generator) { weight($0.id) }
            return selected.compactMap { task(from: $0, catalog: catalog, using: &generator) }
        }
    }

    private static func examTasks<RNG: RandomNumberGenerator>(
        subject: ExamSubject, catalog: [ExamCard], filter: ExamOriginFilter, using generator: inout RNG,
        weight: (String) -> Double
    ) -> [ExamTask] {
        let plan: [(ExamMode, Int)] = [(.multiple, 3), (.match, 3), (.order, 2), (.calc, 4)]
        var tasks: [ExamTask] = []
        for (mode, count) in plan {
            if mode == .calc {
                tasks += calculationTasks(count: count, subject: subject, topic: nil,
                                          using: &generator, weight: weight)
            } else {
                let pool = cards(for: mode, subject: subject, topic: nil, catalog: catalog, filter: filter)
                tasks += AdaptiveLearning.weightedSample(pool, count: count, using: &generator) {
                    weight($0.id)
                }.compactMap { task(from: $0, catalog: catalog, using: &generator) }
            }
        }
        let choices = cards(for: .quiz, subject: subject, topic: nil, catalog: catalog, filter: filter)
        tasks += AdaptiveLearning.weightedSample(choices, count: ExamMode.exam.roundLength - tasks.count,
                                                 using: &generator) { weight($0.id) }
            .compactMap { task(from: $0, catalog: catalog, using: &generator) }
        return tasks.shuffled(using: &generator)
    }

    static func calculationTasks<RNG: RandomNumberGenerator>(
        count: Int, subject: ExamSubject, topic: ExamTopic?, using generator: inout RNG,
        weight: (String) -> Double
    ) -> [ExamTask] {
        let pool = calculations(subject: subject, topic: topic)
        guard !pool.isEmpty else { return [] }
        var kinds: [ExamCalculation] = []
        // Prefer different calculation types; repeat with fresh numbers only when needed.
        while kinds.count < count {
            kinds += AdaptiveLearning.weightedSample(pool, count: count - kinds.count,
                                                     using: &generator) { weight($0.id) }
        }
        return kinds.map { $0.makeTask(using: &generator) }
    }

    static func task<RNG: RandomNumberGenerator>(from card: ExamCard, catalog: [ExamCard] = ExamCatalog.all,
                                                using generator: inout RNG) -> ExamTask? {
        switch card {
        case let .choice(id, topic, prompt, options, explanation):
            let shuffled = Array(options.indices).shuffled(using: &generator)
            return ExamTask(id: id, kind: .single, topic: topic, prompt: prompt, items: [],
                            options: shuffled.map { options[$0] },
                            solution: [shuffled.firstIndex(of: 0)!], explanation: explanation)
        case let .statement(id, topic, text, isTrue, explanation):
            return ExamTask(id: id, kind: .single, topic: topic, prompt: text, items: [],
                            options: [trueLabel, falseLabel], solution: [isTrue ? 0 : 1],
                            explanation: explanation)
        case let .multiple(id, topic, prompt, correct, wrong, explanation):
            let options = (correct + wrong).shuffled(using: &generator)
            let solution = options.indices.filter { correct.contains(options[$0]) }
            return ExamTask(id: id, kind: .multiple, topic: topic, prompt: prompt, items: [],
                            options: options, solution: solution, explanation: explanation)
        case let .match(id, topic, prompt, pairs, extra, explanation):
            let order = Array(pairs.indices).shuffled(using: &generator)
            var labels: [String] = []
            for (_, right) in pairs where !labels.contains(right) { labels.append(right) }
            labels += extra.filter { !labels.contains($0) }
            return ExamTask(id: id, kind: .match, topic: topic, prompt: prompt,
                            items: order.map { pairs[$0].0 }, options: labels,
                            solution: order.map { labels.firstIndex(of: pairs[$0].1)! },
                            explanation: explanation)
        case let .order(id, topic, prompt, steps, explanation):
            var shuffled = Array(steps.indices).shuffled(using: &generator)
            if shuffled == Array(steps.indices) { shuffled.reverse() }
            return ExamTask(id: id, kind: .order, topic: topic, prompt: prompt,
                            items: shuffled.map { steps[$0] }, options: [],
                            solution: steps.indices.map { shuffled.firstIndex(of: $0)! },
                            explanation: explanation)
        case let .gap(id, topic, title, sentences, extra, explanation):
            var words: [String] = []
            for (_, word) in sentences where !words.contains(word) { words.append(word) }
            words = (words + extra.filter { !words.contains($0) }).shuffled(using: &generator)
            return ExamTask(id: id, kind: .match, topic: topic,
                            prompt: "\(title) – Setze die passenden Begriffe ein.",
                            items: sentences.map(\.0), options: words,
                            solution: sentences.map { words.firstIndex(of: $0.1)! },
                            explanation: explanation)
        case let .fact(id, topic, group, question, answer, explanation):
            var others: [String] = []
            for other in catalog.shuffled(using: &generator) {
                guard case let .fact(_, otherTopic, otherGroup, _, otherAnswer, _) = other,
                      otherGroup == group, otherTopic.subject == topic.subject,
                      otherAnswer != answer, !others.contains(otherAnswer) else { continue }
                others.append(otherAnswer)
                if others.count == 3 { break }
            }
            guard others.count == 3 else { return nil }
            let options = ([answer] + others).shuffled(using: &generator)
            return ExamTask(id: id, kind: .single, topic: topic, prompt: question, items: [],
                            options: options, solution: [options.firstIndex(of: answer)!],
                            explanation: explanation)
        }
    }
}

/// German number formatting for generated calculations.
enum ExamNumber {
    /// Cached formatters for the common 0...4 fraction digit counts, avoiding a fresh
    /// `NumberFormatter` on every call. Any other decimal count falls back to a fresh formatter.
    private static let cachedFormatters: [NumberFormatter] = (0...4).map(makeFormatter)

    private static func makeFormatter(decimals: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.roundingMode = .halfUp
        return formatter
    }

    static func format(_ value: Double, decimals: Int = 2) -> String {
        let formatter = cachedFormatters.indices.contains(decimals)
            ? cachedFormatters[decimals] : makeFormatter(decimals: decimals)
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func euro(_ value: Double) -> String { format(value) + " €" }

    static func whole(_ value: Int) -> String { format(Double(value), decimals: 0) }

    static func signedPercent(_ value: Double, decimals: Int = 1) -> String {
        (value > 0 ? "+" : value < 0 ? "−" : "±") + format(abs(value), decimals: decimals) + " %"
    }
}

/// Zahleneingabe statt Auswahl bei Rechenaufgaben: liest Wert und Einheit der richtigen Option
/// ("1.234,56 €", "12,5 %", "4,8 TB") und prüft eine getippte Antwort mit Rundungstoleranz und Einheit.
struct ExamNumericAnswer: Equatable {
    enum Verdict: Equatable { case correct, wrong, invalid }

    let value: Double
    let unit: String
    private(set) var decimals: Int

    /// Halber Schritt der letzten angezeigten Stelle: Wer exakt rechnet und rundet, trifft die Lösung.
    var tolerance: Double { 0.5 * pow(10, -Double(decimals)) + 1e-9 }

    /// Nur Optionen, die ausschließlich aus Zahl und kurzer Einheit bestehen, sind eintippbar.
    init?(option text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let (number, rest) = Self.splitNumber(trimmed)
        let unit = rest.trimmingCharacters(in: .whitespaces)
        guard let value = Self.parse(number), unit.count <= 8, !unit.contains(" "),
              !unit.contains(where: \.isNumber) else { return nil }
        self.value = value
        self.unit = unit
        let normalized = number.replacingOccurrences(of: ".", with: "")
        if let comma = normalized.firstIndex(of: ",") {
            decimals = normalized.distance(from: comma, to: normalized.endIndex) - 1
        } else {
            decimals = 0
        }
    }

    /// Trennt führende Zahl (mit Vorzeichen, Tausenderpunkt und Dezimalkomma) vom Rest.
    private static func splitNumber(_ text: String) -> (String, String) {
        let allowed = Set("0123456789.,+-−")
        let number = String(text.prefix { allowed.contains($0) })
        return (number, String(text.dropFirst(number.count)))
    }

    /// Liest deutsche und englische Schreibweise: "1.234,5", "1234,5", "1234.5", "1.234".
    static func parse(_ text: String) -> Double? {
        var t = text.replacingOccurrences(of: "−", with: "-").replacingOccurrences(of: " ", with: "")
        if t.hasPrefix("+") { t.removeFirst() }
        guard !t.isEmpty, t.contains(where: \.isNumber) else { return nil }
        if t.contains(",") {
            t = t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else if t.range(of: #"^-?\d{1,3}(\.\d{3})+$"#, options: .regularExpression) != nil {
            t = t.replacingOccurrences(of: ".", with: "")
        }
        return Double(t)
    }

    /// Eine getippte Antwort, optional mit Einheit. Eine andere als die erwartete Einheit ist falsch.
    func verdict(for input: String) -> Verdict {
        let (number, rest) = Self.splitNumber(input.trimmingCharacters(in: .whitespaces))
        guard let typed = Self.parse(number) else { return .invalid }
        let typedUnit = rest.trimmingCharacters(in: .whitespaces).lowercased()
        if !typedUnit.isEmpty, typedUnit != unit.lowercased() { return .wrong }
        return abs(typed - value) <= tolerance ? .correct : .wrong
    }

    /// Antwortindex für den `ExamStore`: die richtige Option, die passende falsche oder die erste falsche.
    static func answerIndex(for input: String, task: ExamTask) -> Int? {
        guard task.kind == .single, let solution = task.solution.first,
              task.options.indices.contains(solution),
              var expected = ExamNumericAnswer(option: task.options[solution]) else { return nil }
        // Die Toleranz richtet sich nach der feinsten Angabe aller Optionen, damit nahe Ablenker falsch bleiben.
        expected.decimals = task.options.compactMap { ExamNumericAnswer(option: $0)?.decimals }.max() ?? expected.decimals
        switch expected.verdict(for: input) {
        case .invalid: return nil
        case .correct: return solution
        case .wrong:
            let typed = input.trimmingCharacters(in: .whitespaces)
            let match = task.options.indices.first { index in
                index != solution && ExamNumericAnswer(option: task.options[index])?.verdict(for: typed) == .correct
            }
            return match ?? task.options.indices.first { $0 != solution }
        }
    }
}
