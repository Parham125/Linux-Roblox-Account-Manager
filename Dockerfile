FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    VNC_RESOLUTION=1920x1080 \
    VNC_PORT=5901 \
    NOVNC_PORT=6080

RUN apt-get update && apt-get install -y \
    flatpak xdg-desktop-portal xdg-desktop-portal-gtk \
    mesa-utils libgl1-mesa-dri \
    vulkan-tools libvulkan1 mesa-vulkan-drivers \
    dbus dbus-x11 \
    tigervnc-standalone-server tigervnc-common \
    novnc websockify \
    xfce4 xfce4-terminal \
    supervisor \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
    flatpak install -y flathub org.vinegarhq.Sober

RUN mkdir -p /root/.vnc && \
    echo "sober123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

RUN echo '#!/bin/bash' > /root/.vnc/xstartup && \
    echo 'xfce4-session &' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

RUN mkdir -p /root/.config/autostart && \
    echo '[Desktop Entry]' > /root/.config/autostart/sober.desktop && \
    echo 'Type=Application' >> /root/.config/autostart/sober.desktop && \
    echo 'Name=Sober' >> /root/.config/autostart/sober.desktop && \
    echo 'Exec=/usr/bin/flatpak run org.vinegarhq.Sober' >> /root/.config/autostart/sober.desktop && \
    echo 'Terminal=false' >> /root/.config/autostart/sober.desktop && \
    echo 'StartupNotify=true' >> /root/.config/autostart/sober.desktop

RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

RUN mkdir -p /var/run/dbus

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080

ENTRYPOINT ["/entrypoint.sh"]
