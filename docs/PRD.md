# Still Flow - Product Requirements Document

## Product Overview

**Still Flow** is an open-source Flutter mobile application that brings nature's most calming audio directly to your device with seamless media controls and complete offline functionality. The app provides ambient sleep sounds including rain, ocean waves, and pink noise, targeting users seeking a simple, distraction-free sleep aid without ads or data collection.

## Core Features

### Audio Playbook
- **Built-in Sound Library**: Core sounds include rain, ocean waves, pink noise, plus expanded natural soundscapes:
  - Water sounds: babbling brook, gentle waterfall, stream flowing, light rain on roof
  - Forest ambiance: wind through pine trees, cricket symphony, crackling campfire
  - Atmospheric: desert wind, cave ambiance, mountain stream with birds
- **System Media Integration**: Full integration with Android/iOS notification panel media controls
- **Playbook Controls**: Play, pause, volume adjustment, and seamless loop functionality
- **Sleep Timer**: Configurable auto-stop timer (15 min, 30 min, 1 hour, 2 hours, custom)
- **Background Playbook**: Continues playing when app is minimized or screen is locked

### User Interface
- **Dark Mode Only**: Minimal, sleep-friendly interface with warm color palette
- **Simple Navigation**: Single-screen design with sound selection and basic controls
- **Visual Feedback**: Subtle animations for currently playing sound
- **Accessibility**: Screen reader support and large touch targets

### Technical Architecture
- **Flutter Framework**: Cross-platform development for Android and iOS
- **Audio Engine**: Integration with `just_audio` package for robust playbook
- **Media Session**: Platform-specific media session handling
- **Local Storage**: All audio files bundled with app installation
- **Open Source**: MIT licensed with full source code availability on GitHub

## Platform-Specific Requirements

### Android
- **Minimum SDK**: Android 6.0 (API level 23)
- **Permissions**: WAKE_LOCK for background playbook
- **Media Controls**: Android MediaSession integration
- **Notification**: Rich media notification with album art and controls

### iOS
- **Minimum Version**: iOS 12.0
- **Background Audio**: AVAudioSession configuration for background playbook
- **Control Center**: Integration with iOS Control Center media controls
- **Lock Screen**: Media controls on lock screen

## Non-Functional Requirements

### Performance
- **App Size**: Target under 75MB with expanded bundled audio files
- **Battery Optimization**: Efficient background processing
- **Memory Usage**: Minimal RAM footprint during playbook
- **Audio Quality**: High-quality compressed audio files (AAC/MP3)

### User Experience & Privacy
- **Launch Time**: App ready to play within 2 seconds
- **Complete Offline Functionality**: No internet connection required
- **Zero Data Collection**: No telemetry, analytics, or user tracking
- **Ad-Free Experience**: No advertisements or monetization
- **Reliability**: 99.9% uptime for local playbook functionality

## Audio Content Strategy

### Expanded Sound Library
- **Primary Sounds**: Rain, ocean waves, pink noise, brown noise
- **Water Collection**: Gentle waterfall, babbling brook, stream flowing, rain on leaves
- **Forest Collection**: Wind through trees, cricket symphony, campfire crackling
- **Atmospheric Collection**: Desert wind, cave ambiance, mountain streams
- **Seasonal Blends**: Spring meadow, autumn forest, winter cabin ambiance

### Audio File Management
- **Format**: AAC or high-quality MP3 for optimal compression
- **Duration**: 10-30 minute seamless loops for each sound
- **File Size**: Individual files 8-15MB each
- **Quality**: 44.1kHz sample rate, stereo

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

### Phase 1 (Weeks 1-4)
- Repository setup with comprehensive README
- Core Flutter app structure and navigation
- Audio playbook implementation with just_audio
- Basic UI with initial sound selection
- Android media session integration

### Phase 2 (Weeks 5-8)
- iOS media session implementation
- Sleep timer functionality
- Background playbook optimization
- Expanded sound library integration
- Dark theme refinement

### Phase 3 (Weeks 9-12)
- Audio file optimization and bundling
- Comprehensive testing across devices
- F-Droid and app store preparation
- Documentation completion
- Community contribution guidelines

### Phase 4 (Weeks 13-16)
- Beta testing with community
- Performance optimization
- Accessibility improvements
- First stable release
- Marketing to open-source communities

This updated PRD reflects the open-source nature, expanded natural sound library, and the "Still Flow" branding while maintaining focus on privacy, offline functionality, and seamless media integration.
