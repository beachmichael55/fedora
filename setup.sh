#!/bin/bash
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
ORANGE=$(tput setaf 3)
BLUE=$(tput setaf 4)
PURPLE=$(tput setaf 5)
CYAN=$(tput setaf 6)
GREY=$(tput setaf 8)
sudo -v
( while true; do sudo -v; sleep 50; done ) &
SUDO_PID=$!
trap '[[ -n "$SUDO_PID" ]] && kill "$SUDO_PID"' EXIT
# Reusable prompt function for 'USER INPUT'
function prompt_choice() {
    local var_name=$1
    local prompt=$2
    shift 2
    local options=("$@")
    while true; do
        echo -e "${prompt}"
        for i in "${!options[@]}"; do
            printf "  %s) %s\n" "$((i + 1))" "${options[i]}"
        done
        read -rp "Choice [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            declare -g "$var_name"="${options[choice-1]}"
            break
        else
            echo -e "${RED}Invalid option.${RESET} Please enter a number between 1 and ${#options[@]}."
        fi
    done
}
# == USER INPUT ====
prompt_choice LAPTOP "Is this on a Laptop/Notebook?" "yes" "no"
if [[ "$LAPTOP" == "yes" ]]; then
	prompt_choice LAPTOP_TYPE "Is this a laptop (with Intel/NVIDIA hybrid graphics?" "yes" "no"
	if [[ "$LAPTOP_TYPE" == "yes" ]]; then
		echo "For Turing (GeForce RTX 2080 and earlier): Choose Proprietary"
		echo "For Ampere and later (RTX 3050+): Fedora already have drivers. Skip"
		prompt_choice LAPTOP_NVIDIA "What type of drivers do you want to use?" "PROPRIETARY" "SKIP"
	fi
fi
prompt_choice GPU "What Graphics card do you have?" "AMD" "NVIDIA" "INTEL"
prompt_choice NATIVE "Install Native or Flatpak software when possible." "Native" "Flatpak"
prompt_choice GAMING "Install Gaming stuff?" "yes" "no"
if [[ "$GAMING" == "yes" ]]; then
	prompt_choice EMULATOR "Install game emulators? Will be as flatpak" "yes" "no"
	if [[ "$EMULATOR" == "yes" ]]; then
		prompt_choice EMULATOR_E "Install more then just the emulators that only have Flatpaks available?(just like Dolphin)" "yes" "no"
	fi
	prompt_choice GPAD "Install extra gamepad suport?(like for XboxOne and PlayStation)" "yes" "no"
	prompt_choice OSRS "Install OSRS" "yes" "no"
	prompt_choice MINE "Install Minecraft" "yes" "no"
fi
prompt_choice VIRTM "Install QEMU VM Manager" "yes" "no"

prompt_choice DOCKER "Install Docker?" "yes" "no"

prompt_choice PROTON "Do you use ProtonVPN" "yes" "no"
if [[ "$GPU" == "AMD" ]]; then
	prompt_choice ROCM "Install ROCM for GPU AI" "yes" "no"
fi
if ! command -v winecfg &>/dev/null; then
	prompt_choice WINE "Wine not found. Install Wine" "yes" "no"
fi
########## List of packages and flatpaks
if [[ "$LAPTOP_NVIDIA" == "PROPRIETARY" ]]; then
	PKGS=(libva-vdpau-driver vdpauinfo xorg-x11-drv-nvidia-cuda-libs nvidia-settings akmod-nvidia xorg-x11-drv-nvidia-power intel-gpu-tools)
	sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"
fi
[[ "$GPU" == "INTEL" ]] && PKGS+=(intel-gpu-tools)
[[ "$GPU" == "AMD" ]] && PKGS+=(radeontop)
# General Software (native)
PKGS+=(git duperemove pv duf sg3_utils efitools python3-pip unrar fastfetch dkms java-latest-openjdk yt-dlp btrfs-assistant dnf-plugins-core cmake wmctrl xdotool ulauncher rclone-browser k3b par2cmdline meld iperf3)
GAMING_FLATPAKS=(com.valvesoftware.Steam.Utility.steamtinkerlaunch org.freedesktop.Platform.VulkanLayer.OBSVkCapture//25.08 com.steamgriddb.SGDBoop com.steamgriddb.steam-rom-manager com.vysp3r.ProtonPlus com.usebottles.bottles io.github.antimicrox.antimicrox com.valvesoftware.SteamLink com.github.mtkennerly.ludusavi)
# General Software (flatpak)
FLATPAK_PKGS=(com.github.tchx84.Flatseal it.mijorus.gearlever io.github.ilya_zlobintsev.LACT io.github.peazip.PeaZip fr.handbrake.ghb io.missioncenter.MissionCenter io.github.dvlv.boxbuddyrs io.github.cboxdoerfer.FSearch org.bionus.Grabber org.freefilesync.FreeFileSync io.github.giantpinkrobots.flatsweep net.mkiol.SpeechNote io.gitlab.adhami3310.Converter dev.vencord.Vesktop com.discordapp.Discord de.schmidhuberj.tubefeeder com.notepadqq.Notepadqq com.github.nrittsti.NTag com.github.Bleuzen.FFaudioConverter com.github.zocker_160.SyncThingy) 
if [[ "$NATIVE" == "Native" ]]; then
	PKGS+=(qbittorrent kate vlc calibre keepassxc audacity aegisub converseen mediainfo-gui thunderbird filezilla remmina wireshark)
else
	FLATPAK_PKGS+=(org.qbittorrent.qBittorrent org.kde.kate org.aegisub.Aegisub net.fasterland.converseen org.videolan.VLC com.calibre_ebook.calibre org.keepassxc.KeePassXC org.audacityteam.Audacity net.mediaarea.MediaInfoorg.filezillaproject.Filezilla org.remmina.Remmina org.wireshark.Wireshark org.mozilla.Thunderbird)
fi
if [[ "$GAMING" == "yes" ]]; then
	PKGS+=(steam vulkan)
	[[ "$GPAD" == "yes" ]] && PKGS+=(xpadneo xone lpf-xone-firmware dualsensectl)
	[[ "$EMULATOR" == "yes" ]] && EMULATOR_FLATPAK=(io.github.shiiion.primehack org.DolphinEmu.dolphin-emu)
	[[ "$EMULATOR_E" == "yes" ]] && EMULATOR_FLATPAK+=(io.github.ryubing.Ryujinx org.azahar_emu.Azahar info.cemu.Cemu org.ppsspp.PPSSPP io.mgba.mGBA net.pcsx2.PCSX2 net.kuribo64.melonDS com.github.Rosalie241.RMG net.shadps4.shadPS4 com.snes9x.Snes9x app.xemu.xemu net.rpcs3.RPCS3 com.github.AmatCoder.mednaffe org.flycast.Flycast org.libretro.RetroArch)
	[[ "$NATIVE" == "Native" ]] && PKGS+=(steam vkbasalt mangohud gamescope mame-tools restic goverlay)
	[[ "$NATIVE" == "Flatpak" ]]; then
		FLATPAK_PKGS+=(org.freedesktop.Platform.VulkanLayer.vkBasalt//25.08 org.freedesktop.Platform.VulkanLayer.MangoHud//23.08 org.freedesktop.Platform.VulkanLayer.MangoHud//25.08 org.freedesktop.Platform.VulkanLayer.gamescope//23.08 org.freedesktop.Platform.VulkanLayer.gamescope//25.08 com.github.Matoking.protontricks net.lutris.Lutris com.moonlight_stream.Moonlight dev.lizardbyte.app.Sunshine)
	fi
fi
[[ "$PROTON" == "yes" ]] && PKGS+=(proton-vpn-gtk-app proton-vpn-daemon python3-proton-vpn-network-manager)
[[ "$VIRTM" == "yes" ]] && PKGS+=(qemu-kvm libvirt virt-install bridge-utils virt-manager libvirt-devel virt-top guestfs-tools)
[[ "$ROCM" == "yes" ]] && PKGS+=(rocm-hip rocm-clinfo rocm-opencl)
[[ "$WINE" == "yes" ]] && PKGS+=(winehq-staging)
[[ "$MINE" == "yes" ]] && FLATPAK_PKGS+=(org.prismlauncher.PrismLauncher)
[[ "$OSRS" == "yes" ]] && FLATPAK_PKGS+=(com.adamcake.Bolt net.runelite.RuneLite)
[[ "$DOCKER" == "yes" ]] && PKGS+=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
# Adds the default to 'yes' for DNF. Change the default prompt behavior to make "yes" the default answer by editing the /etc/dnf/dnf.conf file. Add the following line to the [main] section 'defaultyes=True'
sudo tee /etc/dnf/dnf.conf > /dev/null <<EOF
[main]
defaultyes=True
EOF
# Deletes Fedora's Flatpak repository
sudo flatpak remote-delete fedora
# Add Flatpak repository
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Enables Proton repository
if [[ "$PROTON" == "yes" ]]; then
	wget "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d' ' -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"
	sudo dnf install ./protonvpn-stable-release-1.0.3-1.noarch.rpm
fi
# Adds the Wine-HQ repository
if [[ "$WINE" == "yes" ]]; then
	sudo dnf config-manager addrepo --from-repofile=https://dl.winehq.org/wine-builds/fedora/42/winehq.repo
fi
if [[ "$GPAD" == "yes" ]]; then
	sudo dnf copr enable atim/xpadneo
	sudo dnf copr enable sentry/xone
	sudo dnf copr enable trixieua/dualsensectl
fi
# Adds Docker repository
if [[ "$DOCKER" == "yes" ]]; then
	sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
fi
## Update repos before installings packages
sudo dnf update -y
sudo flatpak update -y
# Remove Installed Apps
sudo dnf remove -y kmahjongg kmines kpat okular neochat dragon
# Install via dnf
sudo dnf -y install ${PKGS}
sudo dnf clean all
# Install via Flatpak
if ! command -v flatpak &>/dev/null; then
  echo "Flatpak not found, installing..."
  sudo dnf install -y flatpak
fi
# Install each Flatpak package
ALL_FLATPAKS=("${FLATPAK_PKGS[@]}" "${EMULATOR_FLATPAK[@]}" "${GAMING_FLATPAKS[@]}")
flatpak install -y --noninteractive "${ALL_FLATPAKS[@]}"
# Enable systemd services
echo -"Enabling and Starting services..."
if [[ "$VIRTM" == "yes" ]]; then
	sudo systemctl enable libvirtd
	groups_lst="libvirt,kvm"
	sudo usermod -aG ${groups_lst} $(whoami)
	sudo sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' /etc/libvirt/libvirtd.conf
	sudo sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf
	sudo firewall-cmd --permanent --add-service=libvirt
	sudo firewall-cmd --permanent --add-port=5900-5999/tcp
	sudo firewall-cmd --permanent --add-port=16509/tcp
	sudo firewall-cmd --permanent --add-port=5666/tcp
	sudo firewall-cmd --reload
fi
if [[ "$DOCKER" == "yes" ]]; then
	sudo systemctl enable docker
	sudo docker run hello-world
fi
if [[ "$LAPTOP_NVIDIA" == "PROPRIETARY" ]]; then
	sudo dnf mark user akmod-nvidia
	sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume nvidia-powerd
fi
# Speed up boot time
sudo systemctl disable NetworkManager-wait-online.service
# Add the current user to 'render' and 'video' groups to access GPUs
echo -"Adding current user to render and video groups..."
groups_lst="sys,network,wheel,audio,storage,video,users,render"
sudo usermod -aG ${groups_lst} $(whoami)
####### Misc stuf ###########
# Upgrade pip and install Python tools like setuptools-rust, virtualenv
python -m ensurepip --upgrade
python -m pip install --upgrade pip setuptools wheel virtualenv setuptools-rust
# Download and set up bootnext tool
echo -"Downloading and Installing BOOTNEXT..."
if sudo curl -fSL "https://github.com/TensorWorks/bootnext/releases/download/v0.0.2/bootnext-linux-amd64" -o /usr/local/bin/bootnext; then
  sudo chmod +x /usr/local/bin/bootnext
else
  echo -e "Failed to download BOOTNEXT"
fi
## Post Gameing settings
# For Gamemode
if [[ "$GAMING" == "yes" ]]; then
	sudo usermod -aG gamemode $(whoami)
	if [ ! -f /etc/gamemode.ini ]; then
		sudo tee /etc/gamemode.ini > /dev/null <<EOF
[general]
reaper_freq=5
desiredgov=performance
igpu_desiredgov=powersave
igpu_power_threshold=0.3
softrealtime=off
renice=0
ioprio=0
inhibit_screensaver=1
disable_splitlock=1

[filter]
;whitelist=RiseOfTheTombRaider
;blacklist=HalfLife3

[gpu]
;apply_gpu_optimisations=0
;gpu_device=0
;nv_powermizer_mode=1
;nv_core_clock_mhz_offset=0
;nv_mem_clock_mhz_offset=0
;amd_performance_level=high

[cpu]
;park_cores=no
;pin_cores=yes

[supervisor]
;supervisor_whitelist=
;supervisor_blacklist=
;require_supervisor=0

[custom]
;start=notify-send "GameMode started"
;end=notify-send "GameMode ended"
;script_timeout=10'
EOF
	fi
	# Set Steam Firewall
	sudo firewall-cmd --permanent --add-port=27031-27036/udp &> /dev/null
	sudo firewall-cmd --permanent --add-port=27036/tcp &> /dev/null
	sudo firewall-cmd --permanent --add-port=27037/tcp &> /dev/null
fi
# Builds, installs XboxOne app
if [[ "$GPAD" == "yes" ]]; then
	sudo lpf approve xone-firmware
	sudo lpf build xone-firmware
	sudo lpf install xone-firmware
fi
# For Bash Aliases
touch "${HOME}/.bashrc"
touch "${HOME}/.bash_aliases"
	if ! grep -q "bash_aliases" "${HOME}/.bashrc"; then
		echo -e '\n# Source ~/.bash_aliases if it exists\n[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "${HOME}/.bashrc"
		echo "Added source line to ~/.bashrc"
	else
		echo "~/.bashrc already sources ~/.bash_aliases"
	fi
cat > "${HOME}/.bash_aliases" <<'EOF'
### Custom Aliases ###

# Clear screen and history
alias cls='clear'
alias acls='history -c; clear'

# List hidden files
alias lh='ls -a --color=auto'

# Directory commands
alias mkdir='mkdir -pv'
alias rmdir='rm -rdv'

# Safer file operations
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'

# Networking and package management
alias net?='ping google.com -c 5'

# System info
alias stats='sudo systemctl status'
alias fstats='sudo systemctl status > status.txt'
alias analyze='systemd-analyze'
alias blame='systemd-analyze blame'
alias chain='systemd-analyze critical-chain'
alias chart='systemd-analyze plot > test.svg'

# KDE
alias plasmareset='killall plasmashell; kstart plasmashell'

# Grep with color
alias grep='grep --colour=auto'

# DNF
alias add='sudo dnf install'
alias sp='dnf search'
alias rem='sudo dnf remove'
alias dnfe='sudo nano /etc/dnf/dnf.conf'

# Editors and config
alias nb='nano ~/.bashrc'
alias nano='vim'
alias n='nano'

# Fastfetch
alias ff='fastfetch'

# Disk and navigation
alias ld='lsblk'
alias up='cd ..'
alias up2='cd ../..'
alias up3='cd ../../..'
alias up4='cd ../../../..'
alias up5='cd ../../../../..'

# Network IP info
alias lan="ip addr show | grep 'inet ' | grep -v '127.0.0.1' | cut -d' ' -f6 | cut -d/ -f1"
alias lan6="ip addr show | grep 'inet6 ' | cut -d ' ' -f6 | sed -n '2p'"
alias wan='curl ipinfo.io/ip'

# Make all .sh files executable
#alias run='find . -type f -name \"*.sh\" -exec chmod +x {} \;'
alias run='find . -type f -name "*.sh" -exec chmod +x {} \;'

# Gaming and Wine tools
alias proton='protontricks --gui --no-bwrap'
alias bottles='flatpak run --command=bottles-cli com.usebottles.bottles'
EOF
sudo dnf autoremove
read -p "Completed. Press any key to close" -n1 -s
exit
