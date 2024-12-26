#!/bin/bash

# Required sizes for macOS app icons
sizes=(16 32 64 128 256 512 1024)

# Create AppIcon directory if it doesn't exist
mkdir -p "Clues/Assets.xcassets/AppIcon.appiconset"

# Generate each size using sips (macOS built-in image processing tool)
for size in "${sizes[@]}"; do
    # Ensure high quality output
    sips -s format png --resampleHeightWidth $size $size icon.png --out "Clues/Assets.xcassets/AppIcon.appiconset/icon_${size}x${size}.png"
done

# Also create an icns file for macOS
iconset="Clues/Assets.xcassets/AppIcon.iconset"
mkdir -p "$iconset"

# Copy files to iconset directory with macOS naming convention
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_16x16.png" "$iconset/icon_16x16.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$iconset/icon_16x16@2x.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$iconset/icon_32x32.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_64x64.png" "$iconset/icon_32x32@2x.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" "$iconset/icon_128x128.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$iconset/icon_128x128@2x.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$iconset/icon_256x256.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$iconset/icon_256x256@2x.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$iconset/icon_512x512.png"
cp "Clues/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png" "$iconset/icon_512x512@2x.png"

# Generate icns file
iconutil -c icns "$iconset"
mv "AppIcon.icns" "Clues/AppIcon.icns"

# Clean up temporary iconset
rm -rf "$iconset"

# Create Contents.json
cat > "Clues/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOL'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_64x64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOL