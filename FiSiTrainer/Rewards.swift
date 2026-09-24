// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation
import SwiftUI

enum PetKind: String, Codable, CaseIterable, Identifiable {
    case cat, fox, dragon

    var id: String { rawValue }

    var name: String {
        switch self {
        case .cat: "Katze"
        case .fox: "Fuchs"
        case .dragon: "Drache"
        }
    }

    var unlockLevel: Int {
        switch self {
        case .cat: 2
        case .fox: 5
        case .dragon: 10
        }
    }

    var symbol: String {
        switch self {
        case .cat: "cat.fill"
        case .fox: "pawprint.fill"
        case .dragon: "flame.fill"
        }
    }
}

enum PetInteraction: String, CaseIterable {
    case pet, feed, play

    var title: String {
        switch self {
        case .pet: "Streicheln"
        case .feed: "Füttern"
        case .play: "Spielen"
        }
    }

    var symbol: String {
        switch self {
        case .pet: "hand.raised.fill"
        case .feed: "carrot.fill"
        case .play: "sparkles"
        }
    }
}

struct RewardBadge: Identifiable, Equatable {
    let level: Int
    let name: String
    let symbol: String
    var id: Int { level }

    static let all: [RewardBadge] = [
        .init(level: 12, name: "Spürnase", symbol: "magnifyingglass.circle.fill"),
        .init(level: 18, name: "Analytiker", symbol: "chart.xyaxis.line"),
        .init(level: 24, name: "Architekt", symbol: "square.3.layers.3d.top.filled"),
        .init(level: 30, name: "Legende", symbol: "star.circle.fill"),
        .init(level: 40, name: "Signalmeister", symbol: "dot.radiowaves.left.and.right"),
        .init(level: 50, name: "Systembauer", symbol: "server.rack"),
        .init(level: 60, name: "Cloud-Pionier", symbol: "cloud.fill"),
        .init(level: 70, name: "Sicherheitswache", symbol: "shield.fill"),
        .init(level: 80, name: "Netzgestalter", symbol: "network"),
        .init(level: 90, name: "FiSi-Ikone", symbol: "sparkles.rectangle.stack.fill"),
        .init(level: 100, name: "Hundertfach", symbol: "crown.fill")
    ]
}

struct LevelReward: Identifiable {
    let level: Int
    let title: String
    let detail: String
    let isFeatured: Bool
    var id: Int { level }

    static let all: [LevelReward] = firstThirty + extended

    private static let firstThirty: [LevelReward] = [
        .init(level: 1, title: "Neuling", detail: "Deine Lernreise beginnt", isFeatured: true),
        .init(level: 2, title: "Katze", detail: "Erster Begleiter", isFeatured: true),
        .init(level: 3, title: "Entdecker", detail: "Neuer Titel", isFeatured: true),
        .init(level: 4, title: "Port-Kenner", detail: "Bandana für deine Begleiter", isFeatured: true),
        .init(level: 5, title: "Fuchs", detail: "Neuer Begleiter", isFeatured: true),
        .init(level: 6, title: "Subnetz-Spürer", detail: "Spielball für deine Begleiter", isFeatured: true),
        .init(level: 7, title: "Netzwerkprofi", detail: "Neuer Titel", isFeatured: true),
        .init(level: 8, title: "Protokoll-Kenner", detail: "TCP und UDP unterscheiden", isFeatured: false),
        .init(level: 9, title: "Routenfinder", detail: "Zusammenhänge erkennen", isFeatured: false),
        .init(level: 10, title: "Meister der Netze", detail: "Neuer Titel und Drache", isFeatured: true),
        .init(level: 11, title: "Dienst-Detektiv", detail: "Portwissen festigen", isFeatured: false),
        .init(level: 12, title: "Spürnase", detail: "Neues Abzeichen", isFeatured: true),
        .init(level: 13, title: "Adress-Planer", detail: "Adressräume durchdenken", isFeatured: false),
        .init(level: 14, title: "Masken-Kenner", detail: "Präfixe sicherer lesen", isFeatured: false),
        .init(level: 15, title: "Systemstratege", detail: "Neuer Titel", isFeatured: true),
        .init(level: 16, title: "Fehlersucher", detail: "Schal für deine Begleiter", isFeatured: true),
        .init(level: 17, title: "Netz-Analyst", detail: "Netzwerke besser einordnen", isFeatured: false),
        .init(level: 18, title: "Analytiker", detail: "Neues Abzeichen", isFeatured: true),
        .init(level: 19, title: "Infrastruktur-Planer", detail: "Dienste und Netze verbinden", isFeatured: false),
        .init(level: 20, title: "Infrastruktur-Architekt", detail: "Neuer Titel", isFeatured: true),
        .init(level: 21, title: "Protokoll-Stratege", detail: "Transportwege vergleichen", isFeatured: false),
        .init(level: 22, title: "Adressraum-Profi", detail: "Wollknäuel für deine Begleiter", isFeatured: true),
        .init(level: 23, title: "Service-Architekt", detail: "Dienstwissen verknüpfen", isFeatured: false),
        .init(level: 24, title: "Architekt", detail: "Neues Abzeichen", isFeatured: true),
        .init(level: 25, title: "FiSi-Veteran", detail: "Neuer Titel", isFeatured: true),
        .init(level: 26, title: "Netzwerk-Mentor", detail: "Wissen sicher anwenden", isFeatured: false),
        .init(level: 27, title: "System-Kenner", detail: "Verbindungen im Blick behalten", isFeatured: false),
        .init(level: 28, title: "Infrastruktur-Meister", detail: "Komplexe Aufgaben meistern", isFeatured: false),
        .init(level: 29, title: "Legenden-Anwärter", detail: "Die letzte Etappe beginnt", isFeatured: false),
        .init(level: 30, title: "Netzwerk-Legende", detail: "Neuer Titel und Abzeichen", isFeatured: true)
    ]

    private static let extended: [LevelReward] = [
        .init(level: 31, title: "Dienstefinder", detail: "Bekannte Ports schneller erkennen", isFeatured: false),
        .init(level: 32, title: "Adresskundiger", detail: "Netzgrenzen sicherer bestimmen", isFeatured: false),
        .init(level: 33, title: "Transportkenner", detail: "TCP und UDP bewusst wählen", isFeatured: false),
        .init(level: 34, title: "Maskenleser", detail: "Präfixe genauer einordnen", isFeatured: false),
        .init(level: 35, title: "Expeditionsleiter", detail: "Entdeckerhut für deine Begleiter", isFeatured: true),
        .init(level: 36, title: "Serviceprüfer", detail: "Dienst und Port zusammen denken", isFeatured: false),
        .init(level: 37, title: "Netzvermesser", detail: "Adressbereiche im Blick behalten", isFeatured: false),
        .init(level: 38, title: "Portnavigator", detail: "Ähnliche Dienste unterscheiden", isFeatured: false),
        .init(level: 39, title: "Präfixprofi", detail: "Subnetzgrößen vergleichen", isFeatured: false),
        .init(level: 40, title: "Netzwerk-Koryphäe", detail: "Neuer Titel und Abzeichen", isFeatured: true),
        .init(level: 41, title: "Dienststratege", detail: "Portwissen gezielt anwenden", isFeatured: false),
        .init(level: 42, title: "Hostplaner", detail: "Nutzbare Hosts abschätzen", isFeatured: false),
        .init(level: 43, title: "Protokollanalyst", detail: "Transportprotokolle prüfen", isFeatured: false),
        .init(level: 44, title: "Subnetzlotse", detail: "Mit Präfixen sicher navigieren", isFeatured: false),
        .init(level: 45, title: "Sternenforscher", detail: "Sternenspielzeug für deine Begleiter", isFeatured: true),
        .init(level: 46, title: "Adressanalyst", detail: "Adressräume vergleichen", isFeatured: false),
        .init(level: 47, title: "Serviceexperte", detail: "Dienste auch rückwärts erkennen", isFeatured: false),
        .init(level: 48, title: "Netzrechner", detail: "Hostzahlen sicher berechnen", isFeatured: false),
        .init(level: 49, title: "Systemplaner", detail: "Dienste und Netze verbinden", isFeatured: false),
        .init(level: 50, title: "System-Ingenieur", detail: "Neuer Titel und Abzeichen", isFeatured: true),
        .init(level: 51, title: "Portarchivar", detail: "Wichtige Ports festigen", isFeatured: false),
        .init(level: 52, title: "Netzordner", detail: "Subnetze sauber einteilen", isFeatured: false),
        .init(level: 53, title: "Protokollplaner", detail: "Transportwege zuordnen", isFeatured: false),
        .init(level: 54, title: "Hostanalyst", detail: "Nutzbare Adressen prüfen", isFeatured: false),
        .init(level: 55, title: "Dienstarchitekt", detail: "Servicewissen verknüpfen", isFeatured: false),
        .init(level: 56, title: "Maskenanalyst", detail: "Präfix und Maske verbinden", isFeatured: false),
        .init(level: 57, title: "Netzwerkdenker", detail: "Mehrere Regeln kombinieren", isFeatured: false),
        .init(level: 58, title: "Fehleranalyst", detail: "Antworten gezielt hinterfragen", isFeatured: false),
        .init(level: 59, title: "Infrastrukturstratege", detail: "Zusammenhänge sicher nutzen", isFeatured: false),
        .init(level: 60, title: "Cloud-Architekt", detail: "Neuer Titel und Abzeichen", isFeatured: true),
        .init(level: 61, title: "Portforscher", detail: "Unbekannte Zuordnungen erschließen", isFeatured: false),
        .init(level: 62, title: "Adresslotse", detail: "Netzbereiche sicher lesen", isFeatured: false),
        .init(level: 63, title: "Transportprüfer", detail: "Protokolle bewusst vergleichen", isFeatured: false),
        .init(level: 64, title: "Subnetzstratege", detail: "Präfixe gezielt einsetzen", isFeatured: false),
        .init(level: 65, title: "Dienstplaner", detail: "Servicekenntnisse festigen", isFeatured: false),
        .init(level: 66, title: "Hostexperte", detail: "Hostzahlen schneller ableiten", isFeatured: false),
        .init(level: 67, title: "Netzbeobachter", detail: "Muster in Aufgaben erkennen", isFeatured: false),
        .init(level: 68, title: "Maskenstratege", detail: "Subnetzmasken sicher wählen", isFeatured: false),
        .init(level: 69, title: "Sicherheitsdenker", detail: "Dienste sorgfältig einordnen", isFeatured: false),
        .init(level: 70, title: "Sicherheits-Stratege", detail: "Neuer Titel und Abzeichen", isFeatured: true),
        .init(level: 71, title: "Portmeister", detail: "Dienstwissen souverän abrufen", isFeatured: false),
        .init(level: 72, title: "Netzplaner", detail: "Adressraum sinnvoll strukturieren", isFeatured: false),
        .init(level: 73, title: "Protokollmeister", detail: "Transportprotokolle sicher kennen", isFeatured: false),
        .init(level: 74, title: "Subnetzmeister", detail: "Präfixe sicher berechnen", isFeatured: false),
        .init(level: 75, title: "Kronenträger", detail: "Krone für deine Begleiter", isFeatured: true),
        .init(level: 76, title: "Serviceberater", detail: "Dienste verständlich zuordnen", isFeatured: false),
        .init(level: 77, title: "Adressmeister", detail: "Grenzen und Hosts sicher finden", isFeatured: false),
        .init(level: 78, title: "Systembeobachter", detail: "Netzwissen im Zusammenhang sehen", isFeatured: false),
        .init(level: 79, title: "Infrastrukturkenner", detail: "Wissen verlässlich anwenden", isFeatured: false),
        .init(level: 80, title: "Infrastruktur-Experte", detail: "Neuer Titel und Abzeichen", isFeatured: true),
        .init(level: 81, title: "Portberater", detail: "Wichtige Dienste schnell erkennen", isFeatured: false),
        .init(level: 82, title: "Netzberater", detail: "Subnetzfragen klar lösen", isFeatured: false),
        .init(level: 83, title: "Transportstratege", detail: "TCP und UDP sicher bewerten", isFeatured: false),
        .init(level: 84, title: "Adressarchitekt", detail: "Netzbereiche präzise planen", isFeatured: false),
        .init(level: 85, title: "Dienstemanager", detail: "Port und Service im Blick", isFeatured: false),
        .init(level: 86, title: "Präfixarchitekt", detail: "Masken und Hosts verbinden", isFeatured: false),
        .init(level: 87, title: "Netzwerktrainer", detail: "Erlernte Muster festigen", isFeatured: false),
        .init(level: 88, title: "Systemmentor", detail: "Komplexe Fragen zerlegen", isFeatured: false),
        .init(level: 89, title: "FiSi-Wegbereiter", detail: "Wissen übergreifend einsetzen", isFeatured: false),
        .init(level: 90, title: "FiSi-Ikone", detail: "Neuer Titel, Abzeichen und Rakete", isFeatured: true),
        .init(level: 91, title: "Portlegende", detail: "Dienstwissen weiter vertiefen", isFeatured: false),
        .init(level: 92, title: "Subnetzlegende", detail: "Adresswissen weiter vertiefen", isFeatured: false),
        .init(level: 93, title: "Protokollexperte", detail: "Transportwissen weiter vertiefen", isFeatured: false),
        .init(level: 94, title: "Hoststratege", detail: "Hostzahlen souverän einschätzen", isFeatured: false),
        .init(level: 95, title: "Dienstevisionär", detail: "Services im Zusammenhang sehen", isFeatured: false),
        .init(level: 96, title: "Netzvisionär", detail: "Adressräume im Zusammenhang sehen", isFeatured: false),
        .init(level: 97, title: "FiSi-Analyst", detail: "Aufgaben systematisch lösen", isFeatured: false),
        .init(level: 98, title: "FiSi-Stratege", detail: "Wissen gezielt kombinieren", isFeatured: false),
        .init(level: 99, title: "Legenden-Anwärter", detail: "Die hundertste Etappe ist nah", isFeatured: false),
        .init(level: 100, title: "FiSi-Legende", detail: "Neuer Titel und Abzeichen", isFeatured: true)
    ]

    static func rankTitle(for level: Int) -> String {
        switch level {
        case ..<3: "Neuling"
        case 3..<7: "Entdecker"
        case 7..<10: "Netzwerkprofi"
        case 10..<15: "Meister der Netze"
        case 15..<20: "Systemstratege"
        case 20..<25: "Infrastruktur-Architekt"
        case 25..<30: "FiSi-Veteran"
        case 30..<40: "Netzwerk-Legende"
        case 40..<50: "Netzwerk-Koryphäe"
        case 50..<60: "System-Ingenieur"
        case 60..<70: "Cloud-Architekt"
        case 70..<80: "Sicherheits-Stratege"
        case 80..<90: "Infrastruktur-Experte"
        case 90..<100: "FiSi-Ikone"
        default: "FiSi-Legende"
        }
    }
}

@MainActor
final class RewardStore: ObservableObject {
    @Published private(set) var totalXP = 0
    @Published private(set) var selectedPet: PetKind?
    @Published private(set) var saveError: String?
    @Published private(set) var interactionCounts: [String: [String: Int]] = [:]
    @Published private(set) var outfitsByPet: [String: String] = [:]
    @Published private(set) var toysByPet: [String: String] = [:]

    var needsRecovery: Bool { !maySave }
    var level: Int { 1 + totalXP / 250 }
    var unlockedPets: [PetKind] { PetKind.allCases.filter { level >= $0.unlockLevel } }
    var earnedBadges: [RewardBadge] { RewardBadge.all.filter { level >= $0.level } }
    var nextReward: LevelReward? {
        LevelReward.all.first { $0.level > level && $0.isFeatured }
    }
    var xpToNextReward: Int? {
        nextReward.map { max(0, ($0.level - 1) * 250 - totalXP) }
    }
    var bond: Int {
        guard let selectedPet else { return 0 }
        return PetInteraction.allCases.reduce(0) { $0 + count($1, for: selectedPet) }
    }

    var rankTitle: String { LevelReward.rankTitle(for: level) }

    func outfit(for pet: PetKind) -> PetOutfit? {
        guard unlockedPets.contains(pet), let raw = outfitsByPet[pet.rawValue],
              let outfit = PetOutfit(rawValue: raw), level >= outfit.unlockLevel else { return nil }
        return outfit
    }

    func toy(for pet: PetKind) -> PetToy? {
        guard unlockedPets.contains(pet), let raw = toysByPet[pet.rawValue],
              let toy = PetToy(rawValue: raw), level >= toy.unlockLevel else { return nil }
        return toy
    }

    func equipOutfit(_ outfit: PetOutfit?, for pet: PetKind) {
        guard maySave, unlockedPets.contains(pet),
              outfit == nil || level >= outfit!.unlockLevel else { return }
        guard outfitsByPet[pet.rawValue] != outfit?.rawValue else { return }
        outfitsByPet[pet.rawValue] = outfit?.rawValue
        save()
    }

    func equipToy(_ toy: PetToy?, for pet: PetKind) {
        guard maySave, unlockedPets.contains(pet),
              toy == nil || level >= toy!.unlockLevel else { return }
        guard toysByPet[pet.rawValue] != toy?.rawValue else { return }
        toysByPet[pet.rawValue] = toy?.rawValue
        save()
    }

    private struct Save: Codable {
        var totalXP: Int
        var selectedPet: PetKind?
        var interactionCounts: [String: [String: Int]]
        var outfitsByPet: [String: String]
        var toysByPet: [String: String]

        enum CodingKeys: String, CodingKey {
            case totalXP, selectedPet, interactionCounts, outfitsByPet, toysByPet
        }

        init(totalXP: Int, selectedPet: PetKind?, interactionCounts: [String: [String: Int]],
             outfitsByPet: [String: String], toysByPet: [String: String]) {
            self.totalXP = totalXP
            self.selectedPet = selectedPet
            self.interactionCounts = interactionCounts
            self.outfitsByPet = outfitsByPet
            self.toysByPet = toysByPet
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            totalXP = try values.decode(Int.self, forKey: .totalXP)
            selectedPet = try values.decodeIfPresent(PetKind.self, forKey: .selectedPet)
            interactionCounts = try values.decodeIfPresent([String: [String: Int]].self,
                                                           forKey: .interactionCounts) ?? [:]
            outfitsByPet = try values.decodeIfPresent([String: String].self,
                                                      forKey: .outfitsByPet) ?? [:]
            toysByPet = try values.decodeIfPresent([String: String].self,
                                                   forKey: .toysByPet) ?? [:]
        }
    }

    private let saveURL: URL
    private var maySave = true

    init(saveURL: URL? = nil) {
        self.saveURL = saveURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FiSiTrainer", isDirectory: true)
            .appendingPathComponent("rewards.json")
        load()
    }

    func count(_ interaction: PetInteraction, for pet: PetKind) -> Int {
        interactionCounts[pet.rawValue]?[interaction.rawValue] ?? 0
    }

    func updateXP(_ currentCombinedXP: Int) {
        guard maySave, currentCombinedXP > totalXP else { return }
        totalXP = currentCombinedXP
        if selectedPet == nil { selectedPet = unlockedPets.first }
        save()
    }

    func selectPet(_ pet: PetKind) {
        guard maySave, unlockedPets.contains(pet), selectedPet != pet else { return }
        selectedPet = pet
        save()
    }

    func interact(_ interaction: PetInteraction) {
        guard maySave, let selectedPet, unlockedPets.contains(selectedPet) else { return }
        let oldCount = count(interaction, for: selectedPet)
        guard oldCount < Int.max else { return }
        interactionCounts[selectedPet.rawValue, default: [:]][interaction.rawValue] = oldCount + 1
        save()
    }

    func retrySave() {
        guard maySave, saveError != nil else { return }
        save()
    }

    /// Explicit recovery only: preserve a damaged save before creating a new one.
    func resetCorruptSave() {
        guard !maySave else { return }
        if FileManager.default.fileExists(atPath: saveURL.path) {
            let backup = saveURL.deletingLastPathComponent()
                .appendingPathComponent("rewards.corrupt.\(UUID().uuidString).json")
            do {
                try FileManager.default.moveItem(at: saveURL, to: backup)
            } catch {
                saveError = "Beschädigte Belohnungen konnten nicht gesichert werden: \(error.localizedDescription)"
                return
            }
        }
        totalXP = 0
        selectedPet = nil
        interactionCounts = [:]
        outfitsByPet = [:]
        toysByPet = [:]
        maySave = true
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            let saved = try JSONDecoder().decode(Save.self, from: data)
            guard saved.totalXP >= 0,
                  saved.interactionCounts.allSatisfy({ PetKind(rawValue: $0.key) != nil &&
                      $0.value.allSatisfy({ PetInteraction(rawValue: $0.key) != nil && $0.value >= 0 }) })
            else { throw CocoaError(.coderInvalidValue) }
            totalXP = saved.totalXP
            interactionCounts = saved.interactionCounts
            selectedPet = saved.selectedPet.flatMap { unlockedPets.contains($0) ? $0 : nil }
                ?? unlockedPets.first
            for (key, raw) in saved.outfitsByPet {
                guard let pet = PetKind(rawValue: key), unlockedPets.contains(pet),
                      let outfit = PetOutfit(rawValue: raw), level >= outfit.unlockLevel else { continue }
                outfitsByPet[key] = raw
            }
            for (key, raw) in saved.toysByPet {
                guard let pet = PetKind(rawValue: key), unlockedPets.contains(pet),
                      let toy = PetToy(rawValue: raw), level >= toy.unlockLevel else { continue }
                toysByPet[key] = raw
            }
        } catch {
            maySave = false
            saveError = "Belohnungen konnten nicht gelesen werden: \(error.localizedDescription)"
        }
    }

    private func save() {
        guard maySave else { return }
        do {
            try FileManager.default.createDirectory(at: saveURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Save(totalXP: totalXP,
                                                     selectedPet: selectedPet,
                                                     interactionCounts: interactionCounts,
                                                     outfitsByPet: outfitsByPet,
                                                     toysByPet: toysByPet))
            try data.write(to: saveURL, options: .atomic)
            saveError = nil
        } catch {
            saveError = "Belohnungen konnten nicht gespeichert werden: \(error.localizedDescription)"
        }
    }
}

private enum RewardStyle {
    static let surface = Color(red: 0.078, green: 0.113, blue: 0.151)
    static let raised = Color(red: 0.103, green: 0.145, blue: 0.183)
    static let primary = Color(red: 0.94, green: 0.97, blue: 0.96)
    static let muted = Color(red: 0.53, green: 0.61, blue: 0.64)
    static let accent = Color(red: 0.76, green: 0.97, blue: 0.32)
    static let red = Color(red: 1.0, green: 0.45, blue: 0.43)
}

struct RewardsView: View {
    @EnvironmentObject private var rewards: RewardStore
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var subnet: SubnetStore
    @State private var interaction: PetInteraction?
    @State private var interactionID = 0
    @State private var showingRecovery = false
    @State private var activePetSheet: PetSheet?
    @State private var expandedChapter = 1

    private enum PetSheet: Identifiable {
        case chat(PetKind)
        case wardrobe(PetKind)

        var id: String {
            switch self {
            case .chat(let pet): "chat-\(pet.id)"
            case .wardrobe(let pet): "wardrobe-\(pet.id)"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 7) {
                Text("BELOHNUNGEN")
                    .font(.system(size: 11, weight: .bold)).tracking(2)
                    .foregroundStyle(RewardStyle.accent)
                Text("Dein Lernpfad")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Port-Quiz und Subnetz-Sprint zählen zusammen. Erreichte Belohnungen bleiben auch nach einem Trainings-Reset erhalten.")
                    .font(.system(size: 13))
                    .foregroundStyle(RewardStyle.muted)
            }

            if let saveError = rewards.saveError {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(RewardStyle.red)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(saveError).font(.system(size: 12, weight: .semibold))
                        Text(rewards.needsRecovery
                             ? "Die beschädigte Datei bleibt bis zur bestätigten Wiederherstellung unverändert."
                             : "Deine Änderungen sind noch nicht auf der Festplatte gesichert.")
                            .font(.system(size: 11)).foregroundStyle(RewardStyle.muted)
                    }
                    Spacer()
                    if rewards.needsRecovery {
                        Button("Wiederherstellen") { showingRecovery = true }
                    } else {
                        Button("Erneut speichern") { rewards.retrySave() }
                    }
                }
                .padding(15)
                .background(RewardStyle.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }

            progressCard
            badgeCard
            petCard
            roadmapCard
        }
        .foregroundStyle(RewardStyle.primary)
        .sheet(item: $activePetSheet) { destination in
            switch destination {
            case .chat(let pet): PetChatView(pet: pet)
            case .wardrobe(let pet): PetWardrobeView(pet: pet)
            }
        }
        .confirmationDialog("Beschädigte Belohnungen zurücksetzen?",
                            isPresented: $showingRecovery, titleVisibility: .visible) {
            Button("Datei sichern und neu beginnen", role: .destructive) {
                rewards.resetCorruptSave()
                if !rewards.needsRecovery {
                    let (combined, overflow) = game.progress.totalXP
                        .addingReportingOverflow(subnet.progress.totalXP)
                    rewards.updateXP(overflow ? Int.max : combined)
                }
            }
        } message: {
            Text("Die beschädigte Datei bleibt als Sicherung erhalten. Level und Begleiter werden aus den aktuellen Trainings-XP neu aufgebaut; frühere Bindung und Auswahl sind nur in der Sicherung enthalten.")
        }
        .onAppear { expandedChapter = chapter(for: rewards.level) }
        .onChange(of: rewards.level) { _, newLevel in
            expandedChapter = chapter(for: newLevel)
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("LEVEL \(rewards.level)")
                        .font(.system(size: 13, weight: .bold)).tracking(1.2)
                        .foregroundStyle(RewardStyle.accent)
                    Text(rewards.rankTitle)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("\(rewards.totalXP) XP")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(RewardStyle.raised)
                    Capsule().fill(RewardStyle.accent)
                        .frame(width: geometry.size.width * CGFloat(rewards.totalXP % 250) / 250)
                }
            }
            .frame(height: 9)
            Text("\(250 - rewards.totalXP % 250) XP bis Level \(rewards.level + 1)")
                .font(.system(size: 11)).foregroundStyle(RewardStyle.muted)
            if let next = rewards.nextReward, let remaining = rewards.xpToNextReward {
                HStack(spacing: 9) {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(RewardStyle.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Nächste Belohnung: \(next.title)")
                            .font(.system(size: 12, weight: .semibold))
                        Text(next.detail)
                            .font(.system(size: 11))
                            .foregroundStyle(RewardStyle.muted)
                    }
                    Spacer(minLength: 6)
                    Text("\(remaining) XP · Level \(next.level)")
                        .font(.system(size: 11))
                        .foregroundStyle(RewardStyle.muted)
                }
            } else {
                Text("Alle Roadmap-Belohnungen verdient. Deine Level steigen weiter.")
                    .font(.system(size: 11))
                    .foregroundStyle(RewardStyle.accent)
            }
        }
        .padding(22)
        .background(RewardStyle.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var badgeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Abzeichen")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
                Text("\(rewards.earnedBadges.count) / \(RewardBadge.all.count) VERDIENT")
                    .font(.system(size: 10, weight: .bold)).tracking(1)
                    .foregroundStyle(RewardStyle.accent)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                      spacing: 10) {
                ForEach(RewardBadge.all) { badge in
                    let earned = rewards.level >= badge.level
                    VStack(spacing: 8) {
                        Image(systemName: earned ? badge.symbol : "lock.fill")
                            .font(.system(size: 24))
                            .frame(height: 28)
                        Text(badge.name)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(earned ? "VERDIENT" : "LEVEL \(badge.level)")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(earned ? RewardStyle.accent : RewardStyle.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(earned ? RewardStyle.accent.opacity(0.1) : RewardStyle.raised,
                                in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(earned ? RewardStyle.accent.opacity(0.5) : Color.white.opacity(0.06)))
                    .accessibilityLabel("\(badge.name), \(earned ? "verdient" : "ab Level \(badge.level)")")
                }
            }
        }
        .padding(22)
        .background(RewardStyle.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var petCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Deine Begleiter")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
                Text("\(rewards.unlockedPets.count) / \(PetKind.allCases.count) FREI")
                    .font(.system(size: 10, weight: .bold)).tracking(1)
                    .foregroundStyle(RewardStyle.accent)
            }

            HStack(spacing: 12) {
                ForEach(PetKind.allCases) { pet in
                    let unlocked = rewards.unlockedPets.contains(pet)
                    Button {
                        rewards.selectPet(pet)
                        interaction = nil
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: unlocked ? pet.symbol : "lock.fill")
                                .font(.system(size: 25))
                                .frame(height: 30)
                            Text(pet.name).font(.system(size: 13, weight: .semibold))
                            Text(unlocked ? "FREI" : "LEVEL \(pet.unlockLevel)")
                                .font(.system(size: 10, weight: .bold)).tracking(0.7)
                        }
                        .foregroundStyle(unlocked ? RewardStyle.primary : RewardStyle.muted)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(rewards.selectedPet == pet ? RewardStyle.accent.opacity(0.12) : RewardStyle.raised,
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(rewards.selectedPet == pet ? RewardStyle.accent : Color.white.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                    .accessibilityLabel("\(pet.name), \(unlocked ? "freigeschaltet" : "ab Level \(pet.unlockLevel)" )")
                }
            }

            if let pet = rewards.selectedPet {
                PetHabitatView(pet: pet, interaction: interaction, interactionID: interactionID,
                               outfit: rewards.outfit(for: pet), toy: rewards.toy(for: pet))
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .background(RewardStyle.raised, in: RoundedRectangle(cornerRadius: 14))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text("Ziehen zum Drehen · Scrollen zum Zoomen · Doppelklick zum Zentrieren")
                    .font(.system(size: 11)).foregroundStyle(RewardStyle.muted)
                Button {
                    activePetSheet = .chat(pet)
                } label: {
                    Label("Mit deinem Haustier sprechen", systemImage: "bubble.left.and.bubble.right")
                }
                .buttonStyle(.bordered)
                Button {
                    activePetSheet = .wardrobe(pet)
                } label: {
                    Label("Ausstattung", systemImage: "tshirt.fill")
                }
                .buttonStyle(.bordered)
                HStack {
                    Text("Bindung: \(rewards.bond)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RewardStyle.accent)
                    Spacer()
                    ForEach(PetInteraction.allCases, id: \.self) { action in
                        Button {
                            rewards.interact(action)
                            interaction = action
                            interactionID += 1
                        } label: {
                            Label(action.title, systemImage: action.symbol)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                Text("Erreiche Level 2 und schalte deine Katze frei.")
                    .font(.system(size: 13))
                    .foregroundStyle(RewardStyle.muted)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .padding(22)
        .background(RewardStyle.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var roadmapCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Level-Roadmap")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            ForEach(1...10, id: \.self) { number in
                chapterSection(number)
            }
        }
        .padding(22)
        .background(RewardStyle.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func chapterSection(_ number: Int) -> some View {
        let levels = LevelReward.all.filter { self.chapter(for: $0.level) == number }
        let completed = min(10, max(0, rewards.level - (number - 1) * 10))
        return DisclosureGroup(isExpanded: Binding(
            get: { expandedChapter == number },
            set: { expandedChapter = $0 ? number : 0 }
        )) {
            VStack(spacing: 8) {
                ForEach(levels) { milestone in
                    milestoneRow(milestone)
                }
            }
            .padding(.top, 12)
        } label: {
            HStack {
                Text("KAPITEL \(number) · LEVEL \((number - 1) * 10 + 1)–\(number * 10)")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.7)
                Spacer()
                Text("\(completed) / 10")
                    .font(.system(size: 11))
                    .foregroundStyle(RewardStyle.muted)
            }
        }
        .tint(RewardStyle.accent)
        .padding(14)
        .background(RewardStyle.raised.opacity(0.55), in: RoundedRectangle(cornerRadius: 11))
    }

    private func milestoneRow(_ milestone: LevelReward) -> some View {
        let earned = rewards.level >= milestone.level
        return HStack(spacing: 14) {
            Text("\(milestone.level)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(width: 34, height: 34)
                .background(earned ? RewardStyle.accent : RewardStyle.raised, in: Circle())
                .foregroundStyle(earned ? Color.black : RewardStyle.muted)
            VStack(alignment: .leading, spacing: 3) {
                Text(milestone.title)
                    .font(.system(size: 13, weight: .semibold))
                Text(milestone.detail)
                    .font(.system(size: 11)).foregroundStyle(RewardStyle.muted)
            }
            Spacer()
            Image(systemName: earned ? "checkmark.seal.fill" : "lock.fill")
                .foregroundStyle(earned ? RewardStyle.accent : RewardStyle.muted)
        }
        .padding(11)
        .background(earned ? RewardStyle.accent.opacity(0.06) : RewardStyle.raised.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 10))
    }

    private func chapter(for level: Int) -> Int {
        min(10, max(1, (level - 1) / 10 + 1))
    }
}
