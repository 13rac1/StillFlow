# Plan: Layered Environmental Sound System with Stereo Spatialization

## Overview
Transform the current single-sound playback into a layered audio system where each environment has:
- **Base loop** (continuous ambient sound - existing files)
- **Environmental layers** (toggle on/off with independent volume control and stereo positioning)
- **Randomized events** (thunder, bird calls, etc. at natural intervals with spatial audio)

## Architecture Changes

### 1. Data Model Extensions (`lib/models/sound.dart`)
- Add `SoundLayer` class for individual audio layers:
  - `id`, `assetPath`, `layerType` (continuous/random)
  - `volumeRange` (min/max volume for variation)
  - `panRange` (left/right stereo positioning: -1.0 to 1.0)
  - `intervalRange` (for random events: min/max seconds)
- Add `EnvironmentSound` class extending `Sound` with:
  - Base sound reference
  - List of available layers
  - Default layer states (enabled/disabled)
  - Stereo field configuration
- Update `SoundLibrary` to use environment sounds

### 2. Audio Handler Refactor (`lib/services/audio_handler.dart`)
**Major changes:**
- Track multiple `SoundHandle` instances (base + layers) with stereo metadata
- Implement layer management:
  - `playEnvironment()` - plays base + enabled layers with stereo positioning
  - `toggleLayer()` - add/remove individual layer
  - `setLayerVolume()` - adjust layer volume independently
  - `setLayerPan()` - adjust stereo position (-1.0 left, 0.0 center, 1.0 right)
- Add randomization engine:
  - Timer-based system for random events
  - Randomized stereo positioning per event (birds on left/right, thunder panning)
  - Configurable intervals per layer type
  - One-shot playback for events with random pan position
- Utilize SoLoud's `setPan()` method for stereo control

### 3. Stereo Audio Implementation Details

**SoLoud Pan Control:**
- Use `_soloud.setPan(handle, pan)` where pan is -1.0 (left) to 1.0 (right)
- Apply to both continuous loops and random events
- Randomize pan for each event trigger to create spatial variety

**Stereo Positioning Strategy:**
- **Base loops:** Center (pan = 0.0)
- **Continuous layers:** Slight offset (-0.3 to 0.3 for subtle width)
- **Random events:** Full stereo field (-1.0 to 1.0)
  - Near thunder: Random pan, louder volume
  - Far thunder: Random pan, quieter volume, possible reverb
  - Birds: Randomize left/right/center on each chirp
  - Seagulls: Pan position changes between calls

**Example Stereo Configuration:**
```dart
// Rain environment
- Base rain: pan = 0.0 (center)
- Crickets: pan = -0.2 (slight left)
- Thunder near: random pan -1.0 to 1.0, volume 0.7-1.0
- Thunder far: random pan -1.0 to 1.0, volume 0.3-0.5
- Birds near: random pan -1.0 to 1.0, volume 0.6-0.9
```

### 4. UI Enhancements

**Sound Tile Widget (`lib/widgets/sound_tile.dart`):**
- Add expandable section for layer controls
- Show toggle switches for each available layer
- Volume sliders per layer (optional, future)
- Visual stereo field indicator (future: show pan position)

**New Widget: `EnvironmentDetailSheet` (bottom sheet/modal):**
- Detailed layer controls
- Visual mixer interface with stereo field visualization
- Pan position controls (optional advanced mode)
- Randomization settings toggle
- Preset management (future: save custom mixes)

**Home Screen (`lib/screens/home_screen.dart`):**
- Handle layer state changes
- Pass layer configuration to sound tiles
- Manage bottom sheet for detail view

### 5. Audio Assets Structure
```
assets/audio/
├── rain/
│   ├── base/
│   │   └── rain-ambience-stereo.ogg (existing, stereo)
│   ├── layers/
│   │   ├── thunder-near-1-stereo.ogg
│   │   ├── thunder-near-2-stereo.ogg
│   │   ├── thunder-far-1-stereo.ogg
│   │   ├── thunder-far-2-stereo.ogg
│   │   ├── crickets-loop-stereo.ogg
│   │   ├── pouring-rain-stereo.ogg
│   │   └── light-rain-stereo.ogg
├── water/
│   ├── base/
│   │   └── flowing-water-stereo.ogg (existing, stereo)
│   ├── layers/
│   │   ├── birds-near-chirp-1-stereo.ogg
│   │   ├── birds-near-chirp-2-stereo.ogg
│   │   ├── birds-far-song-stereo.ogg
│   │   ├── frogs-loop-stereo.ogg
│   │   └── wind-reeds-stereo.ogg
├── ocean/ (future)
│   ├── base/
│   │   └── surf-loop-stereo.ogg
│   ├── layers/
│   │   ├── seagulls-1-stereo.ogg
│   │   ├── seagulls-2-stereo.ogg
│   │   ├── bell-buoy-stereo.ogg
│   │   └── waves-rocks-stereo.ogg
```

**Audio File Requirements (Updated):**
- **Format:** OGG Vorbis with stereo channels
- **Sample Rate:** 44.1kHz
- **Channels:** 2 (stereo)
- **Bit Depth:** 16-bit minimum
- **Quality:** Variable bitrate, quality 6-8
- **Size:** 5-8MB per file (stereo typically larger than mono)

### 6. Stereo Recording/Sourcing Strategy
- Source true stereo recordings (not dual mono)
- For mono sources: Create stereo variants with natural ambience
- Multiple takes per event (2-3 thunder variants, bird chirp variants)
- Natural stereo field in recordings preferred over synthetic panning

## Implementation Phases

### Phase 1: Core Layer System with Stereo
1. Create new data models (SoundLayer with pan properties, EnvironmentSound)
2. Refactor audio handler to support multiple simultaneous handles
3. Implement basic layer playback with stereo positioning
4. Add `setPan()` integration for each handle
5. Update Sound model to reference base + 2-3 test layers with pan config
6. Test multi-layer stereo playback with existing audio files

### Phase 2: UI Controls
1. Add expandable layer controls to SoundTile
2. Create toggle switches for layer enable/disable
3. Implement layer volume controls
4. Add visual feedback for active layers
5. (Optional) Add stereo field visualization
6. Test UX flow on mobile devices with headphones

### Phase 3: Randomization Engine with Spatial Audio
1. Add Timer-based event system to audio handler
2. Implement randomized one-shot playback with random pan position
3. Configure interval ranges per layer type:
   - Thunder: 30-180 seconds (near), 60-300 seconds (far)
   - Birds: 15-60 seconds (near chirps), 120-300 seconds (far songs)
   - Seagulls: 20-90 seconds
4. Randomize pan (-1.0 to 1.0) on each event trigger
5. Add randomization toggle in UI
6. Test natural timing, overlaps, and stereo imaging

### Phase 4: Audio Asset Creation/Integration
1. Source or create stereo layer audio files (OGG Vorbis format, stereo)
2. Ensure all files are true stereo or properly spatialized
3. Add rain environment layers (thunder variants, crickets, intensity variants)
4. Add water environment layers (bird variants, frogs, wind)
5. Update asset manifest in pubspec.yaml
6. Test gapless looping for continuous stereo layers
7. Verify stereo field sounds natural in headphones/speakers

### Phase 5: Polish & Additional Environments
1. Add ocean surf environment with stereo tides/seagulls
2. Implement preset system (save favorite mixes with pan positions)
3. Add fade in/out when toggling layers
4. Volume normalization across stereo layers
5. Persistence (remember user's layer preferences and pan settings)
6. Advanced mode: User-adjustable pan controls (optional)

## Environment Sound Catalog (with Stereo Notes)

### Rain
- **Base:** Rain ambience (existing, stereo, centered)
- **Continuous loops:**
  - Crickets (stereo field, slight pan variation)
  - Pouring rain (stereo, centered or slight offset)
  - Light rain (stereo, centered)
  - Wind gusts (stereo with natural movement)
- **Random events (with pan randomization):**
  - Near thunder (random L/R, louder, 30-180s)
  - Far thunder (random L/R, quieter, 60-300s)
  - Dripping water (random L/R, occasional)

### Flowing Water
- **Base:** Flowing water (existing, stereo, centered)
- **Continuous loops:**
  - Frogs (stereo field positioning)
  - Wind in reeds (stereo with movement)
  - Background stream (stereo width)
- **Random events (with pan randomization):**
  - Near birds (random L/R/C, 15-60s)
  - Far birds (random L/R, quieter, 120-300s)
  - Splashing water (random L/R, occasional)

### Ocean Surf (Future)
- **Base:** Wave loop with stereo tide variation
- **Continuous loops:**
  - Gentle surf (stereo width)
  - Wind over dunes (stereo movement)
- **Random events (with pan randomization):**
  - Seagulls (random L/R/C, 20-90s, multiple variants)
  - Bell buoy (random L/R or fixed position, 180-600s)
  - Distant ship horn (random L/R, very far, 300-900s)

### Additional Environments (Future Consideration)
- **Forest:** Wind through trees (stereo), woodpecker (random pan), owls (L/R), deer movement (pan sweep)
- **Campfire:** Crackling fire (stereo center), wood popping (random pan), crickets (stereo field)
- **Desert Night:** Wind over sand (stereo movement), coyotes (random L/R distance)
- **Mountain Stream:** Fast water (stereo center), eagles (high pan + random L/R)
- **Cave:** Dripping water (random pan for depth), echoes (stereo reverb)
- **Meadow:** Breeze in grass (stereo width), bees (random close pan), birds (random distant pan)

## Technical Considerations

1. **Stereo Audio Quality:** All recordings must be true stereo (44.1kHz, 2-channel)
2. **Memory Management:** Load stereo layers on-demand, unload when not playing (2x mono size)
3. **Battery Impact:** Monitor CPU usage with multiple stereo timers/handles
4. **Audio Mixing:** SoLoud handles stereo mixing natively, ensure proper pan + volume normalization
5. **File Size:** Keep total app size reasonable (~80-120MB with stereo environments)
6. **Headphone Detection:** Optional - adjust stereo width for speakers vs headphones
7. **Backwards Compatibility:** Support simple playback for users who don't want complexity

## Testing Strategy
- Test stereo imaging on headphones (critical for spatial audio)
- Test on Android 6.0+, iOS 12.0+, macOS 10.14+
- Verify background playback with multiple stereo layers
- Test media controls with layered environments
- Battery usage testing with 8-hour stereo sessions
- Memory leak testing with layer toggling
- Audio synchronization testing (ensure no drift in stereo field)
- Verify natural stereo width on different playback devices
