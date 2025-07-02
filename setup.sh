#!/bin/bash
### For echo colors, Misc
	#31: Red    35: Magenta
	#32: Green  36: Cyan
	#33: Yellow 37: White
	#34: Blue   90: Gray- bright black
	#1: before color makes BOLD
	# Example: \e[1;33mWhatever...\e[0m - 1;33m	Would be: 1 makes it bold, and 33 is Yellow. 0m , resets it back after.
	
	#read -p "Conpleted. Press any key to close" -n1 -s
LOGFILE="install_errors.log"
> "$LOGFILE"  # Clear the log file at the start

# Track installed and failed packages
installed=()
failed=()

# Serices
SERVICES=(
	"lactd"
	"nordvpnd"
)
########## List of packages and flatpaks
PKGS=(
	"git"
	"duperemove"
	"python3-pip"
	"unrar"
	"rocm-hip"
	"rocm-clinfo"
	"rocm-opencl"
	"java-latest-openjdk"
	"libva-utils"
	"corectrl"
	"fastfetch"
	"distrobox"
	"nordvpn"
	"btrfs-assistant"
	"cmake"
	"wmctrl"
	"xdotool"
	"steam"
)
FLATPAK_PKGS=(
	## General Software
	"com.github.tchx84.Flatseal"
	"it.mijorus.gearlever"
	"io.github.peazip.PeaZip"
	"org.qbittorrent.qBittorrent"
	"org.kde.kate"
	"org.videolan.VLC"
	"com.calibre_ebook.calibre"
	"org.keepassxc.KeePassXC"
	"org.audacityteam.Audacity"
	"com.github.zocker_160.SyncThingy"
	"net.mediaarea.MediaInfo"
	"fr.handbrake.ghb"
	"io.github.ilya_zlobintsev.LACT"
	"io.missioncenter.MissionCenter"
	"io.github.dvlv.boxbuddyrs"
	"io.github.cboxdoerfer.FSearch"
	"org.bionus.Grabber"
	"org.freefilesync.FreeFileSync"
	## Gaming Utilities
	#"com.valvesoftware.Steam"
	"com.valvesoftware.Steam.Utility.steamtinkerlaunch"
	"org.freedesktop.Platform.VulkanLayer.vkBasalt//24.08"
	"org.freedesktop.Platform.VulkanLayer.MangoHud//23.08"
	"org.freedesktop.Platform.VulkanLayer.MangoHud//24.08"
	"org.freedesktop.Platform.VulkanLayer.OBSVkCapture//24.08"
	"org.freedesktop.Platform.VulkanLayer.gamescope//23.08"
	"org.freedesktop.Platform.VulkanLayer.gamescope//24.08"
	"com.steamgriddb.SGDBoop"
	"com.github.Matoking.protontricks"
	"com.steamgriddb.steam-rom-manager"
	"codes.merritt.Nyrna"
	"com.vysp3r.ProtonPlus" #############
	"pupgui2" #ProtonUp-Qt
	"com.usebottles.bottles"
	"com.adamcake.Bolt"
	"net.runelite.RuneLite"
	"org.prismlauncher.PrismLauncher"
	"net.lutris.Lutris"
	## Emulators
	"io.github.ryubing.Ryujinx"
	"org.azahar_emu.Azahar"
	"app.xemu.xemu"
	"com.snes9x.Snes9x"
	"info.cemu.Cemu"
	"org.DolphinEmu.dolphin-emu"
	"org.duckstation.DuckStation"
	"org.ppsspp.PPSSPP"
	"io.mgba.mGBA"
	"net.pcsx2.PCSX2"
	"net.kuribo64.melonDS"
	"io.github.shiiion.primehack"
	"com.github.Rosalie241.RMG"
	"net.shadps4.shadPS4"
)

#### Repositories Section ##########
# Enables third party repositories
sudo sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/google-chrome.repo
sudo sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo
sudo sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo
sudo sed -i '0,/enabled=0/s//enabled=1/' /etc/yum.repos.d/rpmfusion-nonfree-steam.repo
# Deletes Fedora's Flatpak repository
sudo flatpak remote-delete fedora 
# Adds and enables RpmFusion Free and Nonfree Repositories
#sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# Import the GPG key for NordVPN repository
sudo rpm -v --import https://repo.nordvpn.com/gpg/nordvpn_public.asc
# Add NordVPN repository for installation
sudo dnf -y config-manager addrepo --id=nordvpn --set=name='NordVPN' --set=baseurl='https://repo.nordvpn.com/yum/nordvpn/centos/x86_64/'
# Add Flatpak repository
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Add Dolphin Emulator Flatpak repository
flatpak remote-add --if-not-exists dolphin-emu https://flatpak.dolphin-emu.org/releases.flatpakrepo

## Update repos before installings packages
sudo dnf update -y
sudo dnf update -y @core
sudo flatpak update -y
# Remove Installed Apps
sudo dnf remove -y kmahjongg kmines kpat okular akregator kmail neochat dragon

######## Package install Logic ##########
# Install via dnf
for pkg in "${PKGS[@]}"; do
  echo "Trying to install '$pkg' via dnf..."
  if sudo dnf -y install "$pkg"; then
    echo "✅ '$pkg' installed successfully via dnf."
    installed+=("$pkg")
  else
    echo "❌ Failed to install '$pkg' via dnf." | tee -a "$LOGFILE"
    failed+=("$pkg")
  fi
done
sudo dnf clean all

# Install via Flatpak
flatpak update -y
for pkg in "${FLATPAK_PKGS[@]}"; do
  echo "Trying to install '$pkg' via Flatpak..."
  if flatpak install --noninteractive flathub "$pkg"; then
    echo "✅ '$pkg' installed successfully via Flatpak."
    installed+=("$pkg")
  else
    echo "❌ Failed to install '$pkg' via Flatpak." | tee -a "$LOGFILE"
    failed+=("$pkg")
  fi
done
# Summary
echo -e "\nInstallation Summary:"
echo "---------------------"
[[ ${#installed[@]} -gt 0 ]] && echo "✅ Installed: ${installed[*]}"
[[ ${#failed[@]} -gt 0 ]] && echo "❌ Failed:    ${failed[*]}"

# Enable systemd services
echo -e "\e[1;33mEnabling and Starting services...\e[0m"
for svc in "${SERVICES[@]}"; do
  sudo systemctl enable --now "$svc"
done

# Add the current user to 'render' and 'video' groups to access GPUs
echo -e "\e[1;33mAdding current user to render and video groups...\e[0m"
sudo usermod -a -G render,video "$LOGNAME"

####### Misc Software ###########
# Upgrade pip and install Python tools like setuptools-rust, virtualenv
python -m ensurepip --upgrade
python -m pip install --upgrade pip setuptools wheel virtualenv setuptools-rust

# Download and set up bootnext tool
echo -e "\e[1;33mDownlaoding and Installing BOOTNEXT...\e[0m"
sudo curl -fSL "https://github.com/TensorWorks/bootnext/releases/download/v0.0.2/bootnext-linux-amd64" -o /usr/local/bin/bootnext
sudo chmod +x /usr/local/bin/bootnext

# Download Chatbox (AppImage)
curl -fSL "https://download.chatboxai.app/releases/Chatbox-1.11.12-x86_64.AppImage" -o ~/Chatbox-1.11.12-x86_64.AppImage

# For ALL AppImage's
sudo chmod +x ~/*.AppImage

######## Ending tasks
# configure WineHQ Staging
echo "Setup Wine now: (1) Yes, (2) No"
read WINE_CHOICE
[[ "$WINE_CHOICE" == "1" ]] && WINE="yes"
[[ "$WINE_CHOICE" == "2" ]] && WINE="no"
[[ -z "$WINE" ]] && echo "Invalid option" && exit 1

if [[ "$WINE" == "yes" ]]; then
	winecfg
fi

# configure VM
echo "Setup Virtual Machine Manager now: (1) Yes, (2) No"
read WINE_CHOICE
[[ "$VM_CHOICE" == "1" ]] && VIRTM="yes"
[[ "$VM_CHOICE" == "2" ]] && VIRTM="no"
[[ -z "$VIRTM" ]] && echo "Invalid option" && exit 1

if [[ "$VIRTM" == "yes" ]]; then
	sudo dnf install -y qemu-kvm libvirt virt-install bridge-utils virt-manager libvirt-devel virt-top libguestfs-tools guestfs-tools
	sudo systemctl enable --now libvirtd
fi

read -p "Completed. Press any key to close" -n1 -s
exit