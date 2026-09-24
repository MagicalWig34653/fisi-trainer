// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import SwiftUI

/// A question keeps running against wall-clock time, including while the app is closed.
struct QuestionTiming: Codable {
    let startedAt: Date
    var answeredAt: Date? = nil
    var earnedBonus: Int? = nil

    func elapsed(at date: Date) -> TimeInterval {
        let interval = date.timeIntervalSince(startedAt)
        return interval.isFinite ? max(0, interval) : 0
    }

    func availableBonus(at date: Date) -> Int { Self.bonus(for: elapsed(at: date)) }

    static func bonus(for elapsed: TimeInterval) -> Int {
        guard elapsed.isFinite else { return 0 }
        let safeElapsed = max(0, elapsed)
        if safeElapsed <= 10 { return 15 }
        if safeElapsed <= 20 { return 10 }
        if safeElapsed <= 30 { return 5 }
        return 0
    }

    var isValid: Bool {
        guard startedAt.timeIntervalSinceReferenceDate.isFinite else { return false }
        if let answeredAt {
            guard answeredAt.timeIntervalSinceReferenceDate.isFinite,
                  answeredAt >= startedAt else { return false }
        }
        return earnedBonus == nil || [0, 5, 10, 15].contains(earnedBonus!)
    }
}

struct QuestionTimerView: View {
    let timing: QuestionTiming
    let answered: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let date = answered ? (timing.answeredAt ?? context.date) : context.date
            let seconds = Int(min(ceil(timing.elapsed(at: date)), 359_999))
            let bonus = answered ? (timing.earnedBonus ?? 0) : timing.availableBonus(at: date)
            HStack(spacing: 12) {
                Label(String(format: "%02d:%02d", seconds / 60, seconds % 60),
                      systemImage: "timer")
                Text(answered ? "+\(bonus) Tempo-XP" : "+\(bonus) Tempo-XP möglich")
            }
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .accessibilityElement(children: .combine)
            .help("Tempo-XP: +15 bis 10 s, +10 bis 20 s, +5 bis 30 s. " +
                  "Die Zeit läuft auch weiter, wenn du die App schließt.")
        }
    }
}
