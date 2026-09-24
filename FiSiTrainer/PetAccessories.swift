// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

enum PetOutfit: String, Codable, CaseIterable, Identifiable {
    case bandana, scarf, explorerHat, crown

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bandana: "Halstuch"
        case .scarf: "Schal"
        case .explorerHat: "Entdeckerhut"
        case .crown: "Krone"
        }
    }

    var symbol: String {
        switch self {
        case .bandana: "tag.fill"
        case .scarf: "wind"
        case .explorerHat: "hat.widebrim.fill"
        case .crown: "crown.fill"
        }
    }

    var unlockLevel: Int {
        switch self {
        case .bandana: 4
        case .scarf: 16
        case .explorerHat: 35
        case .crown: 75
        }
    }
}

enum PetToy: String, Codable, CaseIterable, Identifiable {
    case ball, yarn, star, rocket

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ball: "Ball"
        case .yarn: "Wollknäuel"
        case .star: "Stern"
        case .rocket: "Rakete"
        }
    }

    var symbol: String {
        switch self {
        case .ball: "circle.fill"
        case .yarn: "circle.grid.cross.fill"
        case .star: "star.fill"
        case .rocket: "paperplane.fill"
        }
    }

    var unlockLevel: Int {
        switch self {
        case .ball: 6
        case .yarn: 22
        case .star: 45
        case .rocket: 90
        }
    }
}
