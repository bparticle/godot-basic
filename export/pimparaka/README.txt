Pimpa Raka – PortMaster (RG40XXV, Godot 4)

Place these files in this folder before copying to the device:

1) pimpa-raka.arm64     (Linux ARM64 executable, chmod +x)
2) pimpa-raka.pck       (same folder as the executable)
3) Port.json            (already provided)
4) launch.sh            (already provided, chmod +x)
5) icon.png             (optional, 256x256)

Copy the entire folder to your SD card under:
/roms/ports/pimparaka/

On device, PortMaster will list "Pimpa Raka (G4)" in Ports.

DEBUGGING (SSH into device):
1) cd /roms/ports/pimparaka/
2) ls -la                    # check permissions
3) chmod +x launch.sh pimpa-raka.arm64
4) ./launch.sh               # test launch directly
5) ldd pimpa-raka.arm64      # check missing libraries
6) dmesg | tail              # check kernel errors
7) journalctl -f             # watch system logs while launching

