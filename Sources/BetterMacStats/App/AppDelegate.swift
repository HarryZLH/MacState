import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settings: AppSettings!
    private var engine: StatsEngine!
    private var controller: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        syncSystemAppearance()
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"), object: nil)

        settings = AppSettings()
        engine = StatsEngine(settings: settings)
        controller = MenuBarController(settings: settings, engine: engine)
        controller.start()
    }
    @objc private func systemAppearanceChanged(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in self?.syncSystemAppearance() }
    }

    private func syncSystemAppearance() {
        // Read the global preference, never a per-app appearance override.
        // macOS updates this when automatic appearance changes at sunrise/sunset.
        let style = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleInterfaceStyle"] as? String
        NSApp.appearance = NSAppearance(named: style == "Dark" ? .darkAqua : .aqua)
        for window in NSApp.windows {
            window.appearance = nil
            window.contentView?.needsDisplay = true
        }
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
