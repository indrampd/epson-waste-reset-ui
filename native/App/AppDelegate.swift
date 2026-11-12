import Cocoa
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var viewModel: EWRViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        viewModel = EWRViewModel()

        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 1120, height: 760)
        let windowWidth: CGFloat = 1120
        let windowHeight: CGFloat = 760
        let originX = screenRect.origin.x + (screenRect.width - windowWidth) / 2
        let originY = screenRect.origin.y + (screenRect.height - windowHeight) / 2
        let rect = NSRect(x: originX, y: originY, width: windowWidth, height: windowHeight)

        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Epson Waste Reset (Native macOS)"
        window.minSize = NSSize(width: 900, height: 620)
        window.delegate = self

        let rootView = MainContentView(vm: viewModel)
        window.contentView = NSHostingView(rootView: rootView)

        setupMenus()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func setupMenus() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Tentang Epson Waste Reset", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Tutup", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit Menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Actions / Device Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "Perangkat")
        viewMenu.addItem(withTitle: "Pindai Ulang Perangkat", action: #selector(rescanDevices), keyEquivalent: "r")
        viewMenu.addItem(withTitle: "Baca Counter Printer", action: #selector(readCounters), keyEquivalent: "R")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Ganti Tema (Gelap/Terang)", action: #selector(toggleThemeAction), keyEquivalent: "t")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func rescanDevices() {
        Task { await viewModel.scanDevices(autoReadStatus: false) }
    }

    @objc func readCounters() {
        Task { await viewModel.readStatus() }
    }

    @objc func toggleThemeAction() {
        viewModel.toggleTheme()
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Epson Waste Reset (Native macOS)"
        alert.informativeText = "Antarmuka Native macOS (SwiftUI + AppKit) untuk RxNaison/Epson-Waste-Reset.\nBerjalan mandiri tanpa WebKit atau server Node.js.\nMendukung ~1450 model printer Epson."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.terminate(nil)
        return true
    }
}
