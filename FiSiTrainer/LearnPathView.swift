// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

private enum PathStyle {
    static let surface = Color(red: 0.078, green: 0.113, blue: 0.151)
    static let raised = Color(red: 0.103, green: 0.145, blue: 0.183)
    static let border = Color.white.opacity(0.085)
    static let primary = Color(red: 0.94, green: 0.97, blue: 0.96)
    static let muted = Color(red: 0.53, green: 0.61, blue: 0.64)
    static let accent = Color(red: 0.76, green: 0.97, blue: 0.32)
    static let flame = Color(red: 1.0, green: 0.62, blue: 0.25)
}

/// Lernpfad: Streak und Tagesziel oben, darunter je Fach die Themen mit ihren fünf Lektionen.
struct LearnPathView: View {
    @EnvironmentObject private var path: LearnPathStore
    @EnvironmentObject private var exam: ExamStore
    /// Wird mit dem Thema aufgerufen, wenn der Nutzer die nächste Lektion antippt.
    let onStart: (ExamTopic) -> Void
    /// Wird mit dem Fach aufgerufen, wenn der Nutzer die Wiederholung fälliger Karten startet.
    var onReview: (ExamSubject) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            ForEach(ExamSubject.allCases) { subject in
                VStack(alignment: .leading, spacing: 12) {
                    Text(subject.title.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(PathStyle.muted)
                    reviewRow(subject)
                    ForEach(ExamTopic.allCases.filter { $0.subject == subject }) { topic in
                        topicRow(topic)
                    }
                }
            }
        }
        .foregroundStyle(PathStyle.primary)
    }

    private var header: some View {
        let progress = min(Double(path.todayXP) / Double(max(path.goalXP, 1)), 1)
        return HStack(spacing: 20) {
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(path.streak > 0 ? PathStyle.flame : PathStyle.muted)
                Text("\(path.streak)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text(path.streak == 1 ? "Tag" : "Tage")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(PathStyle.muted)
            }
            .frame(minWidth: 56)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Streak: \(path.streak) \(path.streak == 1 ? "Tag" : "Tage")")

            VStack(alignment: .leading, spacing: 8) {
                Text(path.goalMetToday ? "Tagesziel erreicht" : "Tagesziel")
                    .font(.system(size: 15, weight: .bold))
                ProgressView(value: progress)
                    .tint(path.goalMetToday ? PathStyle.accent : PathStyle.flame)
                Text("\(min(path.todayXP, path.goalXP)) / \(path.goalXP) XP heute")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(PathStyle.muted)
                Picker("Tagesziel", selection: Binding(get: { path.goalXP }, set: { path.setGoal($0) })) {
                    ForEach(LearnPathProgress.goalChoices, id: \.xp) { choice in
                        Text("\(choice.title) \(choice.xp)").tag(choice.xp)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                weekRow
                milestoneRow
                if path.progress.streakFreezes > 0 {
                    Label("\(path.progress.streakFreezes)× Streak-Schutz: überbrückt einen verpassten Tag", systemImage: "shield.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(PathStyle.muted)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PathStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(PathStyle.border))
    }

    private var weekRow: some View {
        HStack(spacing: 8) {
            ForEach(path.week, id: \.key) { day in
                VStack(spacing: 4) {
                    Text(day.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(day.isToday ? PathStyle.primary : PathStyle.muted)
                    Image(systemName: day.state == .met ? "checkmark.circle.fill"
                          : day.state == .frozen ? "shield.fill" : "circle")
                        .font(.system(size: 17))
                        .foregroundStyle(day.state == .met ? PathStyle.accent
                                         : day.state == .frozen ? PathStyle.flame
                                         : PathStyle.muted.opacity(day.state == .future ? 0.35 : 0.8))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(day.label): \(day.state == .met ? "Ziel erreicht" : day.state == .frozen ? "durch Streak-Schutz überbrückt" : day.state == .future ? "noch offen" : "Ziel verpasst")")
            }
        }
        .padding(.top, 2)
    }

    private var milestoneRow: some View {
        HStack(spacing: 8) {
            ForEach(LearnPathProgress.milestones, id: \.days) { milestone in
                let reached = path.progress.reachedMilestones.contains(milestone.days)
                Label("\(milestone.days) Tage", systemImage: reached ? "rosette" : "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(reached ? PathStyle.accent : PathStyle.muted)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(PathStyle.raised, in: Capsule())
                    .accessibilityLabel("Meilenstein \(milestone.days) Tage, \(reached ? "erreicht" : "offen"), \(milestone.bond) Bindungspunkte")
            }
        }
    }

    @ViewBuilder
    private func reviewRow(_ subject: ExamSubject) -> some View {
        let due = exam.dueCards(subject: subject).count
        if due > 0 {
            Button { onReview(subject) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(PathStyle.flame)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wiederholen")
                            .font(.system(size: 15, weight: .bold))
                        Text("\(due) \(due == 1 ? "Aufgabe" : "Aufgaben") fällig")
                            .font(.system(size: 12))
                            .foregroundStyle(PathStyle.muted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.fill").foregroundStyle(PathStyle.accent)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PathStyle.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(PathStyle.flame.opacity(0.6)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Wiederholen, \(subject.title), \(due) fällige Aufgaben")
        }
    }

    private func topicRow(_ topic: ExamTopic) -> some View {
        let done = path.progress.completedCount(for: topic)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: topic.symbol)
                    .foregroundStyle(PathStyle.accent)
                    .frame(width: 24)
                Text(topic.title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text("\(done)/\(LearnPathProgress.lessonsPerTopic)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(PathStyle.muted)
            }
            HStack(spacing: 12) {
                ForEach(0..<LearnPathProgress.lessonsPerTopic, id: \.self) { index in
                    lessonNode(topic: topic, index: index, done: done)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PathStyle.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(PathStyle.border))
    }

    @ViewBuilder
    private func lessonNode(topic: ExamTopic, index: Int, done: Int) -> some View {
        if index < done {
            node(symbol: "checkmark", fill: PathStyle.accent, foreground: .black)
                .accessibilityLabel("Lektion \(index + 1), abgeschlossen")
        } else if index == done {
            Button { onStart(topic) } label: {
                node(symbol: "play.fill", fill: PathStyle.raised, foreground: PathStyle.accent, ring: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lektion \(index + 1) starten, \(topic.title)")
        } else {
            node(symbol: "lock.fill", fill: PathStyle.raised, foreground: PathStyle.muted)
                .accessibilityLabel("Lektion \(index + 1), gesperrt")
        }
    }

    private func node(symbol: String, fill: Color, foreground: Color, ring: Bool = false) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(foreground)
            .frame(width: 46, height: 46)
            .background(fill, in: Circle())
            .overlay(Circle().strokeBorder(ring ? PathStyle.accent : Color.clear, lineWidth: 2))
    }
}
