#!/bin/bash
set -e  # exit on error

# -------------------------------
#  Check if running as root/sudo
# -------------------------------
if [ "$EUID" -eq 0 ]; then
    echo "[!] This script should not be run as root or with sudo."
    echo "[!] Please run as a regular user."
    exit 1
fi

# -------------------------------
#  Update system
# -------------------------------
echo "[*] Updating system..."
sudo pacman -Syu --noconfirm

# -------------------------------
#  Install core packages
# -------------------------------
echo "[*] Installing core packages..."
sudo pacman -S --noconfirm proton-vpn-gtk-app zsh starship flatpak --needed base-devel git curl unzip

# -------------------------------
#  Install paru (AUR helper)
# -------------------------------
if ! command -v paru &> /dev/null; then
    echo "[*] Installing paru..."
    PARU_DIR="/tmp/paru"
    if git clone https://aur.archlinux.org/paru.git "$PARU_DIR"; then
        if pushd "$PARU_DIR" && makepkg -si --noconfirm; then
            popd
            rm -rf "$PARU_DIR"
            echo "[*] paru installed successfully."
        else
            echo "[!] Failed to build paru. Cleaning up..."
            popd 2>/dev/null || true
            rm -rf "$PARU_DIR"
            exit 1
        fi
    else
        echo "[!] Failed to clone paru repository."
        exit 1
    fi
else
    echo "[*] paru already installed."
fi

# -------------------------------
#  Install AUR packages
# -------------------------------
echo "[*] Installing Visual Studio Code (AUR)..."
paru -S --noconfirm visual-studio-code-bin

# -------------------------------
#  Setup Flatpak + apps
# -------------------------------
echo "[*] Setting up Flatpak..."
if ! flatpak remote-list | grep -q flathub; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

echo "[*] Installing Flatpak apps..."
flatpak install -y flathub io.github.zen_browser.zen
flatpak install -y flathub com.mattjakeman.ExtensionManager

# -------------------------------
#  Setup Oh My Zsh + plugins
# -------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[*] Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "[*] Oh My Zsh already installed."
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
mkdir -p "$ZSH_CUSTOM/plugins"

echo "[*] Installing Zsh plugins..."
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

[ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ] && \
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ] && \
    git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"

# -------------------------------
#  Fonts (Nerd Fonts AdwaitaMono)
# -------------------------------
echo "[*] Installing Nerd Font (AdwaitaMono)..."
mkdir -p ~/.fonts
cd ~/.fonts
if [ ! -d "AdwaitaMono" ]; then
    curl -L -o AdwaitaMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AdwaitaMono.zip
    unzip -o AdwaitaMono.zip -d AdwaitaMono
    rm AdwaitaMono.zip
    fc-cache -fv
else
    echo "[*] Nerd Font already installed."
fi
cd ~

# -------------------------------
#  Apply Starship theme
# -------------------------------
echo "[*] Applying Starship theme..."
mkdir -p ~/.config
starship preset gruvbox-rainbow -o ~/.config/starship.toml

# -------------------------------
#  Configure Zsh
# -------------------------------
echo "[*] Configuring .zshrc..."

ZSHRC=~/.zshrc
if [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "${ZSHRC}.backup.$(date +%s)"
fi

# Check if .zshrc already contains our oh-my-zsh setup
if ! grep -q "export ZSH=\"\$HOME/.oh-my-zsh\"" "$ZSHRC" 2>/dev/null; then
    # Create new .zshrc with oh-my-zsh setup
    cat > "$ZSHRC" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    fast-syntax-highlighting
    zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh

# Starship prompt
eval "$(starship init zsh)"
EOF
    echo "[*] Created new .zshrc with oh-my-zsh configuration."
else
    echo "[*] .zshrc already contains oh-my-zsh configuration."
fi

# -------------------------------
#  Change default shell to zsh
# -------------------------------
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "[*] Changing default shell to zsh..."
    chsh -s "$(which zsh)"
fi

# -------------------------------
#  Install Node.js and nvm
# -------------------------------
echo "[*] Installing nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    # Load nvm immediately
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    echo "[*] nvm installed successfully."
else
    echo "[*] nvm already installed."
    # Load nvm if not already loaded
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

echo "[*] Installing Node.js 22..."
nvm install 22
nvm use 22
nvm alias default 22

echo "[*] Node.js $(node --version) installed successfully."

echo "[✓] Setup complete! Restart your terminal or log out/in to start using Zsh with Starship."
