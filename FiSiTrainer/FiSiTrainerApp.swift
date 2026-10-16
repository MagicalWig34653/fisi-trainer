// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

@main
struct FiSiTrainerApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var subnetStore = SubnetStore()
    @StateObject private var examStore = ExamStore()
    @StateObject private var rewards = RewardStore()

    init() {
        StartupWarmup.run()
    }

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

/// Builds the large authored catalogs once on a thread with a generous stack.
///
/// The iOS main thread has a 1 MB stack (8 MB on the Mac). Debug builds compile the long array literals of
/// the exam catalog, level rewards and port list into very large stack frames, which can overflow it at
/// launch. The statics are initialized exactly once, so the main thread afterwards only reads them.
enum StartupWarmup {
    static func run() {
        #if os(iOS)
        let finished = DispatchSemaphore(value: 0)
        let thread = Thread {
            _ = ExamCatalog.all.count
            _ = LevelReward.all.count
            _ = RewardBadge.all.count
            _ = PortService.catalog.count
            finished.signal()
        }
        thread.stackSize = 32 * 1024 * 1024
        thread.qualityOfService = .userInitiated
        thread.start()
        finished.wait()
        #endif
    }
}
