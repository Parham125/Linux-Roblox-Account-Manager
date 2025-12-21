# Linux Roblox Account Manager

A Docker-based tool for running multiple Sober (Roblox on Linux) instances simultaneously with web-based desktop access. Perfect for managing multiple Roblox accounts on Linux.

## Features

✅ **Multiple Sober instances** - Run as many instances as you want (each in its own container)
✅ **Web-based access** - Control via your browser, no VNC client needed
✅ **No singleton detection** - Each container is fully isolated
✅ **Modern GUI & CLI** - Beautiful GUI application or command-line interface
✅ **Image cloning** - Create instances from pre-configured images with Roblox downloaded
✅ **Interactive management** - Easy-to-use menu system for managing instances
✅ **Auto-installation** - Automatically installs Docker if not present

## Prerequisites

Before running this tool, you need to configure your system swap space to prevent OOM (Out Of Memory) kills.

### Setting Up Swap Space

Each container uses up to 3GB of memory (256MB RAM + swap). To run multiple instances, you need adequate swap space. Recommended: **8GB or more**.

**Check current swap:**

```bash
free -h
swapon --show
```

**Increase swap to 8GB (recommended):**

```bash
# Turn off current swap
sudo swapoff /swapfile

# Remove old swapfile (if exists)
sudo rm -f /swapfile

# Create new 8GB swapfile
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress

# Set correct permissions
sudo chmod 600 /swapfile

# Format as swap
sudo mkswap /swapfile

# Enable swap
sudo swapon /swapfile

# Verify
free -h
```

**Make swap permanent (add to /etc/fstab if not already there):**

```bash
# Check if already configured
grep swapfile /etc/fstab

# If not found, add it
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Parham125/Linux-Roblox-Account-Manager
cd Linux-Roblox-Account-Manager
```

### 2. Choose Your Interface

#### Option A: GUI Application (Recommended)

**Install dependencies:**

```bash
pip install -r requirements.txt
```

**Run the GUI:**

```bash
./gui.py
# or
python3.13 gui.py
```

**Build standalone executable (optional):**

```bash
./build.sh
# Executable will be in dist/SoberManager
```

The GUI provides:

- 🎨 Modern dark/light theme interface
- 📊 Visual instance status indicators
- 🔄 One-click refresh, start, stop, and remove
- 🌐 Direct browser access buttons
- 💾 Easy image creation and cloning
- ⚡ Real-time instance management

#### Option B: Command-Line Interface

```bash
chmod +x run-instance.sh
./run-instance.sh
```

The script will:

- Automatically check and install Docker if needed
- Build the Docker image
- Show you an interactive menu

### 3. Interactive Menu (CLI)

```
╔══════════════════════════════════════╗
║  Sober Multi-Instance Manager        ║
╚══════════════════════════════════════╝

1) List instances
2) Run/Start instance
3) Stop instance
4) Remove instance
5) Create image from instance (save with Roblox)
6) Run/Start instance from custom image
0) Exit
```

**To create a new instance:**

1. Select option `2`
2. Enter an instance number (e.g., `1`, `2`, `3`)
3. The instance will start automatically

**Access URLs:**

- Instance 1: `http://localhost:6080/vnc.html`
- Instance 2: `http://localhost:6081/vnc.html`
- Instance 3: `http://localhost:6082/vnc.html`
- Instance N: `http://localhost:60(79+N)/vnc.html`

**To avoid re-downloading Roblox (Image Cloning):**

1. Create a base instance (option `2`) and download Roblox in it
2. Save it as an image (option `5` in CLI or "Save as Image" in GUI)
3. Create new instances from this image (option `6` in CLI or "Create from Image" in GUI)
4. All new instances will have Roblox pre-installed!

This saves time and bandwidth when creating multiple instances.

## What is XFCE?

**XFCE** is a lightweight desktop environment for Linux. Think of it as the Windows desktop you see when you log into Windows, but for Linux. It provides:

- A taskbar and system tray
- File manager
- Application menu
- Window management
- Terminal emulator

We use XFCE because it's fast, stable, and works well in containers.

## Using the Desktop

1. **Open your web browser**
2. **Navigate to** the instance URL (see above)
3. **Enter VNC password:** `sober123`
4. **You'll see the XFCE desktop**

## Launch Sober

**Sober launches automatically!** Once you connect to the desktop, Sober will start within 10-15 seconds. No need to open a terminal!

If you need to restart Sober manually:

1. Click **Applications** menu (top-left)
2. Open **Terminal Emulator**
3. Run: `flatpak run org.vinegarhq.Sober`

## How Multi-Instance Works

### The Problem

Sober has built-in singleton detection that prevents multiple instances from running. It checks:

- systemd scope units
- Network-based IPC
- Process listings

### The Solution

Each Docker container provides:

- **Isolated systemd** - Each container has its own systemd instance
- **Isolated network** - Containers don't share network namespace (no `--network host`)
- **Isolated processes** - Containers can't see each other's processes
- **Isolated D-Bus** - Each has its own D-Bus session

This makes Sober think it's the only instance running!

## Requirements

- **Docker** installed (auto-installed by script if missing)
- **Graphics drivers** accessible (`/dev/dri`)
- **Audio device** accessible (`/dev/snd`)
- **Disk space** - Each instance uses ~5GB (image) + logs
- **Swap space** - At least 8GB recommended for multiple instances

## Resource Limits (Per Instance)

Each container is limited to:

- **CPU:** 1 core maximum
- **RAM:** 256MB physical memory
- **Memory+Swap:** 3GB total (includes RAM + swap)
- **Shared Memory:** 256MB for graphics

This allows you to run many instances on modest hardware!

## Port Mapping

The script automatically handles port mapping:

- Instance 1: Port 6080
- Instance 2: Port 6081
- Instance 3: Port 6082
- Instance N: Port 6079+N

## Logs and Data Persistence

Each instance automatically mounts its logs directory to your host machine:

**Container path:** `/root/.var/app/org.vinegarhq.Sober/data/sober/sober_logs`

**Host path:** `./sober-logs-<instance-number>/`

Examples:

- Instance 1: Container logs → `./sober-logs-1/`
- Instance 2: Container logs → `./sober-logs-2/`
- Instance 3: Container logs → `./sober-logs-3/`

All Sober logs and data from each instance are automatically saved to these folders.

## Managing Instances

### Using the Interactive Menu

**List all instances:**

- Select option `1` from the menu
- Shows running and stopped instances with their URLs

**Start/Run an instance:**

- Select option `2`
- Enter instance number
- If exists: asks to start the stopped instance
- If new: creates and starts a new instance

**Stop instances:**

- Select option `3`
- Enter instance number or `all` to stop all instances

**Remove instances:**

- Select option `4`
- Enter instance number or `all` to remove all instances
- Confirms before removing

### Manual Docker Commands

```bash
# List all instances
docker ps -a --filter "name=sober-instance-"

# Stop specific instance
docker stop sober-instance-1

# Remove specific instance
docker rm sober-instance-1

# View instance logs
docker logs sober-instance-1
```

## Troubleshooting

### OOM Kills / Containers Keep Dying

**Problem:** Containers are getting killed by the system

**Solution:** Increase swap space (see "Setting Up Swap Space" section above)

```bash
# Check if swap is sufficient
free -h
# You should have at least 8GB swap for multiple instances
```

### Can't Connect to Web Interface

- Check container is running: `docker ps`
- Check logs: `docker logs sober-instance-1`
- Verify port is not in use: `sudo netstat -tlnp | grep 6080`

### Black Screen in Browser

- Wait 10-15 seconds for desktop to start
- Refresh the page
- Check container logs for errors

### Sober Won't Launch

- Sober should launch automatically within 10-15 seconds
- If not, open Terminal from desktop and run `flatpak run org.vinegarhq.Sober`
- Check D-Bus is running: `ps aux | grep dbus`

### Multiple Instances Detect Each Other

- **DO NOT use `--network host`** - This breaks isolation
- Make sure each container has a unique name
- Each container must use a different port

### Docker Installation Issues

The script auto-installs Docker but requires you to log out and back in after installation for group permissions to take effect.

## Technical Details

**Base Image:** Ubuntu 24.04
**Desktop Environment:** XFCE4
**VNC Server:** TigerVNC
**Web Interface:** noVNC
**Sober Version:** Latest from Flathub
**Default Resolution:** 1920x1080
**VNC Password:** sober123

## Customization

### Change Resolution

Edit the Dockerfile or add environment variable:

```bash
docker run -d \
  -e VNC_RESOLUTION=2560x1440 \
  ...
```

### Change VNC Password

Edit `Dockerfile` and rebuild:

```dockerfile
echo "your-password-here" | vncpasswd -f > /root/.vnc/passwd
```

Then rebuild:

```bash
docker build -t sober-multi -f Dockerfile .
```

## Security Notes

⚠️ **This container runs in privileged mode** - Only use on trusted systems
⚠️ **VNC has no encryption** - Only use on localhost or trusted networks
⚠️ **Password is weak by default** - Change it for production use
⚠️ **Containers need host resources** - `/dev/dri`, `/dev/snd`, cgroups access

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Attribution

When distributing or modifying this software, you must include proper attribution as specified in the [NOTICE](NOTICE) file.

## Credits

**Developer**: Parham
**Project**: Linux Roblox Account Manager

Special thanks to:

- VinegarHQ for Sober (Closed Source) - https://sober.vinegarhq.org/
- Roblox Corporation
- Docker and open source community

## Disclaimer

This tool is for educational purposes. Use at your own risk. The developers are not responsible for any bans or issues that may arise from using multi-instance tools in Roblox games. Always review the game's Terms of Service before using automation or multi-instance tools.

## Contributing

Contributions are welcome! Please ensure you:

1. Follow the GPL v3 license terms
2. Maintain attribution as specified in the NOTICE file
3. Test your changes with multiple instances
4. Update documentation as needed

## Support

For issues, bugs, or feature requests, please open an issue on the GitHub repository.
