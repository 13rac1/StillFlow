# StillFlow - Product Requirements Document

## Product Overview

**StillFlow** is an open-source Flutter application that brings nature's most calming audio directly to your device with seamless media controls and complete offline functionality. The app provides ambient sleep sounds with true gapless looping, targeting users seeking a simple, distraction-free sleep aid without ads or data collection.

**Platforms**: Android, iOS, and macOS (tested and working)

## Core Features

### Audio Playback
- **Built-in Sound Library**: Currently implemented ambient sounds:
  - Rain sounds - Gentle rain ambience
  - Flowing water - Peaceful stream sounds
  - Menu loop - Calm background music
- **Gapless Looping**: True gapless looping at the native level using flutter_soloud (no gaps between loop points)
- **System Media Integration**: Full integration with platform media controls:
  - Android: Notification panel with media controls
  - iOS: Control Center and lock screen controls
  - macOS: Native media controls in menu bar and Now Playing widget
- **Playback Controls**: Play, pause, and seamless sound switching
- **Background Playback**: Continues playing when app is minimized or screen is locked
- **Low Latency**: Responsive controls with minimal audio delay

### User Interface
- **Dark Mode Only**: Minimal, sleep-friendly interface with warm color palette
- **Simple Navigation**: Single-screen design with sound selection and basic controls
- **Visual Feedback**: Subtle animations for currently playing sound
- **Accessibility**: Screen reader support and large touch targets

### Technical Architecture
- **Flutter Framework**: Cross-platform development for Android, iOS, and macOS
- **Audio Engine**:
  - **flutter_soloud**: Native SoLoud integration for gapless, low-latency audio playback
  - **audio_service**: System integration for media controls and notifications
  - **audio_session**: Audio focus and session management
- **Media Controls**: Platform-specific media session handling via audio_service
- **Local Storage**: All audio files bundled with app installation (OGG Vorbis format)
- **Open Source**: AGPL-3.0 licensed with full source code availability on GitHub

## Platform-Specific Requirements

### Android (Tested ✅)
- **Minimum SDK**: Android 6.0 (API level 23)
- **Permissions**: WAKE_LOCK, FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK
- **Media Controls**: audio_service integration with MediaSession
- **Notification**: Rich media notification with play/pause controls
- **Package ID**: com.x13rac1.stillflow

### iOS (Tested ✅)
- **Minimum Version**: iOS 12.0
- **Background Audio**: AVAudioSession configuration for background playback
- **Control Center**: Integration with iOS Control Center media controls
- **Lock Screen**: Media controls on lock screen
- **App Icon**: iOS 18+ tinted mode support with grayscale icons
- **Bundle ID**: com.x13rac1.stillflow

### macOS (Tested ✅)
- **Minimum Version**: macOS 10.14
- **Media Controls**: Native macOS Now Playing integration
- **Menu Bar**: System media controls accessible from menu bar
- **Background Playback**: Continues playing when app is not focused
- **Bundle ID**: com.x13rac1.stillflow

## Non-Functional Requirements

### Performance
- **App Size**: ~15MB with bundled audio files and icons
- **Battery Optimization**: Efficient background processing with flutter_soloud
- **Memory Usage**: Minimal RAM footprint during playback
- **Audio Quality**: High-quality OGG Vorbis files (44.1kHz, stereo)
- **Gapless Playback**: Zero-gap looping at native level
- **Low Latency**: Responsive playback controls with minimal delay

### User Experience & Privacy
- **Launch Time**: App ready to play within 2 seconds
- **Complete Offline Functionality**: No internet connection required
- **Zero Data Collection**: No telemetry, analytics, or user tracking
- **Ad-Free Experience**: No advertisements or monetization
- **Reliability**: Robust local playback with proper error handling
- **Branding**: Custom water drop + ripples logo optimized for all platforms

## Audio Content Strategy

### Current Sound Library (v1.0)
- **Rain sounds** - Gentle rain ambience
- **Flowing water** - Peaceful stream sounds
- **Menu loop** - Calm background music

### Future Sound Expansions
- **Water Collection**: Ocean waves, gentle waterfall, babbling brook, rain on leaves
- **Forest Collection**: Wind through trees, cricket symphony, campfire crackling
- **Atmospheric Collection**: Desert wind, cave ambiance, mountain streams
- **Noise Generators**: Pink noise, brown noise, white noise

### Audio File Management
- **Format**: OGG Vorbis for gapless looping support and compression
- **Duration**: Seamless loops designed for flutter_soloud's gapless playback
- **File Size**: ~5-6MB per file (OGG compression)
- **Quality**: 44.1kHz sample rate, stereo
- **Compatibility**: Cross-platform support (Android, iOS, macOS)

## Open Source Considerations

### Development Philosophy
- **Community-Driven**: Accept contributions for new sounds and features
- **Transparency**: All development decisions documented publicly
- **No Vendor Lock-in**: Users own their experience completely
- **Educational Value**: Clean, well-documented Flutter code for learning

### Repository Structure
- **GitHub Repository**: Public repository with comprehensive documentation
- **Contribution Guidelines**: Clear guidelines for sound submissions and code contributions
- **Issue Tracking**: Public issue tracking for bugs and feature requests
- **Release Management**: Semantic versioning with release notes

## Success Metrics

### User Engagement
- **GitHub Stars**: Target 1,000+ stars within first year
- **Daily Active Users**: Target 70% retention after 7 days
- **Session Duration**: Average 6+ hours per session (overnight usage)
- **Community Contributions**: 10+ community-submitted sounds within 6 months

### Technical Performance
- **Crash Rate**: Less than 0.1% across all sessions
- **Audio Dropouts**: Zero audio interruptions during normal operation
- **Battery Impact**: Minimal battery drain compared to music streaming apps
- **Build Success**: 100% CI/CD success rate

## Development Timeline

### Phase 1 - Foundation (✅ Completed)
- Repository setup with comprehensive README
- Core Flutter app structure and navigation
- Audio playback implementation with flutter_soloud
- Basic UI with sound selection
- Android media session integration

### Phase 2 - Platform Integration (✅ Completed)
- iOS media session implementation
- macOS support and testing
- Background playback optimization
- Dark theme implementation
- Custom app icon design and integration

### Phase 3 - Audio Engine Migration (✅ Completed)
- Migration from just_audio to flutter_soloud
- Gapless looping implementation
- Audio file conversion to OGG format
- audio_service integration for media controls
- Error handling and hot restart support

### Phase 4 - Polish & Testing (✅ Completed)
- Comprehensive testing across Android, iOS, and macOS devices
- Package identifier updates (com.x13rac1.stillflow)
- App branding finalization (StillFlow)
- iOS 18+ tinted icon support
- Platform-specific icon optimization
- Documentation completion

### Future Phases
- **Phase 5**: Sleep timer functionality
- **Phase 6**: Expanded sound library
- **Phase 7**: F-Droid and app store releases
- **Phase 8**: Community contribution guidelines

## Current Status

**Version**: 1.0.0
**Platforms Tested**: Android 6.0+, iOS 12.0+, macOS 10.14+
**Audio Engine**: flutter_soloud with audio_service
**Key Achievement**: True gapless looping with full platform media control integration

This updated PRD reflects the current implementation using flutter_soloud for gapless audio, cross-platform support (Android, iOS, macOS), and the "StillFlow" branding while maintaining focus on privacy, offline functionality, and seamless media integration.
