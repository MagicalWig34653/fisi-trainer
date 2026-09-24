// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

@main
struct FiSiTrainerApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var subnetStore = SubnetStore()
    @StateObject private var rewards = RewardStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(subnetStore)
                .environmentObject(rewards)
                .onChange(of: store.progress.totalXP + subnetStore.progress.totalXP, initial: true) { _, xp in
                    rewards.updateXP(xp)
                }
                .preferredColorScheme(.dark)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .defaultSize(width: 1180, height: 800)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
