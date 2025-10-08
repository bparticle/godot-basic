## PortMaster deployment checklist for Anbernic RG40XXV (Godot 4 only)

This checklist targets RG40XXV-class devices using PortMaster, staying on Godot 4 with the Compatibility renderer (OpenGL 3). Vulkan is typically not viable on these handhelds.

### 1) Configure the Godot 4 project
- [x] **Renderer**: Project Settings → Rendering → set to Compatibility (OpenGL 3).
- [x] **Window**: Fullscreen on; default size small (e.g., 640x480 or 480x320). Keep a 4:3 or 3:2 friendly layout.
- [ ] **Quality**: Disable high-end features (SSR, SSAO, SDFGI, MSAA, glow-intensive passes). Prefer nearest filtering for pixel art.
- [ ] **Input**: Map actions to gamepad (A/B/X/Y, D-Pad, L/R, Start/Select). Avoid mouse/keyboard assumptions.
- [ ] **Audio**: Keep effects light; prefer 44.1kHz and modest bus effects to reduce latency.

### 2) Export a Linux ARM64 build (binary + PCK)
- [ ] Project → Export → Add “Linux” (Godot 4).
- [ ] Architecture: ARM64/aarch64.
- [ ] Produce `YourGame` (executable) and `YourGame.pck` in the same folder.
- [ ] Ensure the executable bit is set after copying to the device (`chmod +x`).

### 3) Create PortMaster folder locally
Create a folder structure on your PC (to copy later to the SD card):

```
ports/
  YourGame/
    Port.json
    YourGame          # Godot 4 ARM64 executable
    YourGame.pck
    launch.sh         # optional wrapper (sets env/flags)
    icon.png          # optional, 256x256 recommended
    README.txt        # optional, notes/controls
```

### 4) Launching options
Option A: Launch binary directly via simple runner
```json
{
  "title": "Your Game (G4)",
  "runner": "simple",
  "args": ["./YourGame", "--rendering-driver", "opengl3"],
  "version": "1.0.0"
}
```

Option B: Use a wrapper script (recommended for env tuning)
Create `launch.sh`:
```bash
#!/bin/sh
DIR="$(dirname "$0")"
cd "$DIR"
# Suggested environment knobs for some OS builds
export SDL_AUDIODRIVER=pulse
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330
chmod +x ./YourGame
exec ./YourGame --rendering-driver opengl3 "$@"
```
Make `Port.json` call it:
```json
{
  "title": "Your Game (G4)",
  "runner": "simple",
  "args": ["./launch.sh"],
  "version": "1.0.0"
}
```

Notes:
- Keep `YourGame` and `YourGame.pck` together in the same folder.
- Use short titles; they appear in the launcher list.

### 5) Copy to RG40XXV SD card
- [ ] Eject SD from device, mount on PC (or use SMB/USB).
- [ ] Navigate to the PortMaster `ports/` directory used by your OS build.
- [ ] Copy the entire `YourGame/` folder into `ports/`.

Path example on many builds:
```
/roms/ports/YourGame/
```

### 6) First run checklist on device
- [ ] Appears under Ports and launches.
- [ ] No Vulkan errors; renderer is OpenGL 3 Compatibility.
- [ ] Fullscreen OK; no UI cropping or odd scaling.
- [ ] Controls: D-Pad movement, A/B confirm/cancel, Start pause, Select back.
- [ ] Performance acceptable; audio free of pops/stutter.

### 7) Troubleshooting (Godot 4 specifics)
- Game missing from menu:
  - [ ] Folder is under the correct `ports/` path.
  - [ ] `Port.json` is valid JSON and present.
  - [ ] `YourGame` (executable) and `.pck` both exist.
- Fails to start or black screen:
  - [ ] Confirm Compatibility renderer; pass `--rendering-driver opengl3`.
  - [ ] Ensure `chmod +x YourGame` and, if using `launch.sh`, it’s also executable.
  - [ ] Try lower base resolution (480x320), disable heavy post-processing.
  - [ ] Remove large/NPOT textures or reduce texture sizes.
- Input issues:
  - [ ] Verify InputMap uses standard gamepad actions.
  - [ ] Avoid mouse cursor UI; ensure focus navigation works on controller.
- Audio hitches:
  - [ ] Use lighter mixing, fewer effects; try SDL audio env vars.

### 8) Deliverable summary
- [ ] `ports/YourGame/Port.json`
- [ ] `ports/YourGame/YourGame` (Linux ARM64 executable, +x)
- [ ] `ports/YourGame/YourGame.pck`
- [ ] `ports/YourGame/launch.sh` (optional, +x)
- [ ] `ports/YourGame/icon.png` (optional)
- [ ] `ports/YourGame/README.txt` (optional)

### Example controls (suggested)
- **D-Pad**: Move
- **A**: Jump/Confirm
- **B**: Attack/Cancel
- **X/Y**: Secondary actions (dash/interact)
- **Start**: Pause
- **Select**: Back/Map

---
Tips:
- Stick to Compatibility (OpenGL 3) and modest effects.
- Prefer nearest-neighbor scaling for pixel art; keep textures small.
- Profile on device early; handheld CPUs/GPUs are modest.


