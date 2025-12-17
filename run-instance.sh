#!/bin/bash
install_docker(){
echo "Docker not found. Installing Docker..."
if command -v apt-get &>/dev/null; then
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list>/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
echo "✅ Docker installed successfully!"
echo "⚠️  Please log out and log back in for group changes to take effect."
read -p "Press Enter to continue..."
elif command -v dnf &>/dev/null; then
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
echo "✅ Docker installed successfully!"
echo "⚠️  Please log out and log back in for group changes to take effect."
read -p "Press Enter to continue..."
else
echo "❌ Unsupported package manager. Please install Docker manually."
exit 1
fi
}
check_and_install_docker(){
if ! command -v docker &>/dev/null; then
install_docker
fi
}
build_image(){
echo "Building Docker image..."
if [ ! -f "Dockerfile" ]; then
echo "❌ Dockerfile not found in current directory!"
exit 1
fi
docker build -t sober-multi -f Dockerfile .
if [ $? -eq 0 ]; then
echo "✅ Docker image built successfully!"
else
echo "❌ Failed to build Docker image!"
exit 1
fi
echo ""
}
check_and_install_docker
build_image
list_instances(){
echo ""
echo "=== Sober Instances ==="
echo ""
docker ps -a --filter "name=sober-instance-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | while IFS= read -r line; do
if [[ "$line" == *"NAMES"* ]]; then
echo "$line"
else
instance_name=$(echo "$line" | awk '{print $1}')
instance_num=$(echo "$instance_name" | grep -o '[0-9]*$')
port=$((6079+instance_num))
echo "$line" | sed "s|6080/tcp|http://localhost:$port/vnc.html|"
fi
done
echo ""
}
create_image_from_instance(){
read -p "Enter instance number to create image from: " INSTANCE_NUM
if [ -z "$INSTANCE_NUM" ]; then
echo "❌ Instance number required!"
return
fi
CONTAINER_NAME="sober-instance-$INSTANCE_NUM"
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
echo "❌ Instance $INSTANCE_NUM does not exist!"
return
fi
IMAGE_NAME="sober-multi-roblox"
echo "Creating image from instance $INSTANCE_NUM..."
echo "This will save the current state including downloaded Roblox files."
echo ""
docker commit "$CONTAINER_NAME" "$IMAGE_NAME"
if [ $? -eq 0 ]; then
echo ""
echo "✅ Image created successfully as '$IMAGE_NAME'!"
echo "You can now create instances from this image using option 6."
else
echo ""
echo "❌ Failed to create image from instance $INSTANCE_NUM"
fi
echo ""
}
run_instance(){
read -p "Enter instance number to run: " INSTANCE_NUM
if [ -z "$INSTANCE_NUM" ]; then
echo "❌ Instance number required!"
return
fi
CONTAINER_NAME="sober-instance-$INSTANCE_NUM"
PORT=$((6079+INSTANCE_NUM))
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
echo "❌ Instance $INSTANCE_NUM already exists!"
read -p "Start existing instance? (y/n): " choice
if [[ "$choice" == "y" ]]; then
docker start "$CONTAINER_NAME"
echo "✅ Instance $INSTANCE_NUM started!"
echo "Access at: http://localhost:$PORT/vnc.html"
fi
return
fi
echo "Starting Sober instance $INSTANCE_NUM..."
echo "Container name: $CONTAINER_NAME"
echo "Web interface will be at: http://localhost:$PORT/vnc.html"
echo ""
mkdir -p "./sober-logs-$INSTANCE_NUM"
chmod 777 "./sober-logs-$INSTANCE_NUM"
docker run -d \
--name $CONTAINER_NAME \
--privileged \
--cgroupns=host \
-v /sys/fs/cgroup:/sys/fs/cgroup:rw \
-v ./sober-logs-$INSTANCE_NUM:/root/.var/app/org.vinegarhq.Sober/data/sober/sober_logs \
-p $PORT:6080 \
--device /dev/dri \
--device /dev/snd \
--cpus="1.0" \
--memory="256m" \
--memory-swap="3g" \
--shm-size="256m" \
-e LIBGL_ALWAYS_SOFTWARE=1 \
-e GALLIUM_DRIVER=llvmpipe \
-e MESA_GL_VERSION_OVERRIDE=4.5 \
-e __GLX_VENDOR_LIBRARY_NAME=mesa \
-e EGL_PLATFORM=surfaceless \
sober-multi
if [ $? -eq 0 ]; then
echo ""
echo "✅ Instance $INSTANCE_NUM started successfully!"
echo "Access at: http://localhost:$PORT/vnc.html"
else
echo ""
echo "❌ Failed to start instance $INSTANCE_NUM"
fi
echo ""
}
run_instance_from_image(){
if ! docker images --format '{{.Repository}}' | grep -q "^sober-multi-roblox$"; then
echo "❌ Custom image 'sober-multi-roblox' not found!"
echo "Please create an image first using option 5."
return
fi
read -p "Enter instance number to run: " INSTANCE_NUM
if [ -z "$INSTANCE_NUM" ]; then
echo "❌ Instance number required!"
return
fi
CONTAINER_NAME="sober-instance-$INSTANCE_NUM"
PORT=$((6079+INSTANCE_NUM))
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
echo "❌ Instance $INSTANCE_NUM already exists!"
read -p "Start existing instance? (y/n): " choice
if [[ "$choice" == "y" ]]; then
docker start "$CONTAINER_NAME"
echo "✅ Instance $INSTANCE_NUM started!"
echo "Access at: http://localhost:$PORT/vnc.html"
fi
return
fi
echo "Starting Sober instance $INSTANCE_NUM from custom image..."
echo "Container name: $CONTAINER_NAME"
echo "Web interface will be at: http://localhost:$PORT/vnc.html"
echo ""
mkdir -p "./sober-logs-$INSTANCE_NUM"
chmod 777 "./sober-logs-$INSTANCE_NUM"
docker run -d \
--name $CONTAINER_NAME \
--privileged \
--cgroupns=host \
-v /sys/fs/cgroup:/sys/fs/cgroup:rw \
-v ./sober-logs-$INSTANCE_NUM:/root/.var/app/org.vinegarhq.Sober/data/sober/sober_logs \
-p $PORT:6080 \
--device /dev/dri \
--device /dev/snd \
--cpus="1.0" \
--memory="256m" \
--memory-swap="3g" \
--shm-size="256m" \
-e LIBGL_ALWAYS_SOFTWARE=1 \
-e GALLIUM_DRIVER=llvmpipe \
-e MESA_GL_VERSION_OVERRIDE=4.5 \
-e __GLX_VENDOR_LIBRARY_NAME=mesa \
-e EGL_PLATFORM=surfaceless \
sober-multi-roblox
if [ $? -eq 0 ]; then
echo ""
echo "✅ Instance $INSTANCE_NUM started successfully from custom image!"
echo "Access at: http://localhost:$PORT/vnc.html"
else
echo ""
echo "❌ Failed to start instance $INSTANCE_NUM"
fi
echo ""
}
stop_instance(){
read -p "Enter instance number to stop (or 'all' for all instances): " INSTANCE_NUM
if [ -z "$INSTANCE_NUM" ]; then
echo "❌ Instance number required!"
return
fi
if [[ "$INSTANCE_NUM" == "all" ]]; then
echo "Stopping all instances..."
docker ps --filter "name=sober-instance-" --format "{{.Names}}" | xargs -r docker stop
echo "✅ All instances stopped!"
else
CONTAINER_NAME="sober-instance-$INSTANCE_NUM"
docker stop "$CONTAINER_NAME" 2>/dev/null
if [ $? -eq 0 ]; then
echo "✅ Instance $INSTANCE_NUM stopped!"
else
echo "❌ Instance $INSTANCE_NUM not found or already stopped!"
fi
fi
echo ""
}
remove_instance(){
read -p "Enter instance number to remove (or 'all' for all instances): " INSTANCE_NUM
if [ -z "$INSTANCE_NUM" ]; then
echo "❌ Instance number required!"
return
fi
if [[ "$INSTANCE_NUM" == "all" ]]; then
read -p "⚠️  Remove ALL instances? (y/n): " confirm
if [[ "$confirm" == "y" ]]; then
echo "Removing all instances..."
docker ps -a --filter "name=sober-instance-" --format "{{.Names}}" | xargs -r docker rm -f
echo "✅ All instances removed!"
fi
else
CONTAINER_NAME="sober-instance-$INSTANCE_NUM"
read -p "⚠️  Remove instance $INSTANCE_NUM? (y/n): " confirm
if [[ "$confirm" == "y" ]]; then
docker rm -f "$CONTAINER_NAME" 2>/dev/null
if [ $? -eq 0 ]; then
echo "✅ Instance $INSTANCE_NUM removed!"
else
echo "❌ Instance $INSTANCE_NUM not found!"
fi
fi
fi
echo ""
}
while true; do
echo "╔══════════════════════════════════════╗"
echo "║  Sober Multi-Instance Manager        ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "1) List instances"
echo "2) Run/Start instance"
echo "3) Stop instance"
echo "4) Remove instance"
echo "5) Create image from instance (save with Roblox)"
echo "6) Run/Start instance from custom image"
echo "0) Exit"
echo ""
read -p "Select option: " choice
case $choice in
1) list_instances ;;
2) run_instance ;;
3) stop_instance ;;
4) remove_instance ;;
5) create_image_from_instance ;;
6) run_instance_from_image ;;
0) echo "Goodbye!"; exit 0 ;;
*) echo "❌ Invalid option!" ;;
esac
done
