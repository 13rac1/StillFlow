# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StillFlow is a Flutter ambient sound app for **sleep and study/focus** with true gapless audio looping, background playback, and full media control integration. Built with flutter_soloud for native-level gapless looping and audio_service for system media controls.

## Product Direction & Principles

StillFlow is a **continuous masking machine**: it plays layered ambient soundscapes indefinitely, for sleeping and for focused work. If the sound stops, the sleep or focus stops. Every design decision follows from that.

1. **There will NEVER be a sleep timer.** No timers, no fade-to-stop, no alarms, no scheduled stops, no "wind-down" features that end playback. These are anti-features — do not propose or implement them.
2. **Playback must survive indefinitely.** 8+ hour sessions are the normal case. Interruptions (calls, alarms, other apps) must auto-resume; long sessions must not leak memory, strand timers, or drain battery. If a Bluetooth route disappears mid-session, continuing on the device speaker is the *correct* behavior (masking continues) — never add media-app-style auto-pause on route change.
3. **Consistency over drama.** Soundscapes may evolve in *texture* but the overall masking level stays steady — no loudness swells, no lulls. The sound must never successfully demand attention. Random one-shot events (thunder, birds) should be user-controllable in density, down to zero.
4. **Desktop is first-class.** macOS and Linux are explicitly supported because study/focus happens at a desk. Never adopt a package that is web/mobile-only.
5. **Offline and private.** All audio ships in the app; no analytics, no accounts, no network.

**Near-term priorities** (in order): audio-interruption auto-resume; persistence + one-tap resume of the last mix; fade-in/out on play/pause/layer toggles; per-layer volume and event-density controls (configurable before playback starts); long-session soak audit; a brown/pink-noise + fan environment and a repeatable sound-curation pipeline; more environments (ocean, fireplace).

**Long-term:** true HRTF binaural rendering via a new open-source FFI package wrapping Steam Audio + miniaudio (working name `phonon_audio`). The plan lives in `docs/spatial-audio-package-plan.md` on the `spatial-audio-plan` branch. The current SoLoud 3D positioning is an interim step toward that.

**Key Technologies:**
- **flutter_soloud**: Native SoLoud integration for gapless, low-latency audio playback
- **audio_service**: Platform media controls (notifications, Control Center, lock screen)
- **audio_session**: Audio focus and session management
- **Flutter 3.9.2+** with Dart SDK

**Platforms Tested:** Android 6.0+, iOS 12.0+, macOS 10.14+, Linux

## Development Commands

### Running & Testing

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d ios
flutter run -d macos
flutter run -d android

# List available devices
flutter devices

# Run all tests (Linux: builds the desktop bundle first so the
# flutter_soloud native library is available — see Common Issues)
make test

# Run all tests directly (requires a prior Linux build)
LD_LIBRARY_PATH=$PWD/build/linux/<arch>/release/bundle/lib flutter test

# Run specific test file (pure model/widget tests need no native library)
flutter test test/models/sound_test.dart

# Clean build artifacts
flutter clean
```

### Building

Use the Makefile for builds (see `make help` for all commands):

```bash
# Build for specific platforms
make build-android      # Android APK
make build-ios          # iOS (requires macOS, no codesign)
make build-macos        # macOS app
make build-linux        # Linux app
make build-dmg          # macOS DMG installer (requires: brew install create-dmg)

# Prepare releases
make release-android    # Creates releases/StillFlow-{version}-android.apk
make release-macos      # Creates releases/StillFlow-{version}.dmg
make release-linux      # Creates releases/StillFlow-{version}-linux-x64.tar.gz

# Clean everything
make clean
```

Manual builds (if needed):
```bash
flutter build apk --release
flutter build ios --release
flutter build macos --release
flutter build linux --release
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format .
```

## Architecture

### Audio System (Critical Implementation Detail)

The app uses a **single audio handler** built on flutter_soloud and audio_service:

**SoLoudAudioHandler** (`lib/services/audio_handler.dart`)
   - Wraps flutter_soloud with audio_service's `BaseAudioHandler`
   - Manages gapless looping via SoLoud.instance, plus continuous and random one-shot layers
   - `initSoloud()` owns the full startup sequence: it configures the platform
     `AudioSession` (mix-with-others, Android audio attributes, focus gain)
     BEFORE calling `_soloud.init()`, and retries once (deinit/reinit) on failure
     to handle hot restart; it also sets up the 3D listener (at origin, facing -Z)
   - Spatializes audio with SoLoud's 3D voices (see Spatial Audio below):
     the base loop slowly orbits ("wander"), random one-shots play at random
     azimuths/distances, and thunder events sweep across the sky via
     per-voice roll timers
   - Timer lifecycle: wander/roll/random-event timers are cancelled in
     `pause()`/`stop()` and cancel-before-assign on duplicate `playSound()` —
     preserve this pattern when adding timed behavior
   - Updates media controls and notification state
   - Handles play/pause/stop commands from system controls
   - Uses `LoadMode.disk` for streaming long audio files

**Important:** The audio handler initialization requires:
- `WidgetsFlutterBinding.ensureInitialized()` before `AudioService.init()`
  (the `AudioService.init` from package:audio_service, which builds the handler)
- `AudioSession` configuration before SoLoud initialization (both inside `initSoloud()`)
- Error handling for hot restart scenarios (deinit/reinit pattern in `initSoloud()`)

### Project Structure

```
lib/
├── main.dart                     # App entry, MaterialApp with dark theme
├── models/
│   └── sound.dart               # Sound data model + SoundLibrary (built-in sounds)
├── screens/
│   └── home_screen.dart         # Main UI, audio handler initialization & state
├── services/
│   └── audio_handler.dart       # SoLoudAudioHandler (audio session + flutter_soloud + audio_service)
└── widgets/
    ├── sound_tile.dart          # Sound selection tile widget
    ├── equalizer_controls.dart  # Low-pass filter bottom sheet
    └── about_sheet.dart         # About/attribution bottom sheet

assets/
├── audio/                        # OGG Vorbis loops (5-6MB each, 44.1kHz stereo)
└── images/                       # App icons and branding (logo-1024.png, logo-ios-1024.png)
```

### Key Design Patterns

1. **Singleton Pattern**: Both audio services use singleton instances to ensure single audio engine instance
2. **State Management**: StatefulWidget with local state in HomeScreen (no external state management)
3. **Audio Session Handling**: Configured for playback with mix-with-others on iOS/Android
4. **Media Controls**: audio_service MediaItem and PlaybackState for notification/control integration

## Audio Implementation Details

### Gapless Looping

The core feature relies on flutter_soloud's native gapless looping:

```dart
final handle = await _soloud.play(
  audioSource,
  volume: 1.0,
  looping: true,           // Enable looping
  loopingStartAt: Duration.zero,  // Loop from beginning
);
```

**Critical:** Audio files MUST be in OGG Vorbis format for gapless support. MP3/M4A have gap issues.

### Spatial Audio (SoLoud 3D — interim)

Sounds are placed with `play3d()` / `set3dSourcePosition()`. Key facts learned from SoLoud's source (`soloud_core_3d.cpp`) that constrain how we use it:

- **SoLoud's 3D panning is game-style, not binaural.** Per-ear volume is
  `(dot(speaker_dir, source_dir) + 1) / 2` with default stereo speakers at
  normalized (±0.894, 0, 0.447). A source directly beside the listener gets a
  ~95/5 ear split (~25 dB) — far too harsh for a sleep app.
- **Therefore: keep positioned sources ahead of the listener.** The base-loop
  wander orbit is centered at z = -6 (in front), radius 2.0 × 1.5, which bounds
  the worst-case inter-ear ratio to ~4.6 dB. Don't move sources beside/behind
  the listener until HRTF lands.
- **Attenuation is OFF by default** (model 0 = no attenuation). Every 3D voice
  must call `set3dSourceMinMaxDistance()` + `set3dSourceAttenuation()` or
  distance is inaudible.
- **Keep 3D velocity at 0** — nonzero velocity engages doppler pitch-shift.
- Every 3D setter in flutter_soloud's bindings auto-calls `update3dAudio()`;
  no manual commit is needed.
- Tuning constants (orbit period/radii, one-shot distance ranges, thunder
  sweep/recede) are named constants at the top of `audio_handler.dart`.

### Audio File Requirements

- **Format:** OGG Vorbis (`.ogg` extension)
- **Quality:** 44.1kHz sample rate, stereo
- **Size:** 5-6MB per file (acceptable for offline app)
- **Location:** `assets/audio/` directory
- **Manifest:** Must be listed in `pubspec.yaml` under `flutter: assets:`

### Adding New Sounds

1. Add OGG file to `assets/audio/`
2. Create Sound constant in `lib/models/sound.dart` SoundLibrary class
3. Add to `SoundLibrary.all` list
4. Sound will automatically appear in UI

Example:
```dart
static const Sound oceanWaves = Sound(
  id: 'ocean_waves',
  name: 'Ocean Waves',
  assetPath: 'assets/audio/ocean-waves.ogg',
  description: 'Gentle ocean waves',
);
```

## Testing on Physical Devices

### Android Setup

1. Enable Developer Options: Settings → About Phone → Tap "Build Number" 7 times
2. Enable USB Debugging: Settings → Developer Options → USB Debugging
3. Connect via USB and approve "Allow USB debugging" prompt
4. Run: `flutter run`

**Test Background Audio:**
- Play a sound → Press home button → Verify audio continues
- Lock device → Verify audio continues
- Check notification panel → Tap play/pause controls
- Let audio play several minutes → Verify no gaps in loop

### iOS/macOS Setup

iOS requires Xcode and code signing. For testing:
```bash
flutter run -d ios
# Or open ios/Runner.xcworkspace in Xcode
```

macOS can run directly:
```bash
flutter run -d macos
```

**CocoaPods is removed.** All plugins resolve as Swift Packages, so the iOS and
macOS projects have no Podfile and no `[CP]` build phases. Contributors need a
Flutter version with Swift Package Manager support enabled. Do not reintroduce
Podfiles; if a future plugin lacks SwiftPM support, `flutter build` will say so
explicitly — treat that as a reason to pick a different plugin.

## Common Issues & Solutions

### Audio Initialization Failures

If you see "flutter_soloud already initialized" errors during hot restart:
- The code handles this with a deinit/reinit pattern in `SoLoudAudioHandler.initSoloud()`
- Check the retry logic in `lib/services/audio_handler.dart` (`initSoloud()` method)

### Media Controls Not Showing

Ensure:
- `AudioService.init()` is called before any playback
- `MediaItem` is set when playing (see `audio_handler.dart:67-73`)
- Platform permissions are configured (Android: FOREGROUND_SERVICE, iOS: Background Modes)

### Tests Fail with "Failed to load dynamic library 'libflutter_soloud_plugin.so'"

`flutter test` does not compile native plugin code, but any test that constructs
`SoLoudAudioHandler` loads flutter_soloud's native library over FFI. Build the
Linux desktop bundle first and put its `lib/` directory on `LD_LIBRARY_PATH` —
`make test` does both steps.

### Linux Build Failures (missing headers / wrong format)

- `fatal error: 'alsa/asoundlib.h' file not found` — install `libasound2-dev`
- `libFLAC.so: error adding symbols: file in wrong format` — flutter_soloud's
  bundled codec libraries are x86-64 only. On arm64 hosts install `libflac-dev
  libopus-dev libogg-dev libvorbis-dev` and build with
  `TRY_SYSTEM_LIBS_FIRST=1` (automatic via `make build-linux`).

### Build Failures

```bash
flutter clean
flutter pub get
flutter run
```

For Android ADB issues:
```bash
adb kill-server
adb start-server
adb devices
```

## Platform-Specific Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)
- Package: `com.x13rac1.stillflow`
- Permissions: WAKE_LOCK, FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK
- Min SDK: 23 (Android 6.0)

### iOS (`ios/Runner/Info.plist`)
- Bundle ID: `com.x13rac1.stillflow`
- Background Modes: audio
- Min iOS: 12.0

### macOS (`macos/Runner/Info.plist`)
- Bundle ID: `com.x13rac1.stillflow`
- Min macOS: 10.14

## Design System

The app uses a **dark-only theme** optimized for sleep:

- **Primary:** `#6B9AC4` (calm blue)
- **Secondary:** `#97C4B8` (soft teal)
- **Background:** `#0F0F1E` (very dark blue)
- **Surface:** `#1A1A2E` (dark blue-gray)
- **Material 3** design with rounded corners (12px radius)

Icons generated via `flutter_launcher_icons` package (configured in `pubspec.yaml`).

## Version Management

Version is managed in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Format: major.minor.patch+build
```

The Makefile extracts this for release naming automatically.
