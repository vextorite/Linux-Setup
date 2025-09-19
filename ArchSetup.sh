#!/bin/bash
set -e  # exit on error

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
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    pushd /tmp/paru
    makepkg -si --noconfirm
    popd
    rm -rf /tmp/paru
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

# -------------------------------
#  Change default shell to zsh
# -------------------------------
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "[*] Changing default shell to zsh..."
    chsh -s "$(which zsh)"
fi

echo "[✓] Setup complete! Restart your terminal or log out/in to start using Zsh with Starship."
