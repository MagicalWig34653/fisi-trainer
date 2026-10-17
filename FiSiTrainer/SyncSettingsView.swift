// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

/// The iCloud switch. Hidden in builds without the iCloud entitlement.
struct SyncSettingsView: View {
    @EnvironmentObject private var sync: SyncController

    var body: some View {
        if SyncController.isSupported {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: Binding(get: { sync.isEnabled }, set: { sync.setEnabled($0) })) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Mit iCloud synchronisieren")
                            .font(.system(size: 14, weight: .semibold))
                        Text(detail)
                            .font(.system(size: 12))
                            .foregroundStyle(RewardStyle.muted)
                    }
                }
                .disabled(!sync.accountAvailable && !sync.isEnabled)
            }
            .padding(16)
            .background(RewardStyle.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var detail: String {
        if !sync.accountAvailable {
            return "Melde dich in den Systemeinstellungen bei iCloud an, um XP und Lernstand zwischen deinen Geräten abzugleichen."
        }
        return "Gleicht XP, Lernstand und Prüfungsverlauf zwischen deinen Geräten ab. Ein Zurücksetzen gilt dann für alle Geräte. Die Daten liegen in deinem privaten iCloud-Bereich."
    }
}
