#!/bin/bash
set -e
echo "Starting Sober Multi-Instance Container..."
echo "Configuring memory management..."
sysctl -w vm.swappiness=100 2>/dev/null || echo "Note: Cannot set swappiness (requires privileged mode)"
echo "Memory status:"
free -h
echo "Cleaning up stale files..."
rm -f /run/dbus/pid /var/run/dbus/pid /run/dbus/system_bus_socket /var/run/dbus/system_bus_socket
echo "Starting system D-Bus..."
mkdir -p /run/dbus
dbus-daemon --system --fork
echo "Starting session D-Bus..."
export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address)
echo ""
echo "=========================================="
echo "  Sober Multi-Instance Container Ready!"
echo "=========================================="
echo ""
echo "Launching Sober..."
flatpak run org.vinegarhq.Sober &
tail -f /dev/null
