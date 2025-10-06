# Audio Files Needed - 3D Spatial Audio

This document lists all audio files needed to complete the layered environmental sound system with **3D spatial audio positioning**.

## Audio File Specifications - UPDATED FOR 3D AUDIO

- **Format:** OGG Vorbis (.ogg)
- **Sample Rate:** 44.1kHz
- **Channels:** **MONO (1 channel)** ← Critical for 3D positioning!
- **Bit Depth:** 16-bit minimum
- **Quality:** Variable bitrate, quality 6-8
- **File Size:** 2-4MB per file (much smaller than stereo)
- **Loop Requirements:** Seamless/gapless for continuous layers
- **Variants:** Multiple takes for random events to reduce repetition
- **Reverb:** NO reverb - 3D audio engine adds spatial characteristics

## Why Mono Instead of Stereo?

**3D Spatial Audio Benefits:**
- ✅ SoLoud positions mono sounds in 3D space (x, y, z coordinates)
- ✅ **50% smaller file sizes** (mono vs stereo)
- ✅ Dynamic movement (thunder rolling, birds flying)
- ✅ Automatic distance attenuation (far sounds quieter)
- ✅ Doppler effects for moving sounds
- ✅ More flexible and immersive than simple pan

**The 3D Engine Handles:**
- Positioning sounds left/right/center/behind
- Distance-based volume
- Movement across the soundscape
- Realistic spatial audio with headphones

## Current Status

### ✅ Already Have (2 files - will need mono conversion)
- `rain-sounds-ambience-351115.ogg` - Rain base loop (5.4MB, stereo → convert to mono)
- `flowing-water-loop-1-183953.ogg` - Flowing water base loop (8.2MB, stereo → convert to mono)

**Action:** Convert existing stereo files to mono or re-source as mono

---

## 🌧️ Rain Environment

### Base Sound (1 file needed - conversion)
- `rain/base/rain-ambience-mono.ogg`
  - Convert existing stereo file to mono
  - **3D Position:** (0, 0, 0) - centered at listener
  - Seamless loop

### Continuous Loop Layers (2 files needed)

**Priority: High**
- `rain/layers/crickets-loop-mono.ogg`
  - Single cricket or small chorus (MONO)
  - Clean, loopable cricket ambience
  - Seamless loop
  - **3D Position:** Random positions around listener (radius 5-10 units)
  - Will be duplicated at different positions for chorus effect

**Priority: Medium**
- `rain/layers/wind-gusts-mono.ogg`
  - Wind sound (MONO)
  - Natural wind with gusts
  - Seamless loop
  - **3D Position:** Slowly moving across space (-10 to 10 on X-axis)
  - Dynamic movement for realism

### Random Event Layers (3 files needed)

**Priority: High**
- `rain/layers/thunder-1-mono.ogg`
  - Thunder clap/rumble (MONO)
  - Clear, dramatic
  - One-shot (3-6 seconds)
  - **3D Movement:** Linear path (-50,20,-30) → (50,20,-30) over 3-5s
  - Rolls across the sky

- `rain/layers/thunder-2-mono.ogg`
  - Thunder variation (MONO)
  - Different from variant 1
  - One-shot (3-6 seconds)
  - **3D Movement:** Same as thunder-1 but different sound

- `rain/layers/thunder-3-mono.ogg`
  - Thunder variation (MONO)
  - Third distinct variant
  - One-shot (3-6 seconds)
  - **3D Movement:** Same movement pattern

**Rain Environment Total: 6 files needed (1 converted + 5 new mono)**

---

## 💧 Flowing Water Environment

### Base Sound (1 file needed - conversion)
- `water/base/flowing-water-mono.ogg`
  - Convert existing stereo file to mono
  - **3D Position:** (0, -1, -3) - in front, slightly below listener
  - Seamless loop

### Continuous Loop Layers (1 file needed)

**Priority: High**
- `water/layers/frogs-mono.ogg`
  - Single frog croak or small group (MONO)
  - Natural frog ambience
  - Seamless loop
  - **3D Position:** Multiple positions in semicircle (radius 8, ground level)
  - Positioned near the water in front

### Random Event Layers (4 files needed)

**Priority: High**
- `water/layers/bird-chirp-1-mono.ogg`
  - Bird chirp (MONO)
  - Bright, clear chirp
  - One-shot (0.5-2 seconds)
  - **3D Movement:** Linear flight (20,8,-15) → (-20,8,-15) over 2-4s
  - Bird flying across soundscape

- `water/layers/bird-chirp-2-mono.ogg`
  - Different bird chirp (MONO)
  - Distinct from variant 1
  - One-shot (0.5-2 seconds)
  - **3D Movement:** Same flight pattern, different sound

- `water/layers/bird-chirp-3-mono.ogg`
  - Third bird variant (MONO)
  - Different species/pitch
  - One-shot (0.5-2 seconds)
  - **3D Movement:** Circular or different linear path

**Priority: Medium**
- `water/layers/splash-mono.ogg`
  - Water splash (MONO)
  - Clean splash sound
  - One-shot (1-2 seconds)
  - **3D Position:** Random positions in water area (±5, -1, -5 to -10)

**Flowing Water Environment Total: 6 files needed (1 converted + 5 new mono)**

---

## 🌊 Ocean Surf Environment (Future - Phase 5)

### Base Sound (1 file needed)

**Priority: Low (Phase 5)**
- `ocean/base/ocean-waves-mono.ogg`
  - Ocean waves/surf (MONO)
  - Natural ebb and flow
  - Seamless loop
  - **3D Position:** (0, -2, -5) - in front, below listener

### Continuous Loop Layers (1 file needed)

**Priority: Low (Phase 5)**
- `ocean/layers/wind-ocean-mono.ogg`
  - Beach/ocean wind (MONO)
  - Gentle to moderate wind
  - Seamless loop
  - **3D Movement:** Slowly moving across (-15 to 15 on X-axis)

### Random Event Layers (4 files needed)

**Priority: Low (Phase 5)**
- `ocean/layers/seagull-1-mono.ogg`
  - Seagull call (MONO)
  - Clear, natural call
  - One-shot (1-3 seconds)
  - **3D Movement:** Circular path overhead (radius 15, center (0,12,0))
  - Seagull circling above

- `ocean/layers/seagull-2-mono.ogg`
  - Seagull variant (MONO)
  - Different call
  - One-shot (1-3 seconds)
  - **3D Movement:** Same circular path

- `ocean/layers/seagull-3-mono.ogg`
  - Third seagull variant (MONO)
  - Distinct from others
  - One-shot (1-3 seconds)
  - **3D Movement:** Larger/smaller circular path for variety

- `ocean/layers/bell-buoy-mono.ogg`
  - Bell buoy (MONO)
  - Distant bell sound
  - One-shot (2-4 seconds)
  - **3D Position:** Fixed at (20, 0, -30) - far to the right

**Ocean Surf Environment Total: 6 files needed**

---

## Summary

### Immediate Priority (Phase 4)
- **Rain Environment:** 6 files (1 conversion + 5 new)
- **Flowing Water Environment:** 6 files (1 conversion + 5 new)
- **Total for Phase 4:** 12 files

### Future (Phase 5)
- **Ocean Surf Environment:** 6 files
- **Total for Phase 5:** 6 files

### Grand Total
- **All Environments:** 18 mono files needed
- **Currently Have:** 2 stereo files (need conversion to mono)
- **New Files to Source:** 16 mono files

**File Size Savings:** ~50% smaller than stereo approach (40-60MB vs 80-120MB)

---

## File Naming Convention

All files must be MONO and follow this pattern:
```
assets/audio/{environment}/{category}/{description}-mono.ogg

Where:
  {environment} = rain | water | ocean
  {category}    = base | layers
  {description} = descriptive-name-with-dashes
  -mono suffix  = REQUIRED to indicate mono channel
```

Examples:
- ✅ `assets/audio/rain/base/rain-ambience-mono.ogg`
- ✅ `assets/audio/rain/layers/thunder-1-mono.ogg`
- ✅ `assets/audio/water/layers/bird-chirp-2-mono.ogg`
- ❌ `assets/audio/rain/layers/thunder-stereo.ogg` (must be mono!)

---

## 3D Spatial Audio Positioning

### Coordinate System
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

### Position Examples by Environment

**Rain:**
- Base loop: (0, 0, 0) - centered
- Crickets: Random in circle (radius 10, Y=0) - ground level around listener
- Thunder: Moves from (-50, 20, -30) to (50, 20, -30) - high in sky, rolling L→R
- Distance: Thunder 40-100 units, Crickets 5-15 units

**Water:**
- Base loop: (0, -1, -3) - in front, slightly below
- Frogs: Semicircle positions (radius 8, Y=0) - around water in front
- Birds: Linear flight (20, 8, -15) to (-20, 8, -15) - medium height, flying across
- Distance: Birds 10-30 units, Frogs 3-12 units

**Ocean:**
- Base loop: (0, -2, -5) - waves in front
- Seagulls: Circular (radius 15, center (0, 12, 0)) - overhead
- Bell buoy: Fixed at (20, 0, -30) - distant, to the right
- Distance: Seagulls 8-25 units, Bell buoy 30-50 units

---

## Audio Sources for Mono Files

Recommended sources for royalty-free mono nature sounds:

### Free Sources
- **Freesound.org** - Creative Commons, filter by "mono" channel
- **BBC Sound Effects** - Open license, many mono recordings
- **Zapsplat** - Free with attribution, has mono options
- **99sounds.org** - Free sound effects
- **Sonniss Game Audio GDC Bundles** - Free annual releases

### Professional Sources
- **Soundly** - Professional library with mono/stereo options
- **Adobe Audition Sound Effects** - Included with subscription
- **Pro Sound Effects** - Commercial library

### Recording Your Own

**Equipment:**
- Any decent microphone (mono recording)
- Portable recorder (Zoom H1n, Tascam, etc.)
- Even smartphones work for some sounds

**Technique:**
- Record at 48kHz or higher (downsample to 44.1kHz)
- Get at least 2 minutes for loops
- Multiple takes for variations
- Record in quiet natural environments
- No reverb/echo - record dry
- Close-mic for thunder, distant for ambience

---

## Converting Stereo to Mono

### Using ffmpeg:

```bash
# Convert stereo to mono (mix both channels)
ffmpeg -i input-stereo.wav -ac 1 output-mono.ogg

# Convert with quality control
ffmpeg -i input-stereo.wav -ac 1 -c:a libvorbis -q:a 6 output-mono.ogg

# Convert existing stereo OGG to mono
ffmpeg -i rain-sounds-ambience-351115.ogg -ac 1 -c:a libvorbis -q:a 6 rain-ambience-mono.ogg

# Batch convert all stereo files in directory
for file in *.ogg; do
  ffmpeg -i "$file" -ac 1 -c:a libvorbis -q:a 6 "${file%.ogg}-mono.ogg"
done
```

### Using Audacity:
1. Open stereo file
2. Tracks → Mix → Mix Stereo Down to Mono
3. File → Export → Export as OGG Vorbis
4. Set quality to 6
5. Save with `-mono.ogg` suffix

---

## Integration Checklist

When you have audio files ready:

1. ✅ Files are in OGG Vorbis format
2. ✅ **Files are MONO (1 channel) - Critical!**
3. ✅ Files are at 44.1kHz sample rate
4. ✅ Continuous loops are seamless
5. ✅ File names include `-mono` suffix
6. ✅ Files are placed in correct directory structure
7. ✅ Update `pubspec.yaml` asset manifest
8. ✅ Update `lib/models/sound.dart` with:
   - Correct asset paths (mono files)
   - 3D position data
   - Movement patterns
   - Distance ranges
9. ✅ Test 3D positioning with headphones
10. ✅ Test movement interpolation
11. ✅ Verify distance attenuation works
12. ✅ Test Doppler effects on fast-moving sounds

---

## 3D Audio Configuration Per Layer

### Thunder (Rain Environment)
```dart
SoundLayer(
  id: 'rain_thunder_near',
  name: 'Thunder (Near)',
  assetPath: 'assets/audio/rain/layers/thunder-1-mono.ogg',
  layerType: LayerType.random,
  minVolume: 0.7,
  maxVolume: 1.0,
  minIntervalSeconds: 30,
  maxIntervalSeconds: 180,
  // 3D positioning
  movementType: MovementType.linear,
  startPosition: Vector3(-50, 20, -30),  // High, far left
  endPosition: Vector3(50, 20, -30),     // High, far right
  movementDuration: 4.0,                 // 4 seconds to roll across
  minDistance: 40.0,                     // Heard from 40 units
  maxDistance: 100.0,                    // Fades by 100 units
  dopplerFactor: 0.5,                    // Subtle Doppler
)
```

### Birds (Water Environment)
```dart
SoundLayer(
  id: 'water_birds_near',
  name: 'Birds (Near)',
  assetPath: 'assets/audio/water/layers/bird-chirp-1-mono.ogg',
  layerType: LayerType.random,
  minVolume: 0.6,
  maxVolume: 0.9,
  minIntervalSeconds: 15,
  maxIntervalSeconds: 60,
  // 3D positioning
  movementType: MovementType.linear,
  startPosition: Vector3(20, 8, -15),    // Right, medium height
  endPosition: Vector3(-20, 8, -15),     // Left, medium height
  movementDuration: 3.0,                 // 3 seconds flying across
  minDistance: 10.0,
  maxDistance: 30.0,
  dopplerFactor: 1.0,                    // More pronounced Doppler
)
```

### Seagulls (Ocean Environment - Future)
```dart
SoundLayer(
  id: 'ocean_seagull',
  name: 'Seagull',
  assetPath: 'assets/audio/ocean/layers/seagull-1-mono.ogg',
  layerType: LayerType.random,
  minVolume: 0.5,
  maxVolume: 0.8,
  minIntervalSeconds: 20,
  maxIntervalSeconds: 90,
  // 3D positioning
  movementType: MovementType.circular,
  circularCenter: Vector3(0, 12, 0),     // Overhead
  circularRadius: 15.0,
  circularSpeed: 0.5,                    // Radians per second
  minDistance: 8.0,
  maxDistance: 25.0,
  dopplerFactor: 0.8,
)
```

---

## Notes

- **Critical:** All audio files MUST be MONO for 3D spatial audio to work
- **Placeholder Status:** Currently using stereo files with simple pan (Phase 1-3)
- **Next Step:** Phase 3.5 will upgrade to 3D audio with `play3d()`
- **Testing:** Requires headphones to properly hear 3D positioning
- **Performance:** Mono files = 50% smaller app size vs stereo
- **Movement:** Thunder rolls, birds fly, seagulls circle - all dynamic!
- **Attenuation:** Far sounds automatically quieter, close sounds louder
- **Doppler:** Fast-moving sounds have realistic pitch shifts
