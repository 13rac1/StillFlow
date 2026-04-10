#!/usr/bin/env python3
"""Audio conversion and splitting tool for StillFlow assets.

Converts source audio files to OGG Vorbis format with options for:
- Mono/stereo channel selection
- Sample rate conversion
- Time trimming with fade in/out
- Normalization

Requires: ffmpeg, oggenc (from vorbis-tools)

Usage:
    python3 scripts/audio_convert.py config.json
    python3 scripts/audio_convert.py --input file.wav --output file.ogg --mono --trim 0:16 --fade-out 2
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile


def convert(
    input_path: str,
    output_path: str,
    *,
    mono: bool = True,
    sample_rate: int = 44100,
    start: float | None = None,
    duration: float | None = None,
    fade_in: float | None = None,
    fade_out: float | None = None,
    normalize: bool = False,
    volume_boost: float | None = None,
    quality: int = 6,
):
    """Convert an audio file to OGG Vorbis via ffmpeg (WAV) + oggenc."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Build ffmpeg filter chain
    filters = []
    if volume_boost and volume_boost != 0:
        filters.append(f"volume={volume_boost}dB")
    if fade_in and fade_in > 0:
        filters.append(f"afade=t=in:d={fade_in}")
    if fade_out and fade_out > 0 and duration:
        fade_start = duration - fade_out
        filters.append(f"afade=t=out:st={fade_start}:d={fade_out}")
    if normalize:
        # Peak normalization — simple and works on short clips
        filters.append("volume=0dB:precision=double,aformat=dblp,dynaudnorm=f=150:g=15")

    # ffmpeg to intermediate WAV
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        cmd = ["ffmpeg", "-y"]
        if start is not None:
            cmd += ["-ss", str(start)]
        cmd += ["-i", input_path]
        if duration is not None:
            cmd += ["-t", str(duration)]
        cmd += ["-ac", "1" if mono else "2"]
        cmd += ["-ar", str(sample_rate)]
        if filters:
            cmd += ["-af", ",".join(filters)]
        cmd += ["-c:a", "pcm_s16le", tmp_path]

        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"  ffmpeg error: {result.stderr.splitlines()[-1]}", file=sys.stderr)
            return False

        # oggenc to final OGG
        cmd2 = ["oggenc", "-q", str(quality), "-o", output_path, tmp_path]
        result2 = subprocess.run(cmd2, capture_output=True, text=True)
        if result2.returncode != 0:
            print(f"  oggenc error: {result2.stderr}", file=sys.stderr)
            return False

        size_kb = os.path.getsize(output_path) / 1024
        print(f"  {os.path.basename(output_path)} ({size_kb:.0f} KB)")
        return True
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


def run_config(config_path: str):
    """Run conversions from a JSON config file.

    Config format:
    {
      "source_dir": "assets/original",
      "output_dir": "assets/audio",
      "defaults": {"mono": true, "sample_rate": 44100, "quality": 6},
      "files": [
        {
          "input": "source-file.wav",
          "outputs": [
            {
              "path": "rain/layers/thunder-strike.ogg",
              "start": 0, "duration": 16,
              "fade_out": 2
            }
          ]
        }
      ]
    }
    """
    with open(config_path) as f:
        config = json.load(f)

    base_dir = os.path.dirname(os.path.abspath(config_path))
    project_dir = os.path.dirname(base_dir)
    source_dir = os.path.join(project_dir, config.get("source_dir", "assets/original"))
    output_dir = os.path.join(project_dir, config.get("output_dir", "assets/audio"))
    defaults = config.get("defaults", {})

    total = 0
    success = 0

    for file_entry in config["files"]:
        input_path = os.path.join(source_dir, file_entry["input"])
        if not os.path.exists(input_path):
            print(f"MISSING: {file_entry['input']}", file=sys.stderr)
            continue

        print(f"\n{file_entry['input']}:")

        for out in file_entry["outputs"]:
            total += 1
            output_path = os.path.join(output_dir, out["path"])

            params = {**defaults}
            for key in ("mono", "sample_rate", "start", "duration",
                        "fade_in", "fade_out", "normalize", "volume_boost", "quality"):
                if key in out:
                    params[key] = out[key]

            ok = convert(input_path, output_path, **params)
            if ok:
                success += 1

    print(f"\nDone: {success}/{total} files converted")


def main():
    parser = argparse.ArgumentParser(description="Convert audio files for StillFlow")
    parser.add_argument("config", nargs="?", help="JSON config file")
    parser.add_argument("--input", "-i", help="Input file")
    parser.add_argument("--output", "-o", help="Output file")
    parser.add_argument("--mono", action="store_true", default=True)
    parser.add_argument("--stereo", action="store_true")
    parser.add_argument("--sample-rate", type=int, default=44100)
    parser.add_argument("--start", type=float)
    parser.add_argument("--duration", type=float)
    parser.add_argument("--fade-in", type=float)
    parser.add_argument("--fade-out", type=float)
    parser.add_argument("--normalize", action="store_true")
    parser.add_argument("--volume-boost", type=float, help="Volume boost in dB")
    parser.add_argument("--quality", type=int, default=6)

    args = parser.parse_args()

    if args.config:
        run_config(args.config)
        return

    if not args.input or not args.output:
        parser.print_help()
        sys.exit(1)

    ok = convert(
        args.input,
        args.output,
        mono=not args.stereo,
        sample_rate=args.sample_rate,
        start=args.start,
        duration=args.duration,
        fade_in=args.fade_in,
        fade_out=args.fade_out,
        normalize=args.normalize,
        volume_boost=args.volume_boost,
        quality=args.quality,
    )
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
