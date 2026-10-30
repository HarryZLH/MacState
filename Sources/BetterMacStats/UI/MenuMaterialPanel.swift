import AppKit

/// Uses the real system menu window; AppKit owns all material and edge rendering.
final class MenuMaterialPanel: NSObject, NSMenuDelegate {
    private let menu = NSMenu()
    private(set) var isShown = false
    var contentViewController: NSViewController?

    override init() {
        super.init()
        menu.autoenablesItems = false
        menu.delegate = self
    }

    func show(relativeTo rect: NSRect, of button: NSView, preferredEdge: NSRectEdge) {
        guard let controller = contentViewController else { return }
        let view = controller.view
        view.frame = NSRect(origin: .zero, size: view.fittingSize)
        let item = NSMenuItem()
        item.view = view
        menu.addItem(item)
        menu.popUp(positioning: nil, at: NSPoint(x: rect.minX, y: rect.maxY + 4), in: button)
    }

    func close() { menu.cancelTracking() }
    func menuWillOpen(_ menu: NSMenu) { isShown = true }
    func menuDidClose(_ menu: NSMenu) { isShown = false }
}
