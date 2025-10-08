#!/bin/sh
echo "=== DEBUG START ===" >> /tmp/pimpa-debug.log
echo "PWD: $(pwd)" >> /tmp/pimpa-debug.log
echo "Files in directory:" >> /tmp/pimpa-debug.log
ls -la >> /tmp/pimpa-debug.log
echo "Trying to run binary..." >> /tmp/pimpa-debug.log
./pimpa-raka.arm64 --rendering-driver opengl3_es 2>&1 >> /tmp/pimpa-debug.log
echo "=== DEBUG END ===" >> /tmp/pimpa-debug.log
