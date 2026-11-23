import AppKit
import OSLog
import UserNotifications

@MainActor
final class CompletionNotifications: NSObject, UNUserNotificationCenterDelegate {
    static let shared = CompletionNotifications()

    private let center: UNUserNotificationCenter? = Bundle.main.bundleIdentifier == nil ? nil : .current()
    private let logger = Logger(subsystem: "com.iroblesrazzaq.rallyclip", category: "CompletionNotifications")
    private var authorization: Task<Void, Never>?
    private var unreadCount = 0

    var isForeground: Bool {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier
    }

    func prepare() {
        guard let center, authorization == nil else { return }
        center.delegate = self
        authorization = Task {
            _ = try? await center.requestAuthorization(options: [.alert])
        }
    }

    func post(title: String, body: String) {
        if !isForeground {
            unreadCount += 1
            NSApp.dockTile.badgeLabel = String(unreadCount)
            logger.notice("Dock completion badge: \(NSApp.dockTile.badgeLabel ?? "none", privacy: .public)")
        }

        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        Task {
            await authorization?.value
            try? await center.add(request)
        }
    }

    func clearBadge() {
        guard unreadCount > 0 else { return }
        unreadCount = 0
        NSApp.dockTile.badgeLabel = nil
        logger.notice("Dock completion badge: \(NSApp.dockTile.badgeLabel ?? "none", privacy: .public)")
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
