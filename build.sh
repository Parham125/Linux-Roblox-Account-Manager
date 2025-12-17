#!/usr/bin/bash
echo "Building Linux Roblox Account Manager..."
if ! command -v pyinstaller &>/dev/null; then
echo "PyInstaller not found. Installing..."
pip install pyinstaller
fi
pyinstaller --name="RobloxManager" \
--onefile \
--windowed \
--hidden-import="PIL._tkinter_finder" \
--collect-all customtkinter \
gui.py
echo "Build complete! Executable is in dist/RobloxManager"

