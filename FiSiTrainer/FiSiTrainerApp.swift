// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

@main
struct FiSiTrainerApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var subnetStore = SubnetStore()
    @StateObject private var examStore = ExamStore()
    @StateObject private var rewards = RewardStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(subnetStore)
                .environmentObject(examStore)
                .environmentObject(rewards)
                .onChange(of: combinedXP, initial: true) { _, xp in
                    rewards.updateXP(xp)
                }
                .preferredColorScheme(.dark)
                .macMinimumSize(width: 1000, height: 700)
        }
        #if os(macOS)
        .defaultSize(width: 1180, height: 800)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        #endif
    }

    /// Port-Quiz, Subnetz-Sprint and Prüfungswissen XP together, without overflowing.
    private var combinedXP: Int {
        let (portAndSubnet, overflowedFirst) = store.progress.totalXP
            .addingReportingOverflow(subnetStore.progress.totalXP)
        let (total, overflowedSecond) = portAndSubnet
            .addingReportingOverflow(examStore.progress.totalXP)
        return (overflowedFirst || overflowedSecond) ? Int.max : total
    }
}
