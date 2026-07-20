#!/usr/bin/env bash

DIR="$HOME/Dotfiles"
if [ -d "$DIR" ]; then
  echo "The directory ~/Dotfiles exists. Pulling latest changes..."
  cd "$DIR" && git pull && cd - >/dev/null
else
  echo "The directory ~/Dotfiles does not exist. Cloning repository..."
  git clone https://github.com/Boing-Git/My-Dotfiles "$DIR"
fi

if grep -qi "nixos" /etc/os-release; then
    echo "Detected NixOS..."
    
    git clone https://github.com/Boing-Git/My-NixOs-Dotfiles ~/Nixos
    cd ~/Nixos
    
    echo "Installing dotfiles..."
    mkdir -p ~/.config
    for item in ~/Dotfiles/* ~/Dotfiles/.* ; do
        name=$(basename "$item")
        if [[ "$name" == "." || "$name" == ".." || "$name" == ".git" || "$name" == "README.md" || "$name" == "CONTRIBUTING.md" || "$name" == "LICENSE" || "$name" == "install.sh" || "$name" == "RELEASE.md" || "$name" == "scripts" ]]; then
            continue
        fi
        
        if [ -d "$item" ]; then
            mkdir -p ~/.config/"$name"
            cp -rT "$item" ~/.config/"$name"
        elif [ -f "$item" ]; then
            cp "$item" ~/.config/"$name"
        fi
    done

    echo "Setting up omniformis CLI tool..."
    mkdir -p ~/.local/bin
    curl -L "https://github.com/Boing-Git/OmniFormis-Shell/releases/latest/download/omniformis" -o ~/.local/bin/omniformis
    chmod +x ~/.local/bin/omniformis
    
    echo "Adding ~/.local/bin to Fish PATH..."
    if command -v fish >/dev/null 2>&1; then
        fish -c 'if not contains ~/.local/bin $fish_user_paths; set -Ua fish_user_paths ~/.local/bin; end'
    fi

    cp /etc/nixos/hardware-configuration.nix ./

    ln -sf ~/Dotfiles/fastfetch/Nixos.jsonc ~/Dotfiles/fastfetch/config.jsonc
    
    sudo nixos-rebuild switch --flake .#nixos

elif grep -qi "arch" /etc/os-release; then
    set -e
    
    echo "Starting Arch Linux Dependencies & Dotfiles Installation..."
    
    # Ensure yay is installed
    if ! command -v yay &> /dev/null; then
        echo "yay is not installed. Installing yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        rm -rf /tmp/yay
    fi
    
    echo "Installing system packages and dependencies..."
    yay -S --needed --noconfirm --answerclean None --answerdiff None --answeredit None \
        git wezterm ttf-space-mono-nerd papirus-icon-theme nautilus unzip curl fontconfig \
        file-roller jq btop eza zoxide wl-clipboard cliphist xdg-utils gtk3 \
        desktop-file-utils cairo pango tree gobject-introspection cbonsai lua \
        ffmpeg fuzzel loupe grim slurp playerctl satty blanket github-cli hypridle \
        cmake ninja pkgconf qt6-base qt6-declarative ddcutil brightnessctl \
        lm_sensors networkmanager pipewire fish bash swappy libqalculate aubio \
        cava fftw xkeyboard-config ttf-cascadia-code-nerd \
        tk python-gobject python-flask \
        starship hyprland base-devel \
        vlc python qemu-desktop libvirt swtpm dconf gamemode \
        fastfetch pavucontrol ttf-dejavu prismlauncher hyprpicker \
        inotify-tools ncdu gsettings-desktop-schemas neovim zed matugen-bin
    
    echo "Installing AUR packages..."
    yay -S --needed --noconfirm --answerclean None --answerdiff None --answeredit None \
        quickshell-git vscodium-bin papirus-folders spotify nitch \
        awww-git upscayl-bin github-desktop-bin nixfmt nixd antigravity \
        app2unit ttf-space-mono \
        hexecute-git \
        python-pywebview zen-browser \
        mpvpaper googledot-cursor-theme pipes.sh spicetify-cli python-emoji
    
    echo "Forcing installation of fonts..."
    yay -S --noconfirm --answerclean None --answerdiff None --answeredit None \
        ttf-material-symbols-variable
    
    echo "Manually installing Rubik font (AUR package is broken)..."
    # 1. Create a dedicated directory for Rubik in your local fonts folder
    mkdir -p ~/.local/share/fonts/Rubik
    
    # 2. Download the Rubik family ZIP from Google Fonts using curl
    # (-L ensures curl follows any redirects, -o specifies the output file)
    curl -L "https://fonts.google.com/download?family=Rubik" -o ~/.local/share/fonts/Rubik/Rubik.zip
    
    # 3. Extract the downloaded ZIP file into the new directory
    unzip -o ~/.local/share/fonts/Rubik/Rubik.zip -d ~/.local/share/fonts/Rubik/
    
    # 4. Remove the leftover ZIP file to keep things clean
    rm ~/.local/share/fonts/Rubik/Rubik.zip
    
    # 5. Force the system to rebuild its font cache so it detects Rubik immediately
    fc-cache -fv
    
    echo "Installing dotfiles..."
    
    mkdir -p ~/.config
    for item in ~/Dotfiles/* ~/Dotfiles/.* ; do
        name=$(basename "$item")
        # Skip parent directories, git folder, repo specific files, and scripts (which go to bin)
        if [[ "$name" == "." || "$name" == ".." || "$name" == ".git" || "$name" == "README.md" || "$name" == "CONTRIBUTING.md" || "$name" == "LICENSE" || "$name" == "install.sh" || "$name" == "RELEASE.md" || "$name" == "scripts" ]]; then
            continue
        fi
        
        if [ -d "$item" ]; then
            mkdir -p ~/.config/"$name"
            cp -rT "$item" ~/.config/"$name"
        elif [ -f "$item" ]; then
            cp "$item" ~/.config/"$name"
        fi
    done
    
    echo "Running post-installation configurations..."
    
    echo "Configuring Virtualization..."
    sudo usermod -aG libvirt,kvm "$USER"
    sudo systemctl enable libvirtd
    
    echo "Applying Custom Hacks and Derivations..."
    # Antigravity Scaled Desktop File
    mkdir -p ~/.local/share/applications
    if [ -f /usr/share/applications/antigravity.desktop ]; then
        cp /usr/share/applications/antigravity.desktop ~/.local/share/applications/antigravity-scaled.desktop
        sed -i 's/^Name=Antigravity/Name=Antigravity (Scaled)/' ~/.local/share/applications/antigravity-scaled.desktop
        sed -i 's|^Exec=antigravity|Exec=antigravity --force-device-scale-factor=2|g' ~/.local/share/applications/antigravity-scaled.desktop
    fi
    
    # Btop Symlink Hack
    mkdir -p ~/.config
    ln -sf ~/.local/share/caelestia/btop ~/.config/btop
    
    # Papirus Icon Cleanup
    sudo rm -rf /usr/share/icons/Papirus-Light
    
    echo "Configuring VSCodium..."
    for ext in jnoortheen.nix-ide mvllow.rose-pine haikalllp.matugen-theme; do
        codium --install-extension $ext || true
    done
    
    # VSCodium LSP Hack
    mkdir -p ~/.config/quickshell/Pill
    touch ~/.config/quickshell/Pill/.qmlls.ini
    
    echo "Configuring Spicetify..."
    rm -rf ~/.local/share/spotify-spicetify
    mkdir -p ~/.local/share/spotify-spicetify
    
    if [ -d "/opt/spotify" ]; then
        cp -rT /opt/spotify ~/.local/share/spotify-spicetify
    elif command -v spotify >/dev/null; then
        SPOTIFY_BIN=$(readlink -f $(command -v spotify))
        SPOTIFY_SHARE="$(dirname "$SPOTIFY_BIN")"
        if [[ "$SPOTIFY_SHARE" == */bin ]]; then
            SPOTIFY_SHARE="$(dirname "$SPOTIFY_SHARE")/share/spotify"
        fi
        if [ -d "$SPOTIFY_SHARE" ]; then
            cp -rT "$SPOTIFY_SHARE" ~/.local/share/spotify-spicetify
        fi
    fi
    chmod -R a+wr ~/.local/share/spotify-spicetify
    
    # On NixOS, the copied 'spotify' might be a wrapper script pointing to '.spotify-wrapped' in the Nix store.
    # We must patch this local wrapper to execute the local binary, otherwise it loads the unmodified Nix store binary!
    if grep -qi "nixos" /etc/os-release && [ -f ~/.local/share/spotify-spicetify/.spotify-wrapped ]; then
        sed -i -E "s|/nix/store/[^/]+/share/spotify/\.spotify-wrapped|$HOME/.local/share/spotify-spicetify/.spotify-wrapped|g" ~/.local/share/spotify-spicetify/spotify
    fi
    
    mkdir -p ~/.local/share/applications
    rm -f ~/.local/share/applications/spotify.desktop
    if [ -f /usr/share/applications/spotify.desktop ]; then
        cp /usr/share/applications/spotify.desktop ~/.local/share/applications/spotify.desktop
        sed -i "s|^Exec=spotify|Exec=$HOME/.local/bin/spotify|" ~/.local/share/applications/spotify.desktop
    elif [ -f /run/current-system/sw/share/applications/spotify.desktop ]; then
        cp /run/current-system/sw/share/applications/spotify.desktop ~/.local/share/applications/spotify.desktop
        sed -i "s|^Exec=spotify|Exec=$HOME/.local/bin/spotify|" ~/.local/share/applications/spotify.desktop
    fi
    
    mkdir -p ~/.local/bin
    ln -sf ~/.local/share/spotify-spicetify/spotify ~/.local/bin/spotify

    spicetify config extensions adblockify.js beautifulLyrics.js popupLyrics.js spicyLyrics.js fullAppDisplay.js || true
    spicetify backup apply || true
    
    echo "Setting Environment Variables in Fish..."
    mkdir -p ~/.config/fish
    if ! grep -q "set -gx EDITOR codium" ~/.config/fish/config.fish 2>/dev/null; then
        echo 'set -gx EDITOR codium' >> ~/.config/fish/config.fish
        echo 'set -gx QML_IMPORT_PATH /usr/lib/qt6/qml' >> ~/.config/fish/config.fish
    fi
    
    echo "Setting Default Cursor..."
    mkdir -p ~/.icons/default
    echo '[Icon Theme]' > ~/.icons/default/index.theme
    echo 'Inherits=GoogleDot-Black' >> ~/.icons/default/index.theme
    
    echo "Setting up omniformis CLI tool..."
    mkdir -p ~/.local/bin
    curl -L "https://github.com/Boing-Git/OmniFormis-Shell/releases/latest/download/omniformis" -o ~/.local/bin/omniformis
    chmod +x ~/.local/bin/omniformis
    
    echo "Adding ~/.local/bin to Fish PATH..."
    if command -v fish >/dev/null 2>&1; then
        fish -c 'if not contains ~/.local/bin $fish_user_paths; set -Ua fish_user_paths ~/.local/bin; end'
    fi
    
    echo "Setting default shell to fish..."
    if [ "$SHELL" != "/usr/bin/fish" ]; then
        sudo chsh -s /usr/bin/fish "$USER"
    fi
    
    echo "Installation complete! Please reboot your system."

else
    echo "Unsupported OS! This script only supports NixOS and Arch Linux."
    exit 1
fi

cp  ~/Dotfiles/fastfetch/Arch.jsonc ~/.config/fastfetch/config.jsonc
cp  ~/Dotfiles/fastfetch/Logos/Arch.png ~/.config/fastfetch/Arch.png
