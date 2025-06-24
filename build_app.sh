#!/bin/bash
# Build script for ScrollReverser app
#
# This is the primary build script for creating the ScrollReverser application bundle.
# It handles direct compilation of Swift source files and creates a proper app bundle
# with the necessary structure and Info.plist configuration.
#
# Usage: ./build_app.sh

# Set variables
APP_NAME="ScrollReverser"
BUILD_DIR="./.build"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building $APP_NAME..."

# Remove existing app bundle if it exists
if [ -d "$APP_DIR" ]; then
    echo "Removing existing app bundle..."
    rm -rf "$APP_DIR"
fi

# Create build directory
mkdir -p "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Compile the Swift files
echo "Compiling Swift files..."
swiftc -O -sdk $(xcrun --show-sdk-path) \
    -target x86_64-apple-macosx10.15 \
    -framework Cocoa -framework Carbon \
    -parse-as-library \
    AppDelegate.swift LaunchAtLogin.swift main.swift \
    -o "$MACOS_DIR/$APP_NAME"

# Check if compilation was successful
if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

# Copy Info.plist - use the special bundle info.plist
cp "AppBundle-Info.plist" "$CONTENTS_DIR/Info.plist"

# Create a simple PkgInfo file
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Make the binary executable
chmod +x "$MACOS_DIR/$APP_NAME"

# Create a simple icon file if doesn't exist
if [ ! -f "$RESOURCES_DIR/AppIcon.icns" ]; then
    touch "$RESOURCES_DIR/AppIcon.icns"
fi

# Check for any permission issues
chmod -R 755 "$APP_DIR"

echo "App built successfully at: $APP_DIR"
echo "You can now run the app with: open -a $APP_DIR"
