.PHONY: help clean build-android build-ios build-macos build-linux build-dmg build-all release-android release-macos release-linux

APP_NAME := StillFlow
VERSION := $(shell grep '^version:' pubspec.yaml | awk '{print $$2}' | cut -d'+' -f1)
BUILD_NUMBER := $(shell grep '^version:' pubspec.yaml | awk '{print $$2}' | cut -d'+' -f2)

help:
	@echo "StillFlow - Build Commands"
	@echo ""
	@echo "Development:"
	@echo "  make clean              - Clean build artifacts"
	@echo ""
	@echo "Build:"
	@echo "  make build-android      - Build Android APK"
	@echo "  make build-ios          - Build iOS app (requires macOS)"
	@echo "  make build-macos        - Build macOS app"
	@echo "  make build-linux        - Build Linux app"
	@echo "  make build-dmg          - Build macOS DMG installer"
	@echo "  make build-all          - Build for all platforms"
	@echo ""
	@echo "Release:"
	@echo "  make release-android    - Build and prepare Android release"
	@echo "  make release-macos      - Build and prepare macOS release (app + dmg)"
	@echo "  make release-linux      - Build and prepare Linux release"
	@echo ""
	@echo "Current version: $(VERSION)+$(BUILD_NUMBER)"

clean:
	flutter clean
	rm -f *.apk *.dmg *.tar.gz
	rm -rf build/ releases/

build-android:
	@echo "Building Android APK..."
	flutter build apk --release
	@echo "✅ APK built: build/app/outputs/flutter-apk/app-release.apk"

build-ios:
	@echo "Building iOS app..."
	flutter build ios --release --no-codesign
	@echo "✅ iOS app built: build/ios/iphoneos/Runner.app"

build-macos:
	@echo "Building macOS app..."
	flutter build macos --release
	@echo "✅ macOS app built: build/macos/Build/Products/Release/$(APP_NAME).app"

build-linux:
	@echo "Building Linux app..."
	flutter build linux --release
	@echo "✅ Linux app built: build/linux/x64/release/bundle/"

build-dmg: build-macos
	@echo "Creating DMG installer..."
	@command -v create-dmg >/dev/null 2>&1 || { echo "Error: create-dmg not found. Install with: brew install create-dmg"; exit 1; }
	@rm -f StillFlow-$(VERSION).dmg
	create-dmg \
		--volname "$(APP_NAME)" \
		--window-pos 200 120 \
		--window-size 800 400 \
		--icon-size 100 \
		--icon "$(APP_NAME).app" 200 190 \
		--hide-extension "$(APP_NAME).app" \
		--app-drop-link 600 185 \
		"StillFlow-$(VERSION).dmg" \
		"build/macos/Build/Products/Release/$(APP_NAME).app"
	@echo "✅ DMG created: StillFlow-$(VERSION).dmg"

build-all: build-android build-macos build-linux build-dmg
	@echo "✅ All platforms built successfully!"

release-android: build-android
	@echo "Preparing Android release..."
	@mkdir -p releases
	@cp build/app/outputs/flutter-apk/app-release.apk releases/StillFlow-$(VERSION)-android.apk
	@echo "✅ Android release ready: releases/StillFlow-$(VERSION)-android.apk"
	@ls -lh releases/StillFlow-$(VERSION)-android.apk

release-macos: build-dmg
	@echo "Preparing macOS release..."
	@mkdir -p releases
	@cp StillFlow-$(VERSION).dmg releases/
	@echo "✅ macOS release ready: releases/StillFlow-$(VERSION).dmg"
	@ls -lh releases/StillFlow-$(VERSION).dmg

release-linux: build-linux
	@echo "Preparing Linux release..."
	@mkdir -p releases
	@cd build/linux/x64/release/bundle && tar -czf ../../../../../releases/StillFlow-$(VERSION)-linux-x64.tar.gz *
	@echo "✅ Linux release ready: releases/StillFlow-$(VERSION)-linux-x64.tar.gz"
	@ls -lh releases/StillFlow-$(VERSION)-linux-x64.tar.gz
