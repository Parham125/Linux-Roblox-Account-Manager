FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    flatpak xdg-desktop-portal xdg-desktop-portal-gtk \
    mesa-utils libgl1-mesa-dri libglx-mesa0 libegl-mesa0 \
    vulkan-tools libvulkan1 mesa-vulkan-drivers \
    libosmesa6 libgl1 \
    dbus dbus-x11 \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
    flatpak install -y flathub org.vinegarhq.Sober

RUN mkdir -p /var/run/dbus

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
