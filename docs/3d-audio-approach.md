# 3D Spatial Audio Approach

## Overview

Instead of using pre-recorded stereo files with simple pan positioning, we'll create a **dynamic 3D audio environment** using SoLoud's spatial audio capabilities. This allows for:

- Realistic sound positioning in 3D space
- Dynamic movement (thunder rolling, birds flying)
- Distance-based attenuation (near/far naturally)
- Doppler effects for moving sounds
- More immersive soundscapes

## Audio File Requirements - UPDATED

### Format Changes
- **Format:** OGG Vorbis (.ogg)
- **Channels:** **MONO (1 channel)** ← Changed from stereo!
- **Sample Rate:** 44.1kHz
- **Bit Depth:** 16-bit minimum
- **Quality:** Variable bitrate, quality 6-8
- **File Size:** 2-4MB per file (smaller than stereo)

### Why Mono?
1. **Lighter files** - Half the size of stereo
2. **More flexible** - SoLoud positions them in 3D space
3. **Better control** - Can move sounds dynamically
4. **Realistic** - Distance attenuation works naturally

## 3D Audio Architecture

### Listener Setup (Player Position)
```dart
// Set listener at origin (center of soundscape)
_soloud.set3dListenerPosition(0, 0, 0);
_soloud.set3dListenerAt(0, 0, -1);  // Looking forward
_soloud.set3dListenerUp(0, 1, 0);   // Up is Y-axis
_soloud.update3dAudio();
```

### Sound Positioning Strategy

#### Base Loops (Ambient)
- Position at **origin (0, 0, 0)** - centered, close
- No movement
- Examples: rain ambience, water flow

#### Continuous Layers
- Position in **surrounding space**
- Examples:
  - Crickets: Random positions around listener (-5 to 5, ground level)
  - Wind: Moving slowly across space
  - Frogs: Positioned near water (specific coordinates)

#### Random Events (Dynamic)
- **Thunder:** Start far away, move across sky
  ```dart
  // Thunder rolling from left to right, high up
  Start: (-50, 20, -30)
  End:   (50, 20, -30)
  Duration: 3-5 seconds with position interpolation
  ```

- **Birds:** Fly across the soundscape
  ```dart
  // Bird flying from right to left
  Start: (30, 10, -20)
  End:   (-30, 10, -20)
  Duration: 2-4 seconds with Doppler effect
  ```

- **Seagulls:** Circle overhead
  ```dart
  // Seagull in circular path
  Radius: 20 units
  Height: 15 units (above listener)
  Speed: Variable
  ```

### Distance Attenuation

```dart
// Thunder (far away)
_soloud.set3dSourceMinMaxDistance(handle, 20.0, 100.0);
_soloud.set3dSourceAttenuation(handle, SoLoud.LINEAR_DISTANCE, 0.5);

// Birds (close)
_soloud.set3dSourceMinMaxDistance(handle, 1.0, 30.0);
_soloud.set3dSourceAttenuation(handle, SoLoud.LINEAR_DISTANCE, 1.0);
```

### Attenuation Models
- **LINEAR_DISTANCE** - Natural falloff
- **INVERSE_DISTANCE** - Realistic distance
- **EXPONENTIAL_DISTANCE** - Dramatic falloff

## Implementation Plan

### Phase 3.5: Upgrade to 3D Audio (New Phase)

1. **Update Audio Handler** (`lib/services/audio_handler.dart`)
   - Initialize 3D listener on startup
   - Add `play3d()` support for layers
   - Implement position interpolation for moving sounds
   - Add `update3dAudio()` calls after position changes

2. **Create Sound Movement System**
   - `SoundPath` class for movement patterns
   - Linear paths (thunder rolling)
   - Circular paths (seagulls)
   - Random walks (butterflies, leaves)

3. **Update Random Event Scheduler**
   - Generate random start/end positions
   - Interpolate position over event duration
   - Apply Doppler factor for fast-moving sounds

4. **Update Data Models** (`lib/models/sound.dart`)
   - Add `SoundMovement` enum (static, linear, circular, random)
   - Add 3D positioning parameters to `SoundLayer`
   - Define min/max distance ranges

## Coordinate System

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

### Environment Layout Examples

#### Rain Environment
```
Thunder:
- Start: (-50, 20, -20) to (50, 20, -20)  [high, far, moving L→R]
- Distance: 40-100 units (far)

Crickets:
- Positions: Random in circle radius 10, Y=0 (ground level)
- Distance: 5-15 units (close)
```

#### Water Environment
```
Birds:
- Start: (20, 8, -15) to (-20, 8, -15)  [medium height, flying L→R]
- Distance: 10-30 units (medium)

Frogs:
- Positions: Random in semicircle radius 8, Y=0 (ground, in front)
- Distance: 3-12 units (close)
```

#### Ocean Environment
```
Seagulls:
- Circular path: radius 15, center (0, 12, 0)  [overhead]
- Distance: 8-25 units (close to medium)

Waves:
- Position: (0, -2, -5)  [in front, low]
- Distance: 1-10 units (very close)
```

## Audio File Requirements by Layer

### Rain Environment

**Base:**
- `rain-ambience-mono.ogg` - Mono rain loop

**Continuous Layers (Mono):**
- `crickets-loop-mono.ogg` - Single cricket ambience
- `wind-gusts-mono.ogg` - Wind sound

**Random Events (Mono):**
- `thunder-1-mono.ogg` - Thunder clap/rumble
- `thunder-2-mono.ogg` - Thunder variant
- `thunder-3-mono.ogg` - Thunder variant

### Water Environment

**Base:**
- `flowing-water-mono.ogg` - Mono water loop

**Continuous Layers (Mono):**
- `frogs-mono.ogg` - Single frog croak
- `wind-reeds-mono.ogg` - Wind through reeds

**Random Events (Mono):**
- `bird-chirp-1-mono.ogg` - Bird chirp
- `bird-chirp-2-mono.ogg` - Different bird
- `bird-chirp-3-mono.ogg` - Third variant
- `splash-mono.ogg` - Water splash

### Ocean Environment

**Base:**
- `ocean-waves-mono.ogg` - Mono wave loop

**Continuous Layers (Mono):**
- `wind-ocean-mono.ogg` - Ocean wind

**Random Events (Mono):**
- `seagull-1-mono.ogg` - Seagull call
- `seagull-2-mono.ogg` - Seagull variant
- `bell-buoy-mono.ogg` - Bell buoy
- `ship-horn-mono.ogg` - Distant horn

## Movement Patterns

### Linear Movement (Thunder, Birds)
```dart
class LinearMovement {
  Vector3 start;
  Vector3 end;
  Duration duration;

  Vector3 getPosition(double progress) {
    return start.lerp(end, progress);
  }
}
```

### Circular Movement (Seagulls)
```dart
class CircularMovement {
  Vector3 center;
  double radius;
  double height;
  double speed;
  double startAngle;

  Vector3 getPosition(double time) {
    final angle = startAngle + (time * speed);
    return Vector3(
      center.x + cos(angle) * radius,
      center.y + height,
      center.z + sin(angle) * radius,
    );
  }
}
```

### Random Walk (Butterflies, Leaves)
```dart
class RandomWalk {
  Vector3 current;
  Vector3 bounds;
  double step;

  void update(double dt) {
    current += randomDirection() * step * dt;
    current = current.clamp(bounds);
  }
}
```

## Performance Considerations

1. **Update Rate:** Call `update3dAudio()` at 20-30 Hz (not every frame)
2. **Active Sounds:** Limit to 8-10 3D sources maximum
3. **Distance Culling:** Stop sounds beyond max distance automatically
4. **Position Caching:** Only update when movement changes

## Benefits of 3D Approach

✅ **Realistic:** Natural distance and direction perception
✅ **Dynamic:** Thunder can roll, birds can fly
✅ **Immersive:** Full 360° soundscape
✅ **Efficient:** Mono files = smaller app size
✅ **Flexible:** Easy to adjust positioning at runtime
✅ **Professional:** True spatial audio like games/VR

## Migration from Current System

**Current (Simple Pan):**
- Uses `setPan(handle, -1.0 to 1.0)`
- Stereo files recommended
- Static left/right positioning

**New (3D Spatial):**
- Uses `play3d(source, x, y, z)`
- Mono files required
- Dynamic 3D positioning with movement

**Migration Steps:**
1. Update audio handler to use `play3d()` instead of `play()`
2. Add 3D listener setup in `initSoloud()`
3. Replace pan randomization with position randomization
4. Implement movement interpolation for random events
5. Update all audio files from stereo to mono
6. Test with headphones for proper 3D imaging

## Testing

**Critical Tests:**
1. **Direction:** Thunder from left should sound left
2. **Distance:** Far sounds should be quieter
3. **Movement:** Birds flying should pan smoothly
4. **Doppler:** Fast-moving sounds should pitch-shift
5. **Headphones:** Must test with headphones for full 3D effect

**Recommended Headphones:** Any stereo headphones will work, but over-ear provides best spatial imaging.
