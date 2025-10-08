# RG40XXV + KNULLI Targeted Export Pipeline

## Hardware Constraints
- **GPU**: Mali G31 MP2 (OpenGL ES 3.2 max, NOT OpenGL 3.3)
- **RAM**: 1GB LPDDR4 (very limited)
- **Display**: 640x480 (low resolution)
- **OS**: KNULLI (limited OpenGL driver support)

## Godot 4 Project Settings (CRITICAL)

### 1. Rendering Settings
```
Project Settings → Rendering:
- Renderer: Compatibility (OpenGL 3.0) ← NOT Forward+
- Anti-aliasing: None
- Use pixel snap: ON
- Canvas item default blend mode: Mix
- 2D pixel snap: ON
- 2D screen pixel snap: ON
```

### 2. Display Settings
```
Project Settings → Display:
- Window size: 640x480 (match device)
- Stretch mode: Viewport
- Stretch aspect: Keep
- Per pixel transparency: OFF
```

### 3. Rendering Quality (Performance)
```
Project Settings → Rendering → Quality:
- Use pixel snap: ON
- 2D pixel snap: ON
- 2D screen pixel snap: ON
- Canvas item default blend mode: Mix
- Anti-aliasing: None
- MSAA: Disabled
- Use pixel snap: ON
```

### 4. Input Settings
```
Project Settings → Input Map:
- ui_accept: Joypad Button 0 (A)
- ui_cancel: Joypad Button 1 (B)
- ui_select: Joypad Button 0 (A)
- ui_back: Joypad Button 1 (B)
- move_left: Joypad D-Pad Left
- move_right: Joypad D-Pad Right
- move_up: Joypad D-Pad Up
- move_down: Joypad D-Pad Down
```

## Export Settings

### 1. Export Template
- **Platform**: Linux/X11
- **Architecture**: ARM64
- **Custom Template**: Use ARM64 template (build your own)

### 2. Export Options
```
Binary Format:
- Embed PCK: OFF (we want separate .pck file)
- Architecture: ARM64

Resources:
- Export mode: Resources only
- Filters: Include all

Features:
- Disable all high-end features
```

## Launch Script (pimpa-raka.sh)
```bash
#!/bin/sh
DIR="$(dirname "$0")"
cd "$DIR"

# Force OpenGL ES 2.0 (Mali G31 max compatibility)
export MESA_GL_VERSION_OVERRIDE=2.0
export MESA_GLSL_VERSION_OVERRIDE=100
export MESA_GL_EXT_OVERRIDE="-GL_ARB_compatibility"

# Audio settings
export SDL_AUDIODRIVER=pulse

# Ensure executable
chmod +x ./pimpa-raka.arm64 2>/dev/null || true

# Try OpenGL ES 2.0 first (most compatible)
exec ./pimpa-raka.arm64 --rendering-driver opengl3_es --display-driver headless
```

## Port.json
```json
{
  "title": "Pimpa Raka (G4)",
  "runner": "simple",
  "args": ["./pimpa-raka.sh"],
  "version": "0.1.0"
}
```

## Build ARM64 Template (Required)

### On Linux (WSL2 Ubuntu 22.04+):
```bash
# Install dependencies
sudo apt update
sudo apt install -y git scons clang lld pkg-config build-essential \
  libx11-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev libudev-dev \
  libxi-dev libxrandr-dev yasm libasound2-dev libpulse-dev

# Get Godot source
git clone https://github.com/godotengine/godot.git
cd godot
git checkout 4.3-stable

# Build ARM64 templates
scons -j$(nproc) platform=linuxbsd target=template_release arch=arm64 use_llvm=yes production=yes
scons -j$(nproc) platform=linuxbsd target=template_debug arch=arm64 use_llvm=yes

# Copy templates to Windows
cp bin/godot.linuxbsd.template_release.arm64 /mnt/c/Users/bruno/dev/Godot/pimpa-raka/export/
cp bin/godot.linuxbsd.template_debug.arm64 /mnt/c/Users/bruno/dev/Godot/pimpa-raka/export/
```

## Project Optimizations

### 1. Texture Settings
- **Max texture size**: 512x512 (not 1024x1024)
- **Compression**: ETC2 (mobile optimized)
- **Filter**: Nearest (pixel art)

### 2. Scene Settings
- **Max nodes per scene**: < 100
- **Max draw calls**: < 50
- **Max vertices**: < 1000

### 3. Script Optimizations
```gdscript
# Disable high-end features
RenderingServer.set_default_clear_color(Color.BLACK)
RenderingServer.set_default_clear_color(Color.BLACK)

# Use low-quality settings
get_viewport().msaa_3d = Viewport.MSAA_DISABLED
get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
```

## Testing Checklist

### 1. Before Export
- [ ] Project uses Compatibility renderer
- [ ] Window size is 640x480
- [ ] All textures are 512x512 or smaller
- [ ] No high-end shaders
- [ ] Input mapped to gamepad
- [ ] Performance profiled

### 2. After Export
- [ ] ARM64 binary created
- [ ] .pck file created
- [ ] Both files in same folder
- [ ] launch.sh has execute permissions
- [ ] Port.json points to correct script

### 3. On Device
- [ ] Game appears in Ports menu
- [ ] Launches without crashing
- [ ] Shows on screen (not headless)
- [ ] Controls work
- [ ] Performance acceptable

## Troubleshooting

### If game crashes:
1. Check `/tmp/pimpa-raka.log`
2. Try `--rendering-driver dummy` (no graphics)
3. Check OpenGL support: `glxinfo | grep OpenGL`

### If black screen:
1. Try `--display-driver headless` first
2. Check if game is running: `ps aux | grep pimpa`
3. Try different renderer: `opengl3_es` vs `opengl3`

### If performance poor:
1. Reduce texture sizes
2. Disable post-processing
3. Lower resolution to 480x320
4. Use fewer nodes per scene

## Alternative: Godot 3.x
If Godot 4 still fails, consider:
1. **Export to Godot 3.5** (more compatible with Mali G31)
2. **Use GLES2 renderer** (better handheld support)
3. **Simpler project structure** (fewer nodes, smaller textures)

This pipeline targets the specific limitations of RG40XXV + KNULLI for maximum compatibility.
