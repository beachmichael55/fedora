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

sudo -v
( while true; do sudo -v; sleep 50; done ) &
SUDO_PID=$!
trap '[[ -n "$SUDO_PID" ]] && kill "$SUDO_PID"' EXIT

# CPU vendor
if cat /proc/cpuinfo | grep "vendor" | grep "GenuineIntel" > /dev/null; then
	export CPU="Intel"
elif cat /proc/cpuinfo | grep "vendor" | grep "AuthenticAMD" > /dev/null; then
	export CPU="AMD"
    export AMD_SCALING_DRIVER="amd_pstate=active"
fi
# GPU vendor
if lspci | grep -E "VGA|3D" | grep -q "Intel"; then
    export GPU_PACKAGES="vulkan-intel intel-media-driver intel-gpu-tools libva-intel-driver"
	export GPU="Intel"
elif lspci | grep -E "VGA|3D" | grep -q "AMD"; then
    export GPU_PACKAGES="vulkan-radeon libva-mesa-driver radeontop mesa-vdpau xf86-video-amdgpu xf86-video-ati corectrl"
	export GPU="AMD"
elif lspci | grep -E "VGA|3D" | grep -q "NVIDIA"; then
    export GPU_PACKAGES="dkms nvidia-utils nvidia-dkms nvidia-settings lib32-nvidia-utils libva-vdpau-driver"
	export GPU="NVIDIA"
fi

# Reusable prompt function for 'USER INPUT'
prompt_choice() {
	local var_name=$1
	local prompt=$2
	local opt1=$3
	local opt2=$4

	while true; do
		echo "$prompt: (1) $opt1, (2) $opt2"
		read -rp "Choice: " choice
		case "$choice" in
			1) eval "$var_name=\"$opt1\"" ; break ;;
			2) eval "$var_name=\"$opt2\"" ; break ;;
			*) echo "Invalid option. Please enter 1 or 2." ;;
		esac
	done
}
# == USER INPUT ====
prompt_choice NATIVE "Install Native or Flatpak software when possible" "Native" "Flatpak"
prompt_choice GAMING "Install Gaming stuff" "yes" "no"
if [[ "$GAMING" == "yes" ]]; then
	prompt_choice EMULATOR "Install game emulators" "yes" "no"
	if [[ "$EMULATOR" == "yes" ]]; then
		prompt_choice EMULATOR_V "Install AppImages or Flatpak versions of emulators" "appimage" "flatpak"
		
		if [[ "$EMULATOR_V" == "appimage" ]]; then
			prompt_choice CANARY_EMULATOR "Use Canary version when possible?" "yes" "no"
			prompt_choice DESKTOP_INTEGRATION "Create launcher shortcuts for Emulator AppImages?" "yes" "no"
		fi
	fi

	prompt_choice OSRS "Install OSRS" "yes" "no"
	prompt_choice MINE "Install Minecraft" "yes" "no"
fi
prompt_choice VIRTM "Install QEMU VM Manager" "yes" "no"
prompt_choice PROTON "Do you use ProtonVPN" "yes" "no"
if [[ "$GPU" == "AMD" ]]; then
	prompt_choice ROCM "Install ROCM for GPU AI" "yes" "no"
fi
if ! command -v winecfg &>/dev/null; then
	prompt_choice WINE "Wine not found. Install Wine" "yes" "no"
fi

NORD

# Track installed and failed packages
installed=()
failed=()
########## List of packages and flatpaks
PKGS=(
	"git"
	"duperemove"
	"python3-pip"
	"unrar"
	"libva-utils"
	"corectrl"
	"fastfetch"
	"distrobox"
	"java-latest-openjdk"
	"btrfs-assistant"
	"cmake"
	"wmctrl"
	"xdotool"
	"jq"
	"curl"
	"unzip"
	"ulauncher"
	"rclone-browser"
	"k3b"
	"par2cmdline"
	"meld"
	"iperf3"
)
GAMING_FLATPAKS=(
	"com.valvesoftware.Steam.Utility.steamtinkerlaunch"
	"org.freedesktop.Platform.VulkanLayer.OBSVkCapture//24.08"
	"com.steamgriddb.SGDBoop"
	"com.steamgriddb.steam-rom-manager"
	"com.vysp3r.ProtonPlus"
	"com.usebottles.bottles"
	"io.github.antimicrox.antimicrox"
	"com.valvesoftware.SteamLink"
	"com.github.mtkennerly.ludusavi"
)
FLATPAK_PKGS=(
	## General Software
	"com.github.tchx84.Flatseal"
	"it.mijorus.gearlever"
	"io.github.peazip.PeaZip"
	"fr.handbrake.ghb"
	"io.github.ilya_zlobintsev.LACT"
	"io.missioncenter.MissionCenter"
	"io.github.dvlv.boxbuddyrs"
	"io.github.cboxdoerfer.FSearch"
	"org.bionus.Grabber"
	"org.freefilesync.FreeFileSync"
	"io.github.giantpinkrobots.flatsweep"
	"net.mkiol.SpeechNote"
	"io.gitlab.adhami3310.Converter"
	#"dev.vencord.Vesktop"
	"com.discordapp.Discord"
	"org.filezillaproject.Filezilla"
	"com.geeks3d.furmark"
)
EMULATOR_FLATPAKS=(
	"io.github.ryubing.Ryujinx"
	"org.azahar_emu.Azahar"
	"info.cemu.Cemu"
	"org.ppsspp.PPSSPP"
	"io.mgba.mGBA"
	"net.pcsx2.PCSX2"
	"net.kuribo64.melonDS"
	"io.github.shiiion.primehack"
	"com.github.Rosalie241.RMG"
	"net.shadps4.shadPS4"
	"org.DolphinEmu.dolphin-emu"
	"com.snes9x.Snes9x"
	"app.xemu.xemu"
)

if [[ "$NATIVE" == "Native" ]]; then
	PKGS+=(
	"qbittorrent"
	"kate"
	"vlc"
	"calibre"
	"keepassxc"
	"audacity"
	"aegisub"
	"digikam"
	"converseen"
	"syncthing"
	"mediainfo"
	"thunderbird"
	"pipeline"
	"filezilla"
	"remmina"
	"iperf3"
	"wireshark")
else
	FLATPAK_PKGS+=(
	"org.qbittorrent.qBittorrent"
	"org.kde.kate"
	"com.github.nrittsti.NTag"
	"org.aegisub.Aegisub"
	"org.kde.digikam.desktop"
	"net.fasterland.converseen"
	"com.notepadqq.Notepadqq"
	"com.github.Bleuzen.FFaudioConverter"
	"org.videolan.VLC"
	"com.calibre_ebook.calibre"
	"org.keepassxc.KeePassXC"
	"org.audacityteam.Audacity"
	"com.github.zocker_160.SyncThingy"
	"net.mediaarea.MediaInfo"
	"de.schmidhuberj.tubefeeder"
	"net.mkiol.SpeechNote"
	"io.gitlab.adhami3310.Converter"
	#"dev.vencord.Vesktop"
	"com.discordapp.Discord"
	"org.filezillaproject.Filezilla"
	"com.geeks3d.furmark"
	"org.remmina.Remmina.desktop"
	"org.wireshark.Wireshark")
fi
if [[ "$GAMING" == "yes" ]]; then
	[[ "$NATIVE" == "Native" ]] && PKGS+=(
		"steam"
		"vkBasalt"
		"mangohub.x86_64"
		"gamescope"
		"lutris"
		"protontricks"
		"mame-tools"
		"restic"
		"goverlay")
	[[ "$NATIVE" == "Flatpak" ]] && FLATPAK_PKGS+=(
		"com.valvesoftware.Steam"
		"org.freedesktop.Platform.VulkanLayer.vkBasalt//24.08"
		"org.freedesktop.Platform.VulkanLayer.MangoHud//23.08"
		"org.freedesktop.Platform.VulkanLayer.MangoHud//24.08"
		"org.freedesktop.Platform.VulkanLayer.gamescope//23.08"
		"org.freedesktop.Platform.VulkanLayer.gamescope//24.08"
		"com.github.Matoking.protontricks" "net.lutris.Lutris"
		"com.moonlight_stream.Moonlight"
		"dev.lizardbyte.app.Sunshine")
fi
[[ "$PROTON" == "yes" ]] && PKGS+=("proton-vpn-gnome-desktop")
[[ "$VIRTM" == "yes" ]] && PKGS+=("qemu-kvm" "libvirt" "virt-install" "bridge-utils" "virt-manager" "libvirt-devel" "virt-top" "libguestfs-tools" "guestfs-tools")
[[ "$ROCM" == "yes" ]] && PKGS+=("rocm-hip" "rocm-clinfo" "rocm-opencl")
[[ "$WINE" == "yes" ]] && PKGS+=("wine")
[[ "$MINE" == "yes" ]] && FLATPAK_PKGS+=("org.prismlauncher.PrismLauncher")
[[ "$OSRS" == "yes" ]] && FLATPAK_PKGS+=("com.adamcake.Bolt" "net.runelite.RuneLite")
[[ "$EMULATOR_V" == "flatpak" ]] && FLATPAK_PKGS+=("${EMULATOR_FLATPAKS[@]}")

#### Repositories Section ##########
# Enables third party repositories
for repo in \
    /etc/yum.repos.d/google-chrome.repo \
    /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo \
    /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo \
    /etc/yum.repos.d/rpmfusion-nonfree-steam.repo; do

    [[ -f "$repo" ]] && sudo sed -i '0,/enabled=0/s//enabled=1/' "$repo"
done
# Deletes Fedora's Flatpak repository
sudo flatpak remote-delete fedora 
# Adds and enables RpmFusion Free and Nonfree Repositories
#sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# Add Flatpak repository
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Enables Proton repository
if [[ "$PROTON" == "yes" ]]; then
# Import the GPG key for protonvpn repository
wget "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d' ' -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"
# Add NordVPN repository for installation
sudo dnf install ./protonvpn-stable-release-1.0.3-1.noarch.rpm && sudo dnf check-update --refresh
fi

## Update repos before installings packages
sudo dnf update -y
sudo flatpak update -y
# Remove Installed Apps
sudo dnf remove -y kmahjongg kmines kpat okular akregator kmail neochat dragon

######## Package install Logic ##########
# Install via dnf
for pkg in "${PKGS[@]}"; do
  echo "Trying to install '$pkg' via dnf..."
  if sudo dnf -y install "$pkg"; then
    echo "'$pkg' installed successfully via dnf."
    installed+=("$pkg")
  else
    echo "Failed to install '$pkg' via dnf." | tee -a "$LOGFILE"
    failed+=("$pkg")
  fi
done
sudo dnf clean all

# Install via Flatpak
if ! command -v flatpak &>/dev/null; then
  echo "Flatpak not found, installing..."
  sudo dnf install -y flatpak
fi

# Install each Flatpak package
for pkg in "${FLATPAK_PKGS[@]}"; do
  echo "Trying to install '$pkg' via Flatpak..."
  if flatpak install -y --noninteractive "$pkg"; then
    installed+=("$pkg")
  else
    echo "Failed to install '$pkg' via Flatpak." | tee -a "$LOGFILE"
    failed+=("$pkg")
  fi
done


# Enable systemd services
echo -e "\e[1;33mEnabling and Starting services...\e[0m"
if [[ "$VIRTM" == "yes" ]]; then
	sudo systemctl enable --now libvirtd
fi

# Add the current user to 'render' and 'video' groups to access GPUs
echo -e "\e[1;33mAdding current user to render and video groups...\e[0m"
sudo usermod -a -G render,video "$LOGNAME"

######## EMULATOR Appimages ###################
# ===Generate .desktop File Function
create_desktop_file() {
    local name="$1"           # Duckstation
    local path="$2"           # /home/user/Games/Emulators/Duckstation/Duckstation.AppImage
    local icon_path="$3"      # Optional, if you download an icon

    local desktop_file="$HOME/.local/share/applications/${name,,}.desktop"  # lowercase

    cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=$name
Exec="$path"
Icon=${icon_path:-application-x-executable}
Type=Application
Categories=Game;Emulator;
Terminal=false
Icon=${icon_path:-application-x-executable}
EOF

    chmod +x "$desktop_file"
    update-desktop-database ~/.local/share/applications/ &>/dev/null
}


# Function for emulators
install_appimage_emulator() {
	local repo="$1"       # e.g., "mgba-emu/mgba"
	local pattern="$2"    # e.g., "x64.appimage$"
	local name="$3"       # e.g., "mGBA"
	local subpath="$4"    # Optional subdir in zip
	local custom_api_url="$5"  # Optional override API URL
	local icon_name="${6:-${name,,}}"  # defaults to lowercase $name

	local workdir
	workdir=$(mktemp -d)
	trap 'rm -rf "$workdir"' EXIT
	cd "$workdir" || exit 1

	local installdir="$HOME/Games/Emulators/$name"
	local install_file="$installdir/$name.AppImage"
	mkdir -p "$installdir"

	local api_url="${custom_api_url:-https://api.github.com/repos/$repo/releases/latest}"
	local api_response
	api_response=$(curl -s "$api_url")

	local latest_url
	latest_url=$(echo "$api_response" | jq -r ".assets[] | select(.name | test(\"$pattern\")) | .browser_download_url")

	if [[ -z "$latest_url" ]]; then
		echo -e "\e[1;31mNo matching AppImage found for $name\e[0m"
		return
	fi

	curl -sLOJ "$latest_url"
	if [[ "$latest_url" == *.zip ]]; then
		unzip -q "$(basename "$latest_url")" -d "$workdir"
		unzip -q "$(basename "$latest_url")" -d "$workdir"
		appimage_source=$(find "$workdir/$subpath" -iname "*.AppImage" | head -n 1)
	else
		appimage_source=$(find . -maxdepth 1 -iname "*.AppImage" | head -n 1)
	fi

	if [[ -z "$appimage_source" ]]; then
		echo -e "\e[1;31mFailed to extract AppImage for $name\e[0m"
		return
	fi

	mv "$appimage_source" "$install_file"
	chmod +x "$install_file"

	mkdir -p "$installdir/${name}.AppImage.home"
	mkdir -p "$installdir/${name}.AppImage.config"

	# Download icon if enabled
	if [[ "$DESKTOP_INTEGRATION" == "yes" ]]; then
		icon_url="https://raw.githubusercontent.com/beachmichael55/emulator-icons/main/icons/${icon_name}.png"
		icon_path="$installdir/icon.png"
		if curl -fsSL "$icon_url" -o "$icon_path"; then
			create_desktop_file "$name" "$install_file" "$icon_path"
		else
			create_desktop_file "$name" "$install_file"
		fi
	fi
}
# Run emulator function to download and setup
if [[ "$EMULATOR_V" == "appimage" ]]; then
	install_appimage_emulator "azahar-emu/azahar" "\.AppImage$" "Azahar"
	install_appimage_emulator "cemu-project/Cemu" "\.AppImage$" "Cemu"
	install_appimage_emulator "stenzek/duckstation" "x64\.AppImage$" "Duckstation"
	install_appimage_emulator "melonDS-emu/melonDS" "appimage-x86_64.zip$" "melonDS"
	install_appimage_emulator "mgba-emu/mgba" "x64.appimage$" "mGBA"
	install_appimage_emulator "Rosalie241/RMG" "\.AppImage$" "RMG"
	install_appimage_emulator "RPCS3/rpcs3-binaries-linux" "\.AppImage$" "RPCS3"
	install_appimage_emulator "Ryubing/Stable-Releases" "x64\.AppImage$" "Ryubing"
	install_appimage_emulator "xemu-project/xemu" "x86_64\.AppImage" "Xemu"
	install_appimage_emulator "snes9xgit/snes9x" "x86_64\.AppImage$" "Snes9x"
	
	if [[ "$CANARY_EMULATOR" == "yes" ]]; then
		install_appimage_emulator "PCSX2/pcsx2" "Qt\.AppImage$" "Pcsx2" "" "https://api.github.com/repos/PCSX2/pcsx2/releases"
	else
		install_appimage_emulator "PCSX2/pcsx2" "Qt\.AppImage$" "Pcsx2"
	fi
	if [[ "$CANARY_EMULATOR" == "yes" ]]; then
		install_appimage_emulator "shadps4-emu/shadPS4" "linux-qt.*\.zip$" "ShadPS4" "" "https://api.github.com/repos/shadps4-emu/shadPS4/releases"
	else
		install_appimage_emulator "shadps4-emu/shadPS4" "linux-qt.*\.zip$" "ShadPS4"
	fi

fi

####### Misc Software ###########
# Upgrade pip and install Python tools like setuptools-rust, virtualenv
python -m ensurepip --upgrade
python -m pip install --upgrade pip setuptools wheel virtualenv setuptools-rust

# Download and set up bootnext tool
echo -e "\e[1;33mDownloading and Installing BOOTNEXT...\e[0m"
if sudo curl -fSL "https://github.com/TensorWorks/bootnext/releases/download/v0.0.2/bootnext-linux-amd64" -o /usr/local/bin/bootnext; then
  sudo chmod +x /usr/local/bin/bootnext
else
  echo -e "\e[1;31mFailed to download BOOTNEXT\e[0m" | tee -a "$LOGFILE"
  failed+=("bootnext")
fi

######## Ending tasks
# configure/ install Wine
if [[ "$WINE" == "yes" ]]; then
echo -e "\e[1;36mLaunching Wine configuration window... this may take a few moments.\e[0m"
winecfg
fi

# Summary
echo -e "\n\e[1;32mInstallation Summary:\e[0m"
[[ ${#installed[@]} -gt 0 ]] && echo -e "\e[1;32mInstalled:\e[0m ${installed[*]}"
[[ ${#failed[@]} -gt 0 ]] && echo -e "\e[1;31mFailed:\e[0m ${failed[*]} (see $LOGFILE)"


read -p "Completed. Press any key to close" -n1 -s
exit
