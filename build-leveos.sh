#!/usr/bin/env bash
# LeveOS - gera uma ISO Linux leve (Debian + Xfce) para notebooks.
# Rode em Debian/Ubuntu (pode ser uma máquina virtual). Precisa de internet e ~15 GB livres.
# Uso: chmod +x build-leveos.sh && ./build-leveos.sh
set -euo pipefail

DIST="trixie"          # Debian estável
WORKDIR="$HOME/leveos-build"

sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso

mkdir -p "$WORKDIR" && cd "$WORKDIR"
sudo lb clean --purge || true

lb config \
  --distribution "$DIST" \
  --architectures amd64 \
  --archive-areas "main non-free-firmware" \
  --debian-installer live \
  --binary-images iso-hybrid \
  --iso-volume "LeveOS" \
  --iso-application "LeveOS" \
  --bootappend-live "boot=live components quiet splash locales=pt_BR.UTF-8 keyboard-layouts=br timezone=America/Sao_Paulo"

# Pacotes: desktop mínimo, rede, navegador e firmwares de Wi-Fi comuns
mkdir -p config/package-lists
cat > config/package-lists/leveos.list.chroot <<'EOF'
xorg
lightdm
xfce4-session
xfwm4
xfce4-panel
xfdesktop4
xfce4-terminal
xfce4-settings
thunar
mousepad
network-manager-gnome
firefox-esr
firefox-esr-l10n-pt-br
pipewire-audio
pavucontrol
zram-tools
firmware-linux
firmware-iwlwifi
firmware-realtek
firmware-atheros
locales
console-setup
EOF

# Serviços pesados desligados / ajustes de leveza
mkdir -p config/hooks/live
cat > config/hooks/live/0100-leve.hook.chroot <<'EOF'
#!/bin/sh
sed -i 's/^# *pt_BR.UTF-8/pt_BR.UTF-8/' /etc/locale.gen || true
locale-gen || true
systemctl disable bluetooth.service 2>/dev/null || true
systemctl disable ModemManager.service 2>/dev/null || true
EOF
chmod +x config/hooks/live/0100-leve.hook.chroot

sudo lb build

echo
echo "Pronto! ISO gerada em: $WORKDIR"
ls -lh "$WORKDIR"/*.iso
