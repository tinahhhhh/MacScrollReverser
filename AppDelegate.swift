import Cocoa
import Carbon
import ApplicationServices

/**
 * TrackpadScrollReverser - A lightweight macOS utility that reverses the scrolling direction
 * for trackpad inputs while preserving the original behavior for mouse wheels.
 *
 * Key Features:
 * - Differentiates between trackpad and mouse inputs using event characteristics
 * - Reverses scrolling direction only for trackpad events
 * - Operates as a menu bar application with minimal resource usage
 * - Supports launch at login functionality
 */

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Properties
    
    /// Status bar menu item
    private var statusItem: NSStatusItem?
    
    /// Event tap for intercepting scroll events
    private var eventTap: CFMachPort?
    
    /// Run loop source for the event tap
    private var runLoopSource: CFRunLoopSource?
    
    /// Whether scrolling reversal is currently enabled
    private var reverseEnabled = true
    
    /// The dropdown menu for the status bar
    private let menu = NSMenu()

    // Create a new instance of LaunchAtLogin
    private let launchAtLogin = LaunchAtLogin()
    
    // Application Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Better launch at login detection
        let isLaunchedAtLogin = ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("launchd") ?? false
        
        if isLaunchedAtLogin {
            // For apps launched at login, add a delay before setting up event tap
            // This gives macOS time to apply saved permissions
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.setupMenuBar()
                self.setupEventTap()
            }
        } else {
            setupMenuBar()
            setupEventTap()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        cleanupEventTap()
    }
    
    // UI Setup
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuBarIcon()
        setupMenuItems()
    }
    
    private func setupMenuItems() {
        // Create menu items
        let enabledMenuItem = NSMenuItem(title: "Reverse Trackpad Scrolling", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledMenuItem.state = reverseEnabled ? .on : .off
        
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = launchAtLogin.isEnabled ? .on : .off

        // Add items to menu
        menu.addItem(enabledMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Trackpad Only (Mouse Unaffected)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func updateMenuBarIcon() {
        if reverseEnabled {
            statusItem?.button?.attributedTitle = NSAttributedString(
                string: "↕︎",
                attributes: [
                    .foregroundColor: NSColor.labelColor,
                    .font: NSFont.menuBarFont(ofSize: 20)
                ]
            )
        } else {
            statusItem?.button?.attributedTitle = NSAttributedString(
                string: "⊝",
                attributes: [
                    .foregroundColor: NSColor.disabledControlTextColor,
                    .font: NSFont.menuBarFont(ofSize: 20)
                ]
            )
        }
    }
    
    // Event Handling
    private func setupEventTap() {
        // Check if accessibility permissions are granted
        if !checkAccessibilityPermissions() {
            print("⚠️ Accessibility permissions not granted")
            // Show alert and guide user to grant permissions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showPermissionAlert()
            }
            return
        }

        print("Setting up event tap")
        
        // Capture scroll wheel events
        let eventMask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        
        // Create an event tap to intercept events
        guard let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type == .scrollWheel {
                    guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
                        return Unmanaged.passRetained(event)
                    }
                    return delegate.handleScrollEvent(event)
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        ) else {
            print("⚠️ Failed to create event tap")
            // Try again with a delay (for login item launches)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.setupEventTap()
            }
            return
        }
        
        print("Event tap created successfully")
        self.eventTap = eventTap
        
        // Create a run loop source and add to the current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: reverseEnabled)
        print("✅ Event tap setup successfully")
    }
    
    private func cleanupEventTap() {
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
    
    // Check if the app has accessibility permissions
    private func checkAccessibilityPermissions() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    // Show alert guiding user to enable accessibility permissions
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = "TrackpadScrollReverser needs accessibility permissions to function correctly.\n\nPlease go to System Settings > Privacy & Security > Accessibility and enable TrackpadScrollReverser."
        
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Quit")
        
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            // Open system settings
            let prefpaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(prefpaneURL)
            // Try again after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.setupEventTap()
            }
        case .alertSecondButtonReturn:
            // Retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.setupEventTap()
            }
        default:
            // Quit
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func showAccessibilityPermissionsAlert() {
        let alert = NSAlert()
        alert.messageText = "Unable to Create Event Tap"
        alert.informativeText = "TrackpadScrollReverser needs accessibility permissions to work. Please go to System Preferences > Security & Privacy > Privacy > Accessibility and add this app."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Quit")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open Security & Privacy preferences
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
        
        NSApplication.shared.terminate(self)
    }
    
    // Scroll Event Processing
    func handleScrollEvent(_ event: CGEvent) -> Unmanaged<CGEvent> {
        if !reverseEnabled {
            return Unmanaged.passRetained(event)
        }
        
        // Extract event characteristics for debugging and decision-making
        let deltaY = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
        let deltaX = event.getDoubleValueField(.scrollWheelEventDeltaAxis2)
        let pixelDeltaY = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        let pixelDeltaX = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
        let fixedDeltaY = event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let fixedDeltaX = event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2)
        let phase = event.getIntegerValueField(.scrollWheelEventScrollPhase)
        let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        let scrollCount = event.getIntegerValueField(.scrollWheelEventScrollCount)
        
        // Log event details
        logEventDetails(
            deltaY: deltaY, deltaX: deltaX,
            pixelDeltaY: pixelDeltaY, pixelDeltaX: pixelDeltaX,
            fixedDeltaY: fixedDeltaY, fixedDeltaX: fixedDeltaX,
            phase: phase, momentumPhase: momentumPhase,
            scrollCount: scrollCount
        )
        
        // Determine if this is from a trackpad
        let isTrackpad = isEventFromTrackpad(event)
        
        // Only modify trackpad events
        if isTrackpad {
            return reverseScrollDirection(
                event: event,
                deltaY: deltaY, deltaX: deltaX,
                pixelDeltaY: pixelDeltaY, pixelDeltaX: pixelDeltaX,
                fixedDeltaY: fixedDeltaY, fixedDeltaX: fixedDeltaX,
                phase: phase, momentumPhase: momentumPhase, 
                scrollCount: scrollCount
            )
        } else {
            // For mouse events, preserve the original scrolling direction
            print("🖱️ PASSING THROUGH MOUSE scroll event (not reversed)")
            print("=============== End Event ===============\n")
            return Unmanaged.passRetained(event)
        }
    }
    
    private func logEventDetails(
        deltaY: Double, deltaX: Double,
        pixelDeltaY: Double, pixelDeltaX: Double,
        fixedDeltaY: Int64, fixedDeltaX: Int64,
        phase: Int64, momentumPhase: Int64,
        scrollCount: Int64
    ) {
        print("\n=============== Scroll Event ===============")
        print("Line deltas: Y=\(deltaY), X=\(deltaX)")
        print("Pixel deltas: Y=\(pixelDeltaY), X=\(pixelDeltaX)")
        print("Fixed deltas: Y=\(fixedDeltaY), X=\(fixedDeltaX)")
        print("Phases: Scroll=\(phase), Momentum=\(momentumPhase)")
        print("ScrollCount: \(scrollCount)")
        
        // Print fractional parts for more detailed analysis
        let yFractional = deltaY.truncatingRemainder(dividingBy: 1.0)
        let pixelYFractional = pixelDeltaY.truncatingRemainder(dividingBy: 1.0)
        print("Fractional parts: deltaY=\(yFractional), pixelY=\(pixelYFractional)")
    }
    
    private func reverseScrollDirection(
        event: CGEvent, 
        deltaY: Double, deltaX: Double, 
        pixelDeltaY: Double, pixelDeltaX: Double, 
        fixedDeltaY: Int64, fixedDeltaX: Int64, 
        phase: Int64, momentumPhase: Int64, 
        scrollCount: Int64
    ) -> Unmanaged<CGEvent> {
        print("✅ REVERSING TRACKPAD scroll direction")
        
        // Make a copy of the event to avoid modifying the original
        guard let eventCopy = event.copy() else {
            return Unmanaged.passRetained(event)
        }
        
        // Reverse all delta values consistently
        eventCopy.setDoubleValueField(.scrollWheelEventDeltaAxis1, value: -deltaY)
        eventCopy.setDoubleValueField(.scrollWheelEventDeltaAxis2, value: -deltaX)
        eventCopy.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: -pixelDeltaY)
        eventCopy.setDoubleValueField(.scrollWheelEventPointDeltaAxis2, value: -pixelDeltaX)
        eventCopy.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedDeltaY)
        eventCopy.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -fixedDeltaX)
        
        // Preserve phase information for gesture continuity
        eventCopy.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase)
        eventCopy.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentumPhase)
        eventCopy.setIntegerValueField(.scrollWheelEventScrollCount, value: scrollCount)
        
        print("    Y: \(deltaY) → \(-deltaY)")
        print("    Pixel Y: \(pixelDeltaY) → \(-pixelDeltaY)")
        print("=============== End Event ===============\n")
        
        return Unmanaged.passRetained(eventCopy)
    }
    
    // Device Detection
    private func isEventFromTrackpad(_ event: CGEvent) -> Bool {
        // Extract relevant event characteristics
        let phase = event.getIntegerValueField(.scrollWheelEventScrollPhase)
        let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        
        // DEFINITE TRACKPAD INDICATORS
        // Phase information is the most reliable trackpad indicator
        if phase != 0 || momentumPhase != 0 {
            print("DEFINITE TRACKPAD: Has phase/momentum phase information")
            return true
        }
        
        return false
    }
    
    // Actions
    @objc func toggleEnabled() {
        reverseEnabled = !reverseEnabled
        
        // Update menu item state
        if let menuItem = menu.item(at: 0) {
            menuItem.state = reverseEnabled ? .on : .off
        }
        
        // Update the menu bar icon to show enabled/disabled state
        updateMenuBarIcon()
        
        // Enable or disable the event tap
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: reverseEnabled)
            print("Event tap \(reverseEnabled ? "enabled" : "disabled")")
        }
    }
    
    @objc func toggleLaunchAtLogin() {
        // Try to toggle and get new status
        let isEnabled = launchAtLogin.toggle()
        
        // Update the menu item
        if let menuItem = menu.item(at: 4) {
            menuItem.state = isEnabled ? .on : .off
        }
    }
}
