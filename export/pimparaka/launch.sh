#!/bin/sh
DIR="$(dirname "$0")"
cd "$DIR"

# Log to help debug PortMaster issues
echo "Starting Pimpa Raka from: $DIR" > /tmp/pimpa-raka.log 2>&1

# Environment tuning for handheld OS builds
export SDL_AUDIODRIVER=pulse
export MESA_GL_VERSION_OVERRIDE=3.0
export MESA_GLSL_VERSION_OVERRIDE=300
export MESA_GL_EXT_OVERRIDE="-GL_ARB_compatibility"

# Ensure executable bit just in case
chmod +x ./pimpa-raka.arm64 2>/dev/null || true

# Check if files exist
if [ ! -f "./pimpa-raka.arm64" ]; then
    echo "ERROR: pimpa-raka.arm64 not found" >> /tmp/pimpa-raka.log
    exit 1
fi

if [ ! -f "./pimpa-raka.pck" ]; then
    echo "ERROR: pimpa-raka.pck not found" >> /tmp/pimpa-raka.log
    exit 1
fi

# Try different rendering backends in order of preference
exec ./pimpa-raka.arm64 --rendering-driver opengl3_es --display-driver headless 2>/dev/null || \
     ./pimpa-raka.arm64 --rendering-driver opengl3_es 2>/dev/null || \
     ./pimpa-raka.arm64 --rendering-driver opengl3 --display-driver headless 2>/dev/null || \
     ./pimpa-raka.arm64 --rendering-driver opengl3

