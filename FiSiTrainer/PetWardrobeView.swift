// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

struct PetWardrobeView: View {
    let pet: PetKind

    @EnvironmentObject private var rewards: RewardStore
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 130, maximum: 180), spacing: 10)]
    private let surface = Color(red: 0.078, green: 0.113, blue: 0.151)
    private let raised = Color(red: 0.103, green: 0.145, blue: 0.183)
    private let accent = Color(red: 0.76, green: 0.97, blue: 0.32)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ausstattung für \(pet.name)")
                        .font(.title2.bold())
                    Text("Erspiele neue Looks und Spielzeuge mit deinen Lern-XP.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Schließen") { dismiss() }
            }
            .padding(20)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 11) {
                        sectionTitle("Outfit", selected: rewards.outfit(for: pet)?.name)
                        LazyVGrid(columns: columns, spacing: 10) {
                            choice("Keines", symbol: "xmark.circle", level: nil,
                                   selected: rewards.outfit(for: pet) == nil) {
                                rewards.equipOutfit(nil, for: pet)
                            }
                            ForEach(PetOutfit.allCases) { outfit in
                                choice(outfit.name, symbol: outfit.symbol,
                                       level: outfit.unlockLevel,
                                       selected: rewards.outfit(for: pet) == outfit) {
                                    rewards.equipOutfit(outfit, for: pet)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 11) {
                        sectionTitle("Spielzeug", selected: rewards.toy(for: pet)?.name)
                        LazyVGrid(columns: columns, spacing: 10) {
                            choice("Keines", symbol: "xmark.circle", level: nil,
                                   selected: rewards.toy(for: pet) == nil) {
                                rewards.equipToy(nil, for: pet)
                            }
                            ForEach(PetToy.allCases) { toy in
                                choice(toy.name, symbol: toy.symbol, level: toy.unlockLevel,
                                       selected: rewards.toy(for: pet) == toy) {
                                    rewards.equipToy(toy, for: pet)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 520, idealWidth: 650, minHeight: 440, idealHeight: 510)
        .background(surface)
        .foregroundStyle(.white)
    }

    private func sectionTitle(_ name: String, selected: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(name).font(.headline)
            Spacer()
            Text("Ausgewählt: \(selected ?? "Keines")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func choice(_ name: String, symbol: String, level: Int?, selected: Bool,
                        action: @escaping () -> Void) -> some View {
        let locked = level.map { rewards.level < $0 } ?? false
        return Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: locked ? "lock.fill" : symbol)
                    .font(.title2)
                    .frame(height: 28)
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(locked ? "Ab Level \(level ?? 1)" : selected ? "Ausgewählt" : "Freigeschaltet")
                    .font(.caption2)
                    .foregroundStyle(locked ? Color.gray : selected ? accent : Color.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(10)
            .background(selected ? accent.opacity(0.13) : raised,
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(selected ? accent : Color.white.opacity(0.08)))
            .opacity(locked ? 0.65 : 1)
        }
        .buttonStyle(.plain)
        .disabled(locked || selected)
        .accessibilityLabel("\(name), \(locked ? "gesperrt bis Level \(level ?? 1)" : selected ? "ausgewählt" : "freigeschaltet")")
    }
}
