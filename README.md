# MacScrollReverser

A lightweight macOS utility that reverses scrolling direction for trackpads while preserving system scrolling setting for mouse.

## Features

- **Selective Reversal**: Reverses scrolling direction for trackpad input
- **Mouse Preservation**: Maintains system setting scrolling behavior for mouse wheels
- **Menu Bar Integration**: Runs as a minimal menu bar application
- **Launch at Login**: Automatic startup with your Mac

## Requirements

- macOS 10.15 or later
- Accessibility permissions for event interception
- System Events permissions for login launch

## Installation

### Pre-built Release

1. Download the latest release from the Releases page
2. Move the app to your Applications folder
3. Launch the application
4. Grant accessibility permissions when prompted


## Build from source
1. Clone or download this repository
2. Run the build script:
   ```
   ./build_app.sh
   ```
4. Launch the app:
   double click ScrollerReverser.app
   or
   ```
   open -a ScrollReverser.app
   ```
5. move ScrollReverser.app to Applications folder
6. Grant accessibility permissions when prompted

## Usage

- The app runs as a menu bar application (look for the bi-directional arrow icon ↕️ in your menu bar)
- Click on the menu bar icon to adjust settings:
  - **Reverse Trackpad Scrolling**: Turn trackpad scroll reversal on or off
  - **Launch at Login**: Control whether the app starts automatically
- The app works transparently in the background once configured

## Project Structure

```
ScrollReverser/
├── main.swift              # Application entry point
├── AppDelegate.swift       # Main application logic and menu bar handling
├── LaunchAtLogin.swift     # Launch at login functionality
├── AppBundle-Info.plist    # App bundle configuration
├── build_app.sh            # Build script
└── README.md               # This file
```

## Technical Implementation

### Event Tap System
- Uses `CGEventTap` to intercept scroll events
- Monitors `kCGEventScrollWheel` events with `kCGHeadInsertEventTap` placement
- Requires accessibility permissions to function

### Device Detection
The app distinguishes between trackpad and mouse events to retain scrolling  animation
- Trackpads produce events with distinct scrollPhase and momentumPhase values that are absent in mouse wheel events

### Launch at Login
- Uses AppleScript-based approach for maximum compatibility
- No special entitlements required
- Works reliably across different macOS versions


## Troubleshooting

### App Won't Launch
- Ensure you have granted accessibility permissions in System Preferences > Privacy & Security > Privacy > Accessibility
- Try running the app from Terminal to see any error messages:
  ```bash
  open -a ScrollReverser.app
  ```

### Scrolling Not Reversed
- Check that the app is running (look for the icon in the menu bar)
- Verify accessibility permissions are granted
- Try toggling the "Enable" option in the menu bar menu

### Launch at Login Not Working
- Ensure you have system events permissions in System Settings > Privacy & Security > Automation > ScrollReverser
- You can manually add the app via shortcuts if needed

### Testing
Test the app with different input devices:
- Built-in trackpad
- Magic Trackpad
- USB/Bluetooth mice

## License

MIT License
