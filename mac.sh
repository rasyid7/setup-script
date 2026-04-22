# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install --cask iterm2

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

brew install zsh-autosuggestions
# masukkan source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ke ~/.zshrc
brew install zsh-syntax-highlighting
# masukkan source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ke ~/.zshrc
brew install --cask visual-studio-code

brew install powerlevel10k
echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc

brew install --cask google-chrome

brew install --cask rectangle

brew install maccy

brew install stats

brew install --cask aldente

brew install openjdk@21

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
nvm install 22

curl -LsSf https://astral.sh/uv/install.sh | sh
uv install python


# set tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# set 3-finger drag
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# Set dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 53
killall Dock

# brew install --cask logi-options+
