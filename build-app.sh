#!/bin/zsh
# 编译并打包成 CleanSlate.app（ad-hoc 签名）
set -euo pipefail

VERSION=1.0.1
BUILD=2
cd "$(dirname "$0")"

# 同时编译 Apple 芯片和 Intel 两种架构
swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/CleanSlate"

APP=build/CleanSlate.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/CleanSlate"
cp Resources/AppIcon.icns Resources/Mascot.png Resources/wechat-pay.jpg Resources/alipay.jpg "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>CleanSlate</string>
    <key>CFBundleIdentifier</key><string>local.cleanslate</string>
    <key>CFBundleName</key><string>CleanSlate</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD" "$APP/Contents/Info.plist"

xattr -cr "$APP"
codesign --force --sign - "$APP"
echo "Built $PWD/$APP"

# ./build-app.sh --install：装到 /Applications，并删掉 build 里的副本，避免出现两个
if [[ "${1:-}" == "--install" ]]; then
    osascript -e 'quit app "CleanSlate"' 2>/dev/null || true
    rm -rf /Applications/CleanSlate.app
    ditto "$APP" /Applications/CleanSlate.app
    rm -rf "$APP"
    echo "Installed /Applications/CleanSlate.app"
fi
