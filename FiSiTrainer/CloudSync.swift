// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Where the sync blobs live. The iCloud implementation and the test double both conform to this.
@MainActor
protocol SyncBackend: AnyObject {
    func read(_ key: String) -> Data?
    func write(_ data: Data, forKey key: String)
    /// `handler` runs when *another* device changed `key`. Passing `nil` removes the observer.
    func setObserver(forKey key: String, _ handler: (() -> Void)?)
}

/// A stable, random ID per installation. A reinstall gets a new ID, so what the old installation earned is
/// kept as another device's share instead of being lost or counted twice.
enum SyncDevice {
    static let defaultsKey = "sync.deviceID"

    static func id(defaults: UserDefaults = .standard) -> String {
        if let existing = defaults.string(forKey: defaultsKey), !existing.isEmpty { return existing }
        let created = UUID().uuidString
        defaults.set(created, forKey: defaultsKey)
        return created
    }
}

/// Connects one store to the backend: publishes its share after saves and merges what other devices wrote.
///
/// The local save file stays the source of truth. A store with a damaged save (`canSync == false`) neither
/// publishes nor merges, and invalid remote data is ignored instead of overwriting local progress.
@MainActor
final class StoreSyncCoordinator {
    private let key: String
    private let deviceID: String
    private let backend: SyncBackend
    private let throttle: TimeInterval
    private let snapshot: () -> SyncState
    private let canSync: () -> Bool
    private let apply: (SyncState) -> Void
    private var lastPublished: Data?
    private var scheduled: Task<Void, Never>?

    /// Set when remote data was ignored because it could not be decoded or failed validation.
    private(set) var ignoredRemoteData = false

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    init(key: String, deviceID: String, backend: SyncBackend, throttle: TimeInterval = 1.5,
         snapshot: @escaping () -> SyncState, canSync: @escaping () -> Bool,
         apply: @escaping (SyncState) -> Void) {
        self.key = key
        self.deviceID = deviceID
        self.backend = backend
        self.throttle = throttle
        self.snapshot = snapshot
        self.canSync = canSync
        self.apply = apply
    }

    func start() {
        backend.setObserver(forKey: key) { [weak self] in self?.pull() }
        pull()
        publishNow()
    }

    func stop() {
        backend.setObserver(forKey: key, nil)
        scheduled?.cancel()
        scheduled = nil
    }

    /// Call after every save. Writes are coalesced so quick answers do not flood iCloud.
    func publish() {
        guard canSync() else { return }
        if throttle <= 0 {
            publishNow()
            return
        }
        guard scheduled == nil else { return }
        let delay = UInt64(throttle * 1_000_000_000)
        scheduled = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, let self else { return }
            self.scheduled = nil
            self.publishNow()
        }
    }

    func pull() {
        guard canSync(), let data = backend.read(key) else { return }
        guard let payload = try? JSONDecoder().decode(SyncPayload.self, from: data),
              payload.isValid else {
            ignoredRemoteData = true
            return
        }
        ignoredRemoteData = false
        let current = snapshot()
        let merged = SyncMerge.merged(current, with: payload, deviceID: deviceID)
        // `apply` saves, which publishes the merged state, so the other devices converge.
        if merged != current { apply(merged) }
    }

    private func publishNow() {
        guard canSync() else { return }
        let payload = SyncMerge.payload(for: snapshot(), deviceID: deviceID)
        guard let data = try? Self.encoder.encode(payload), data != lastPublished else { return }
        backend.write(data, forKey: key)
        lastPublished = data
    }
}
