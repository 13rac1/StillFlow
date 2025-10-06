# Plan: Layered Environmental Sound System with 3D Spatial Audio

## Overview
Transform the current single-sound playback into a layered audio system where each environment has:
- **Base loop** (continuous ambient sound - existing files)
- **Environmental layers** (toggle on/off with independent volume control and 3D positioning)
- **Randomized events** (thunder, bird calls, etc. at natural intervals with **dynamic 3D spatial audio**)

## 🎯 3D Spatial Audio Approach

### Why 3D Audio Instead of Simple Stereo Pan?

**Previous approach (completed in Phase 1-3):**
- Simple pan positioning (-1.0 to 1.0)
- Static left/right balance
- Stereo audio files

**NEW approach (Phase 3.5+):**
- ✅ **3D positional audio** using SoLoud's `play3d()`
- ✅ **Dynamic movement** (thunder rolling, birds flying)
- ✅ **Distance attenuation** (near/far sounds naturally quieter)
- ✅ **Doppler effects** for moving sounds
- ✅ **Mono audio files** (half the size!)
- ✅ **Immersive soundscape** (360° audio environment)

### 3D Coordinate System
```
         Y (up)
         |
         |
         |
         0------- X (right)
        /
       /
      Z (forward/back)

Listener at origin (0, 0, 0)
Looking toward -Z direction
```

## Architecture Changes

### 1. Data Model Extensions (`lib/models/sound.dart`)
- ✅ Add `SoundLayer` class for individual audio layers (COMPLETED)
- ✅ Add `EnvironmentSound` class extending `Sound` (COMPLETED)
- 🔄 **UPDATE:** Add 3D positioning fields to `SoundLayer`:
  - `movementType` enum (static, linear, circular, random)
  - `position3d` (Vector3 for static sounds)
  - `startPosition3d` / `endPosition3d` (for linear movement)
  - `circularPath` (center, radius, height for circular movement)
  - `minDistance` / `maxDistance` (attenuation range)
  - `dopplerFactor` (for moving sounds)

### 2. Audio Handler Refactor (`lib/services/audio_handler.dart`)
**Completed (Phase 1):**
- ✅ Track multiple `SoundHandle` instances (base + layers)
- ✅ Layer management (toggleLayer, setLayerVolume)
- ✅ Randomization engine with Timer-based events
- ✅ Simple pan positioning

**NEW (Phase 3.5 - 3D Upgrade):**
- 🔄 Initialize 3D listener: `set3dListenerPosition(0, 0, 0)`
- 🔄 Replace `play()` with `play3d(source, x, y, z)` for layers
- 🔄 Add position interpolation for moving sounds
- 🔄 Call `update3dAudio()` after position changes (20-30 Hz)
- 🔄 Implement `SoundMovement` classes:
  - `LinearMovement` - Thunder rolling across sky
  - `CircularMovement` - Seagulls circling overhead
  - `RandomWalk` - Butterflies, leaves drifting

### 3. 3D Audio Implementation Details

**Listener Setup:**
```dart
_soloud.set3dListenerPosition(0, 0, 0);  // Origin
_soloud.set3dListenerAt(0, 0, -1);       // Looking forward
_soloud.set3dListenerUp(0, 1, 0);        // Up is Y-axis
_soloud.update3dAudio();
```

**Sound Positioning Examples:**

**Base Loops (Centered):**
```dart
// Rain ambience at origin (close, centered)
await _soloud.play3d(audioSource, 0, 0, 0, volume: 1.0, looping: true);
```

**Continuous Layers (Positioned):**
```dart
// Crickets - random positions around listener
await _soloud.play3d(audioSource, x, 0, z, volume: 0.5, looping: true);
// x, z in range -10 to 10 (surrounding circle)

// Wind - slowly moving across space
await _soloud.play3d(audioSource, x, 2, -5, volume: 0.4, looping: true);
// Update position periodically for movement
```

**Random Events (Dynamic Movement):**
```dart
// Thunder rolling left to right across sky
Start: play3d(audioSource, -50, 20, -30)
// Interpolate position over 3-5 seconds
End: set3dSourcePosition(handle, 50, 20, -30)

// Bird flying across soundscape
Start: play3d(audioSource, 30, 10, -20)
// Interpolate with Doppler
End: set3dSourcePosition(handle, -30, 10, -20)

// Seagull circling overhead
Circular path: radius 15, center (0, 12, 0)
// Update position continuously
```

**Distance Attenuation:**
```dart
// Thunder (far away)
_soloud.set3dSourceMinMaxDistance(handle, 20.0, 100.0);
_soloud.set3dSourceAttenuation(handle, SoLoud.LINEAR_DISTANCE, 0.5);

// Birds (close)
_soloud.set3dSourceMinMaxDistance(handle, 1.0, 30.0);
_soloud.set3dSourceAttenuation(handle, SoLoud.LINEAR_DISTANCE, 1.0);

// Crickets (very close)
_soloud.set3dSourceMinMaxDistance(handle, 0.5, 15.0);
```

### 4. UI Enhancements

**Sound Tile Widget (`lib/widgets/sound_tile.dart`):**
- ✅ Expandable section for layer controls (COMPLETED)
- ✅ Toggle switches for each available layer (COMPLETED)
- ✅ Visual feedback for active layers (COMPLETED)
- Future: 3D position visualization (optional)

**Home Screen (`lib/screens/home_screen.dart`):**
- ✅ Handle layer state changes (COMPLETED)
- ✅ Pass layer configuration to sound tiles (COMPLETED)

### 5. Audio Assets Structure
```
assets/audio/
├── rain/
│   ├── base/
│   │   └── rain-ambience-mono.ogg (mono, for 3D positioning)
│   ├── layers/
│   │   ├── thunder-1-mono.ogg
│   │   ├── thunder-2-mono.ogg
│   │   ├── thunder-3-mono.ogg
│   │   ├── crickets-loop-mono.ogg
│   │   └── wind-gusts-mono.ogg
├── water/
│   ├── base/
│   │   └── flowing-water-mono.ogg
│   ├── layers/
│   │   ├── bird-chirp-1-mono.ogg
│   │   ├── bird-chirp-2-mono.ogg
│   │   ├── bird-chirp-3-mono.ogg
│   │   ├── frogs-mono.ogg
│   │   └── splash-mono.ogg
├── ocean/ (future)
│   ├── base/
│   │   └── ocean-waves-mono.ogg
│   ├── layers/
│   │   ├── seagull-1-mono.ogg
│   │   ├── seagull-2-mono.ogg
│   │   ├── bell-buoy-mono.ogg
│   │   └── ship-horn-mono.ogg
```

**Audio File Requirements (UPDATED FOR 3D AUDIO):**
- **Format:** OGG Vorbis
- **Channels:** **MONO (1 channel)** ← Changed from stereo!
- **Sample Rate:** 44.1kHz
- **Bit Depth:** 16-bit minimum
- **Quality:** Variable bitrate, quality 6-8
- **Size:** 2-4MB per file (smaller than stereo)

### 6. Audio Recording/Sourcing Strategy
- **Use mono recordings** - SoLoud positions them in 3D space
- Multiple takes per event (2-3 variants to avoid repetition)
- Natural recordings preferred (outdoor ambiences)
- Clean samples without reverb (3D engine adds space)

## Implementation Phases

### ✅ Phase 1: Core Layer System with Stereo (COMPLETED)
- ✅ Data models (SoundLayer, EnvironmentSound, LayerType)
- ✅ Multi-layer audio handler
- ✅ Simple stereo positioning with setPan()
- ✅ Tests passing, macOS build working

### ✅ Phase 2: UI Controls (COMPLETED)
- ✅ Expandable layer controls in SoundTile
- ✅ Toggle switches for layers
- ✅ Visual feedback for active layers
- ✅ State management with HomeScreen

### ✅ Phase 3: Randomization Engine (COMPLETED)
- ✅ Timer-based random events
- ✅ Random pan positioning
- ✅ Configurable intervals (shortened for testing: 3-15s)
- ✅ Console logging with emoji indicators

### 🔄 Phase 3.5: Upgrade to 3D Spatial Audio (IN PROGRESS)
1. Add 3D positioning data to SoundLayer model
2. Initialize 3D listener in audio handler
3. Replace `play()` with `play3d()` for all layers
4. Implement movement interpolation system
5. Add distance attenuation configuration
6. Test 3D positioning with headphones

### Phase 4: Audio Asset Creation/Integration
1. Convert/source MONO layer audio files (OGG Vorbis format)
2. Add rain environment layers (thunder, crickets, wind)
3. Add water environment layers (birds, frogs, splash)
4. Update asset manifest in pubspec.yaml
5. Configure 3D positions and movement paths
6. Test gapless looping and 3D imaging

### Phase 5: Polish & Additional Environments
1. Add ocean surf environment with 3D seagulls/waves
2. Implement movement patterns (linear, circular, random walk)
3. Add fade in/out when toggling layers
4. Volume normalization across layers
5. Persistence (remember user's layer preferences)
6. Additional environments (forest, campfire, desert, etc.)

## Environment Sound Catalog (with 3D Positioning)

### Rain
- **Base:** Rain ambience (0, 0, 0) - centered
- **Continuous loops:**
  - Crickets: Random positions in circle (radius 10, Y=0)
  - Wind: Slowly moving (-10 to 10, Y=2, Z=-5)
- **Random events (with 3D movement):**
  - Thunder: Linear movement (-50,20,-30) → (50,20,-30), 3-5s
  - Distance: 40-100 units (far, with attenuation)

### Flowing Water
- **Base:** Flowing water (0, -1, -3) - in front, slightly below
- **Continuous loops:**
  - Frogs: Semicircle positions (radius 8, Y=0, in front)
  - Wind in reeds: Positioned at (0, 1, -10)
- **Random events (with 3D movement):**
  - Birds: Linear flight (20,8,-15) → (-20,8,-15), 2-4s with Doppler
  - Splash: Random position in water area (±5, -1, -5 to -10)
  - Distance: 10-30 units (medium)

### Ocean Surf (Future)
- **Base:** Waves (0, -2, -5) - in front, low
- **Continuous loops:**
  - Wind: Moving across (-15 to 15, Y=3, Z=-8)
- **Random events (with 3D movement):**
  - Seagulls: Circular path overhead (radius 15, center (0,12,0))
  - Bell buoy: Fixed position (20, 0, -30) - far right
  - Ship horn: Very distant (0, 0, -100)
  - Distance: 8-25 units (close to medium)

### Additional Environments (Future Consideration)
- **Forest:** Woodpecker moving through trees, owls at specific positions
- **Campfire:** Crackling at center (0,0,0), wood popping randomly nearby
- **Desert Night:** Coyotes at varying distances, tumbleweeds passing by
- **Mountain Stream:** Water rushing past, eagles circling overhead
- **Cave:** Dripping water at random depths, echoes from walls
- **Meadow:** Bees buzzing around, birds at different heights

## Technical Considerations

1. **3D Audio Quality:** Mono files positioned in 3D space by SoLoud
2. **Memory Management:** Load mono layers on-demand (50% smaller than stereo)
3. **Battery Impact:** Monitor CPU with 3D position updates (20-30 Hz)
4. **Audio Mixing:** SoLoud handles 3D mixing, distance attenuation automatic
5. **File Size:** Much smaller app (~40-60MB with mono vs 80-120MB with stereo)
6. **Update Rate:** Call `update3dAudio()` at 20-30 Hz (not every frame)
7. **Active Sounds:** Limit to 8-10 3D sources for performance
8. **Headphones Required:** 3D audio works best with headphones

## Movement Patterns Implementation

### Linear Movement (Thunder, Birds)
```dart
class LinearMovement {
  final Vector3 start;
  final Vector3 end;
  final Duration duration;

  Vector3 getPosition(double progress) {
    return Vector3.lerp(start, end, progress);
  }
}
```

### Circular Movement (Seagulls)
```dart
class CircularMovement {
  final Vector3 center;
  final double radius;
  final double height;
  final double speed;

  Vector3 getPosition(double time) {
    final angle = time * speed;
    return Vector3(
      center.x + cos(angle) * radius,
      center.y + height,
      center.z + sin(angle) * radius,
    );
  }
}
```

### Random Walk (Butterflies)
```dart
class RandomWalk {
  Vector3 current;
  final Vector3 bounds;
  final double step;

  void update(double dt) {
    current += randomDirection() * step * dt;
    current = current.clampToBounds(bounds);
  }
}
```

## Testing Strategy
- ✅ Test simple pan on headphones (Phase 1-3 complete)
- 🔄 Test 3D positioning accuracy (Phase 3.5)
- 🔄 Test movement interpolation (thunder rolling, birds flying)
- 🔄 Test distance attenuation (far sounds quieter)
- 🔄 Test Doppler effects (fast-moving sounds pitch-shift)
- Test on Android 6.0+, iOS 12.0+, macOS 10.14+
- Verify background playback with 3D layers
- Memory leak testing with layer toggling
- Battery usage testing with 8-hour sessions
- **Critical: Test with headphones for full 3D effect**

## Migration from Phase 1-3 to 3D Audio

**Completed (Simple Pan):**
- Uses `setPan(handle, -1.0 to 1.0)`
- Random pan for events
- Static left/right positioning

**Upgrade to 3D (Phase 3.5):**
- Use `play3d(source, x, y, z)` instead of `play()`
- Random 3D positions instead of pan
- Dynamic movement with position interpolation
- Distance-based attenuation automatically

**Benefits:**
- ✅ More realistic and immersive
- ✅ Smaller file sizes (mono vs stereo)
- ✅ Dynamic movement (rolling, flying, circling)
- ✅ Professional-grade spatial audio
- ✅ Natural distance perception
