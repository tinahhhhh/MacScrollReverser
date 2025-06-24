import Cocoa

// Define a proper entry point using @main attribute
@main
struct ScrollReverserApp {
    static func main() {
        autoreleasepool {
            // Create and retain the delegate to avoid weak reference issues
            let delegate = AppDelegate()
            let app = NSApplication.shared
            app.delegate = delegate  

            // Set activation policy to accessory (menu bar app)
            app.setActivationPolicy(.accessory)

            // Activate the app
            app.activate(ignoringOtherApps: true)

            // Run the app's main event loop
            app.run()
        }
    }
}
