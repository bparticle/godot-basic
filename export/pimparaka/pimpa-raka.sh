#!/bin/sh
DIR="$(dirname "$0")"
cd "$DIR"

# Log to help debug PortMaster issues
echo "Starting Pimpa Raka from: $DIR" > /tmp/pimpa-raka.log 2>&1

# Environment tuning for handheld OS builds
export SDL_AUDIODRIVER=pulse
export MESA_GL_VERSION_OVERRIDE=2.1
export MESA_GLSL_VERSION_OVERRIDE=120
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

# Try different approaches in order
echo "Attempting to run: ./pimpa-raka.arm64 --rendering-driver opengl3_es" >> /tmp/pimpa-raka.log
./pimpa-raka.arm64 --rendering-driver opengl3_es 2>&1 >> /tmp/pimpa-raka.log
if [ $? -ne 0 ]; then
    echo "OpenGL 3 ES failed, trying dummy renderer" >> /tmp/pimpa-raka.log
    ./pimpa-raka.arm64 --rendering-driver dummy 2>&1 >> /tmp/pimpa-raka.log
fi
echo "Game exited with code: $?" >> /tmp/pimpa-raka.log

