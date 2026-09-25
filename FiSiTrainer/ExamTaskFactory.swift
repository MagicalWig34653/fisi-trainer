// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Builds playable tasks from the authored catalog and the calculation generators.
enum ExamTaskFactory {
    static let trueLabel = "Richtig"
    static let falseLabel = "Falsch"

    /// Catalog entries that a mode can use. Calculations come from generators instead.
    static func cards(for mode: ExamMode, subject: ExamSubject, topic: ExamTopic?,
                      catalog: [ExamCard] = ExamCatalog.all) -> [ExamCard] {
        catalog.filter { card in
            guard card.topic.subject == subject, topic == nil || card.topic == topic else { return false }
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
                               catalog: [ExamCard] = ExamCatalog.all) -> Int {
        switch mode {
        case .calc: calculations(subject: subject, topic: topic).count
        case .exam: cards(for: .quiz, subject: subject, topic: nil, catalog: catalog).count
        default: cards(for: mode, subject: subject, topic: topic, catalog: catalog).count
        }
    }

    static func makeRound<RNG: RandomNumberGenerator>(
        mode: ExamMode, subject: ExamSubject, topic: ExamTopic?,
        catalog: [ExamCard] = ExamCatalog.all, using generator: inout RNG,
        weight: (String) -> Double
    ) -> [ExamTask] {
        switch mode {
        case .calc:
            return calculationTasks(count: mode.roundLength, subject: subject, topic: topic,
                                    using: &generator, weight: weight)
        case .exam:
            return examTasks(subject: subject, catalog: catalog, using: &generator, weight: weight)
        default:
            let pool = cards(for: mode, subject: subject, topic: topic, catalog: catalog)
            let selected = AdaptiveLearning.weightedSample(pool, count: mode.roundLength,
                                                           using: &generator) { weight($0.id) }
            return selected.compactMap { task(from: $0, catalog: catalog, using: &generator) }
        }
    }

    private static func examTasks<RNG: RandomNumberGenerator>(
        subject: ExamSubject, catalog: [ExamCard], using generator: inout RNG,
        weight: (String) -> Double
    ) -> [ExamTask] {
        let plan: [(ExamMode, Int)] = [(.multiple, 3), (.match, 3), (.order, 2), (.calc, 4)]
        var tasks: [ExamTask] = []
        for (mode, count) in plan {
            if mode == .calc {
                tasks += calculationTasks(count: count, subject: subject, topic: nil,
                                          using: &generator, weight: weight)
            } else {
                let pool = cards(for: mode, subject: subject, topic: nil, catalog: catalog)
                tasks += AdaptiveLearning.weightedSample(pool, count: count, using: &generator) {
                    weight($0.id)
                }.compactMap { task(from: $0, catalog: catalog, using: &generator) }
            }
        }
        let choices = cards(for: .quiz, subject: subject, topic: nil, catalog: catalog)
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
