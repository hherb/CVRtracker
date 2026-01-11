import Foundation
import SwiftUI
import Combine

/// Manages iCloud sync preferences and status for the app.
///
/// This manager stores iCloud sync preferences in UserDefaults (not in SwiftData)
/// because the preference must be read before the SwiftData container is configured.
///
/// ## Important Notes
///
/// - Changing the iCloud sync setting requires an app restart to take effect
/// - The preference is stored locally and not synced between devices
/// - Each device can independently choose whether to sync to iCloud
///
/// ## Privacy Considerations
///
/// When iCloud sync is disabled (default), all data stays on the device only.
/// When enabled, data is synced to the user's iCloud account and can be accessed
/// from any of their Apple devices running this app.
@MainActor
class iCloudSyncManager: ObservableObject {
    /// UserDefaults key for the iCloud sync enabled preference
    private static let iCloudSyncEnabledKey = "iCloudSyncEnabled"

    /// UserDefaults key for tracking if user has been shown the restart prompt
    private static let pendingRestartKey = "iCloudSyncPendingRestart"

    /// Shared instance for accessing iCloud sync settings
    static let shared = iCloudSyncManager()

    /// Whether iCloud sync is currently enabled.
    ///
    /// This reflects the saved preference. Changes require app restart to take effect.
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.iCloudSyncEnabledKey)
            if isEnabled != oldValue {
                pendingRestart = true
            }
        }
    }

    /// Whether the user needs to restart the app for changes to take effect.
    @Published var pendingRestart: Bool {
        didSet {
            UserDefaults.standard.set(pendingRestart, forKey: Self.pendingRestartKey)
        }
    }

    /// The current sync status
    @Published var syncStatus: SyncStatus = .idle

    /// Sync status for displaying in the UI
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case error(String)
    }

    /// Initializes the manager and loads saved preferences.
    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.iCloudSyncEnabledKey)
        self.pendingRestart = UserDefaults.standard.bool(forKey: Self.pendingRestartKey)
    }

    /// Returns whether iCloud sync should be used for the current app session.
    ///
    /// This is determined at app launch and doesn't change during the session,
    /// ensuring container configuration remains consistent.
    static var shouldUseiCloud: Bool {
        UserDefaults.standard.bool(forKey: iCloudSyncEnabledKey)
    }

    /// Clears the pending restart flag (call after app launches with new setting)
    func clearPendingRestart() {
        pendingRestart = false
    }

    /// Checks if iCloud is available on this device.
    ///
    /// Returns true if the user is signed into iCloud and has iCloud Drive enabled.
    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    /// Enables iCloud sync after confirming with the user.
    ///
    /// - Parameter completion: Called with true if sync was enabled, false if cancelled
    func enableSync() {
        guard isAvailable else {
            syncStatus = .error("iCloud not available")
            return
        }
        isEnabled = true
    }

    /// Disables iCloud sync.
    ///
    /// Note: Existing data in iCloud is not deleted. The device simply stops syncing.
    func disableSync() {
        isEnabled = false
    }
}
