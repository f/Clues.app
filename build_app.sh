#!/bin/bash

# Exit if any command fails
set -e

rm -rf build

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "🏗️  Building Clues.app..."

# Create build directory
mkdir -p build

# Determine if this is a CI build
if [ "$CI" = "true" ]; then
    echo "📦 Running CI build..."
    
    # Build without code signing for CI
    xcodebuild -scheme "Clues" \
        -configuration Release \
        -derivedDataPath build \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
        
    # Move app to build directory
    mv build/Build/Products/Release/Clues.app build/
else
    echo "📦 Running local development build..."
    
    # Build with default code signing for local development
    xcodebuild -scheme "Clues" \
        -configuration Release \
        -derivedDataPath build
        
    # Move app to build directory
    mv build/Build/Products/Release/Clues.app build/
fi

echo "✅ App built successfully"

# Create DMG if create-dmg is available
if command -v create-dmg &> /dev/null; then
    echo "📀 Creating DMG..."
    
    # Remove existing DMG if it exists
    rm -f "$SCRIPT_DIR/Clues.dmg"
    
    create-dmg \
        --volname "Clues" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "Clues.app" 200 190 \
        --app-drop-link 400 190 \
        "$SCRIPT_DIR/Clues.dmg" \
        "$SCRIPT_DIR/build/Clues.app"
        
    echo "✅ DMG created successfully at: $SCRIPT_DIR/Clues.dmg"
else
    echo "⚠️  create-dmg not found. Install with: brew install create-dmg"
    echo "✅ Build complete without DMG"
    exit 0
fi

echo "🎉 Build complete! Your app is in: $SCRIPT_DIR/build/Clues.app"
echo "📦 Installer available at: $SCRIPT_DIR/Clues.dmg" 