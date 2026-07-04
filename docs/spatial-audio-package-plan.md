# Spatial Audio Package Plan

A plan for building an open-source Flutter package providing true HRTF binaural
3D audio on Android, iOS, macOS, and Linux — built on miniaudio and Valve's
Steam Audio SDK. Working name: `phonon_audio` ("Steam" is Valve's trademark and
must not appear in the package name).

StillFlow is the motivating application (and first consumer), but the package
is designed to stand alone and be published to pub.dev: no such maintained
package exists today.

## Why HRTF? The benefits over panning

Every current Flutter audio engine — including flutter_soloud's "3D" API —
spatializes with **amplitude panning plus distance attenuation**: a sound to
your left is louder in the left ear, a far sound is quieter. That produces a
left–right axis and a near–far axis, and nothing else. Sounds localize on a
line between the listener's ears and tend to sit "inside the head."

An HRTF (Head-Related Transfer Function) is a measured catalog of how sound
arriving from each direction is filtered by the human head, shoulders, and
outer ear before reaching the eardrums — direction-dependent frequency shaping
and inter-aural time differences. Binaural rendering convolves a mono source
through the HRTF filter pair for its direction in real time. On headphones,
the result recreates what the eardrums would receive if the source were really
there. Concretely, that unlocks:

- **Externalization** — the flagship effect. Sounds detach from the head and
  sit out in the room. Panned audio feels like headphones; binaural audio
  feels like a place.
- **Front/back and elevation** — a full sphere instead of a left-right line.
  Rain genuinely *overhead*, a stream *in front*, an owl *behind the left
  shoulder*.
- **Perceptible motion through space** — a source drifting from front-left to
  behind-right reads as actual travel, which panning can only hint at.
- **Distance realism** — combined with attenuation and air absorption, near
  vs. far becomes visceral rather than merely quieter.

For a sleep app used mostly on earbuds in bed, these map directly onto the
product: rain that reads as a roof overhead, thunder that rolls across the
sky, a composed *place* rather than a stereo mix. The same capability serves
games, meditation apps, audiobooks/drama, and accessibility uses — the
package audience.

Caveats to design for: HRTF only pays off on headphones (on speakers it should
degrade to plain panning — expose a toggle); generic HRTFs fit some ears
better than others (front/back confusion is the common failure — support SOFA
files later for personalized HRTFs); convolution costs more CPU than panning
(a few ambient voices are trivial on any modern phone).

## Why these foundations

**Steam Audio (libphonon)** — Valve's spatial-audio SDK: the highest-quality
open HRTF renderer. Apache-2.0 since 2023, actively maintained (v4.8.1,
Feb 2025), C API, prebuilt binaries for Windows, Linux x64, macOS
(Intel + Apple Silicon), Android (armv7/arm64/x86_64), and iOS. SOFA file
support for custom HRTFs. It is DSP-only: it transforms buffers and owns no
audio device, decoder, or mixer.

**miniaudio** — single-file public-domain C library, already proven inside
flutter_soloud on all target platforms. Its high-level `ma_engine` API *is*
the mixer: device output (ALSA/PulseAudio on Linux, CoreAudio on
macOS/iOS, AAudio/OpenSL on Android), decoding (WAV/FLAC/MP3 natively, OGG
Vorbis via stb_vorbis), voice management, **gapless looping**
(`ma_sound_set_looping`), and a pluggable node graph for custom DSP.

**The two are designed to compose.** The miniaudio repository ships an
official integration example, `examples/engine_steamaudio.c`, implementing a
custom `ma_node` that applies Steam Audio's `IPLBinauralEffect` per source.
The package's audio core is an adaptation of that example, not a from-scratch
engine.

## Architecture

Four layers, from the speaker up:

```
┌───────────────────────────────────────────────────────────┐
│ 4. Dart API        PhononEngine, PhononSound, PhononVoice │
│    (idiomatic wrapper over ffigen-generated bindings)     │
├───────────────────────────────────────────────────────────┤
│ 3. C API (FFI)     ~20 flat functions, stable ABI         │
│    engine_init/shutdown, load/unload, play/stop/pause,    │
│    set_source_position, set_listener, set_volume, ...     │
├───────────────────────────────────────────────────────────┤
│ 2. Engine core     ma_engine (mixer, voices, gapless      │
│    (C, vendored)   loops, decode) + custom phonon node    │
│                    per voice: IPLDirectEffect (distance/  │
│                    air absorption) → IPLBinauralEffect    │
│                    (HRTF) → mix bus                       │
├───────────────────────────────────────────────────────────┤
│ 1. Platform I/O    miniaudio backends: ALSA/PulseAudio,   │
│                    CoreAudio, AAudio/OpenSL               │
└───────────────────────────────────────────────────────────┘
```

Design rules:

- **All per-frame audio processing stays native.** The audio thread runs
  inside miniaudio's callback; Steam Audio processes fixed-size frames there
  (set the engine period size to phonon's frame size, per the official
  example). Dart is the control plane only — positions, volumes, play/stop.
  Control calls are sub-microsecond FFI writes into atomics/lock-free slots
  read by the audio thread; never lock the callback.
- **HRTF is per-voice and optional.** Each voice can route through the
  binaural node (headphones mode) or plain `ma_sound` panning (speakers
  mode), switchable at runtime.
- **Assets load as bytes.** Dart reads via `rootBundle` and passes buffers
  down (`engine_load_mem`), avoiding per-platform asset-path handling.

### Dart API sketch

```dart
final engine = await PhononEngine.init(sampleRate: 44100);
engine.listener.set(position: Vec3.zero, forward: Vec3(0, 0, -1));

final rain = await engine.loadAsset('assets/audio/rain.ogg');
final voice = engine.play(rain, looping: true, spatial: true);
voice.position = Vec3(0, 2.0, -1.0);          // overhead-ish
voice.fadeVolume(0.0, Duration(minutes: 30)); // sleep timer

engine.binauralEnabled = false;               // speakers fallback
```

The initial API surface deliberately mirrors the subset of flutter_soloud
that StillFlow uses (play/pause/stop/loop/volume/seek-position/filter), plus
3D positions — that keeps the StillFlow migration mechanical.

## Repository layout

Scaffolded with `flutter create --template=plugin_ffi`:

```
phonon_audio/
├── src/                      # native engine core (C)
│   ├── phonon_audio.c/.h     # C API + engine + binaural node
│   ├── miniaudio.h           # vendored (public domain)
│   ├── stb_vorbis.c          # vendored (public domain)
│   └── CMakeLists.txt
├── lib/
│   ├── phonon_audio.dart     # idiomatic API
│   └── src/bindings.g.dart   # ffigen output
├── linux/CMakeLists.txt      # links libphonon.so
├── android/build.gradle      # CMake; Valve's per-ABI .so files
├── macos/phonon_audio.podspec
├── ios/phonon_audio.podspec
├── example/                  # runnable demo app (pub.dev requirement)
└── ffigen.yaml
```

### Steam Audio binary vendoring

The phonon binaries are too large for pub.dev. Each platform's build step
downloads the pinned SDK release from Valve's GitHub releases (checksum
verified) into a cache before compiling — the pattern used by other
binary-wrapping Flutter packages. An env override points at a local SDK copy
for offline/CI builds.

| Platform | Build hook | Phonon binary |
|----------|-----------|---------------|
| Linux x64 | CMake | prebuilt `libphonon.so` |
| Linux arm64 | CMake | **built from source** (no prebuilt exists); cacheable, CMake-based |
| Android | Gradle+CMake | prebuilt arm64-v8a / armeabi-v7a / x86_64 |
| macOS | CocoaPods | prebuilt universal dylib, embedded + codesigned |
| iOS | CocoaPods | prebuilt static lib / xcframework |
| Windows | (later) | prebuilt DLL — deferred, not a StillFlow target |

## Roadmap

**Phase 0 — listening spike (go/no-go).** One C file: miniaudio +
`engine_steamaudio.c` node + stb_vorbis, looping StillFlow's rain OGG while
orbiting its position. No Flutter, no FFI. Proves: the HRTF effect is worth
it, gapless looping survives the DSP chain, and phonon builds from source on
arm64 Linux. Everything here is reused later.

**Phase 1 — engine + package (Linux, macOS).** Wrap the spike in the C API;
`plugin_ffi` scaffold; ffigen bindings; idiomatic Dart layer; example app;
unit tests against a null/loopback backend (miniaudio supports a null device —
tests run headless in CI, a lesson learned from flutter_soloud's FFI tests).

**Phase 2 — mobile.** Android Gradle/CMake wiring; iOS podspec + framework
embedding; background-audio smoke tests with audio_service on both.

**Phase 3 — publish.** README with HRTF explainer + demo video, API docs,
CI (build matrix + tests per platform), pub.dev release, versioning policy
pinned to a specific Steam Audio SDK release.

**Phase 4 — StillFlow migration.** Swap `SoLoudAudioHandler` internals to the
new engine behind the same `BaseAudioHandler` interface. The audio_service
media-controls layer, UI, models, and layer-scheduling logic are
engine-agnostic and carry over unchanged. Interim spatial features built on
flutter_soloud's pan-based 3D (wandering rain, spatial random layers, rolling
thunder) translate directly: same positions, real HRTF rendering.

**Later.** SOFA HRTF loading, reverb/occlusion (phonon supports both),
ambisonics beds, Windows, web (Steam Audio has no wasm build — likely a
WebAudio PannerNode fallback).

## Licensing

- Steam Audio SDK: Apache-2.0 (attribution notice required). Compatible with
  the package under MIT/Apache-2.0 and with StillFlow's AGPL-3.0.
- miniaudio, stb_vorbis: public domain / MIT-0.
- Package license: Apache-2.0 (matches the key dependency, friendly to
  commercial adopters).
- Trademark: no "Steam" in the package name; credit "Steam® Audio" in docs.

## Risks and open questions

- **arm64 Linux phonon build** — no prebuilt binary; must build from source.
  Mitigation: Phase 0 proves it on this machine; cache the artifact.
- **iOS/macOS embedding friction** — dylib signing and framework embedding
  are historically the fiddliest part (see flutter_al's abandoned attempt).
  Budget real time in Phase 2.
- **Phonon frame-size vs. device period mismatch** — handled by configuring
  `ma_engine` period size per the official example; verify on each backend.
- **CPU/battery on low-end Android** — measure in Phase 2; per-voice HRTF
  toggle is the escape hatch.
- **Maintenance surface** — pinning phonon + vendored miniaudio versions and
  a per-platform CI matrix is the ongoing cost of owning the package.
