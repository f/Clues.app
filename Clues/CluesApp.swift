//
//  CluesApp.swift
//  Clues
//
//  Created by Fatih Kadir Akın on 26.12.2024.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit

@main
struct CluesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let modelContainer: ModelContainer
    
    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: Item.self, configurations: config)
        } catch {
            fatalError("Could not configure SwiftData container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .modelContainer(modelContainer)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
        .defaultPosition(.center)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            // Add About Menu
            CommandGroup(replacing: .appInfo) {
                Button("About Clues") {
                    let attributedString = NSMutableAttributedString(
                        string: "Created by ",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 12),
                            .foregroundColor: NSColor.textColor
                        ]
                    )
                    
                    let linkString = NSMutableAttributedString(
                        string: "Fatih Kadir Akın",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 12),
                            .link: NSURL(string: "https://x.com/fkadev")!,
                            .foregroundColor: NSColor.linkColor
                        ]
                    )
                    
                    let restOfString = NSMutableAttributedString(
                        string: " using AI tools",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 12),
                            .foregroundColor: NSColor.textColor
                        ]
                    )
                    
                    attributedString.append(linkString)
                    attributedString.append(restOfString)
                    
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: attributedString
                        ]
                    )
                }
            }
            
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NotificationCenter.default.post(
                        name: Notification.Name("NewFile"),
                        object: nil
                    )
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Open...") {
                    NotificationCenter.default.post(
                        name: Notification.Name("OpenFile"),
                        object: nil
                    )
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("Close") {
                    if let window = NSApp.keyWindow {
                        window.close()
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(
                        name: Notification.Name("SaveFile"),
                        object: nil
                    )
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Save As...") {
                    NotificationCenter.default.post(
                        name: Notification.Name("SaveAsFile"),
                        object: nil
                    )
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            // Edit Menu
            CommandGroup(after: .newItem) {
                Button("New Todo") {
                    NotificationCenter.default.post(
                        name: Notification.Name("NewTodo"),
                        object: nil
                    )
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            
            // View Menu
            CommandGroup(after: .windowSize) {
                Button("Toggle Full Screen") {
                    if let window = NSApp.keyWindow {
                        window.toggleFullScreen(nil)
                    }
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
            }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}

// Configure the NSApplication delegate to handle window behavior
class AppDelegate: NSObject, NSApplicationDelegate {
    private var sharedModelContainer: ModelContainer? {
        (NSApp.delegate as? CluesApp)?.modelContainer
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if NSApp.windows.isEmpty {
            createNewWindow()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            createNewWindow()
        }
        return true
    }
    
    private func createNewWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        if let modelContainer = sharedModelContainer {
            let contentView = NavigationStack {
                ContentView()
            }
            .modelContainer(modelContainer)
            
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
}
