#!/bin/bash
set -e

echo "Starting Sober Multi-Instance Container..."

export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MESA_GL_VERSION_OVERRIDE=4.5
export MESA_GLSL_VERSION_OVERRIDE=450

echo "Configuring memory management..."
sysctl -w vm.swappiness=100 2>/dev/null || echo "Note: Cannot set swappiness (requires privileged mode)"

echo "Memory status:"
free -h

echo "Starting system D-Bus..."
mkdir -p /run/dbus
dbus-daemon --system --fork

echo "Starting VNC server on display $DISPLAY..."
Xvnc $DISPLAY -geometry $VNC_RESOLUTION -depth 24 -rfbport $VNC_PORT -SecurityTypes None &
sleep 2

echo "Starting XFCE desktop environment..."
export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address)
startxfce4 &
sleep 3

echo "Starting noVNC web interface on port $NOVNC_PORT..."
/usr/share/novnc/utils/novnc_proxy --vnc localhost:$VNC_PORT --listen $NOVNC_PORT &

echo ""
echo "=========================================="
echo "  Sober Multi-Instance Container Ready!"
echo "=========================================="
echo ""
echo "Access the desktop at:"
echo "  http://localhost:$NOVNC_PORT/vnc.html"
echo ""
echo "VNC Password: sober123"
echo ""
echo "To launch Sober, open Terminal in the desktop and run:"
echo "  flatpak run org.vinegarhq.Sober"
echo ""
echo "=========================================="

tail -f /dev/null
