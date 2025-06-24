import Foundation
import AppKit

/**
 * LaunchAtLogin - A simplified utility class for managing app launch at login
 *
 * This implementation uses a simple AppleScript approach rather than SMAppService,
 * allowing it to work without special entitlements or code signing requirements.
 */
final class LaunchAtLogin {
    /// Shared singleton instance
    static let shared = LaunchAtLogin()
    
    /// Store user preference in UserDefaults
    private let defaults = UserDefaults.standard
    private let launchAtLoginKey = "launchAtLoginEnabled"
    private let appURL: URL
    
    /// Initializer that can be used to create new instances
    init() {
        // Get the URL to the current app
        self.appURL = Bundle.main.bundleURL
        
        // Initialize defaults if needed
        if defaults.object(forKey: launchAtLoginKey) == nil {
            defaults.set(false, forKey: launchAtLoginKey)
        }
    }
    
    /// Returns whether the app is set to launch at login
    var isEnabled: Bool {
        // First check the actual login items (most accurate)
        let actualState = isInLoginItems()
        let savedState = defaults.bool(forKey: launchAtLoginKey)
        
        // If there's a mismatch, update our saved state to match reality
        if actualState != savedState {
            defaults.set(actualState, forKey: launchAtLoginKey)
            return actualState
        }
        
        return savedState
    }
    
    /// Toggles the launch at login setting
    @discardableResult
    func toggle() -> Bool {
        let currentState = isEnabled
        
        // Set to the opposite state
        let newState = !currentState
        
        // Update the user preference
        defaults.set(newState, forKey: launchAtLoginKey)
        
        // Try to update the actual login item using AppleScript
        if newState {
            addToLoginItems()
        } else {
            removeFromLoginItems()
        }
        
        return newState
    }
    
    // MARK: - Private Methods
    
    /// Add the app to login items using AppleScript
    private func addToLoginItems() {
        let appPath = appURL.path
        
        // Create an AppleScript that adds the app to login items
        let script = """
        tell application "System Events"
            make new login item at end with properties {path:"\(appPath)", hidden:false}
        end tell
        """
        
        executeAppleScript(script)
    }
    
    /// Remove the app from login items using AppleScript
    private func removeFromLoginItems() {
        let appPath = appURL.path
        
        // Create an AppleScript that removes the app from login items
        let script = """
        tell application "System Events"
            delete (every login item whose path is "\(appPath)")
        end tell
        """
        
        executeAppleScript(script)
    }
    
    /// Execute an AppleScript and handle errors
    private func executeAppleScript(_ script: String) {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        // Silently handle errors - could add minimal error handling if needed
    }
    
    /// Check if the app is currently in login items
    private func isInLoginItems() -> Bool {
        let appPath = appURL.path
        let script = """
        tell application "System Events"
            return (exists (every login item whose path is "\(appPath)"))
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        if let result = appleScript?.executeAndReturnError(&error) {
            return result.booleanValue
        }
        
        // Fall back to UserDefaults if the AppleScript fails
        return defaults.bool(forKey: launchAtLoginKey)
    }
}
