#!/bin/bash
set -ueo pipefail

# --- Colors & Logging ---
INFO="\033[0;33m"
SUCCESS="\033[0;32m"
RESET="\033[0m"
info()    { echo -e "${INFO}$*${RESET}"; }
success() { echo -e "${SUCCESS}$*${RESET}"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 1. Install Homebrew ---
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- 2. Install packages ---
info "Updating Homebrew..."
brew update

# Trust lazygit
brew trust jesseduffield/lazygit

info "Installing packages from Brewfile..."
brew bundle --upgrade

# Fix for macos plugin flagging spotify and music as missing
touch ~/.local/share/zinit/snippets/OMZP::macos/music
touch ~/.local/share/zinit/snippets/OMZP::macos/spotify

info "Created a cron entry to update brew packages on boot"
echo "@reboot /opt/homebrew/bin/brew update" | crontab -

# Install theme for starship
starship preset nerd-font-symbols -o "$HOME/.config/starship.toml"

# --- 3. Symlink dotfiles ---
info "Symlinking dotfiles..."
for file in .zshrc .zprofile .gitconfig .gitignore; do
  ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
done
ln -sf "$DOTFILES_DIR/.config" "$HOME/.config"

# --- 4. Set default shell to Zsh ---
TARGET_SHELL="$(which zsh)"
if [[ "$SHELL" != "$TARGET_SHELL" ]]; then
  info "Setting default shell to Zsh..."
  if ! grep -qF "$TARGET_SHELL" /etc/shells; then
    echo "$TARGET_SHELL" | sudo tee -a /etc/shells
  fi
  chsh -s "$TARGET_SHELL"
fi

# --- 5. iTerm2 shell integration ---
info "Installing iTerm2 shell integration..."
curl -fsSL https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh

# --- 6. Delta themes ---
info "Downloading delta themes..."
mkdir -p "$HOME/.config/delta"
curl -fsSL https://raw.githubusercontent.com/dandavison/delta/main/themes.gitconfig \
  -o "$HOME/.config/delta/themes.gitconfig"

# --- 7. macOS defaults ---
info "Applying macOS system preferences..."

# iTerm2
defaults write com.googlecode.iterm2 HotkeyTermAnimationDuration -float 0.00001
# Terminal
defaults write com.apple.terminal StringEncodings -array 4
# Dock
defaults write com.apple.Dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4
defaults write com.apple.dock autohide -bool true
# Typing
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# Keyboard
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 1
# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
killall Dock

# --- Done ---
success ""
success "!!! Setup complete — a few things still need your attention: !!!"
success ""
success "1. GPG key: generate or import your key and set the fingerprint in .gitconfig"
success "   - Generate:  gpg --full-generate-key"
success "   - List keys: gpg --list-secret-keys --keyid-format=long"
success "   - Then set:  git config --global user.signingkey <KEY_ID>"
success ""
success "2. Git email:  git config --global user.email 'you@example.com'"
success ""
success "3. iTerm2 color scheme: Preferences → Profiles → Colors → import Ayu"
success "4. iTerm2 font:         Preferences → Profiles → Text → set a Nerd Font"
