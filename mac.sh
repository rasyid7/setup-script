# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install iterm2 dan OhMyZsh
brew install --cask iterm2
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

brew install zsh-autosuggestions
# masukkan source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ke ~/.zshrc
brew install zsh-syntax-highlighting
# masukkan source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ke ~/.zshrc

brew install powerlevel10k
echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc

brew install --cask visual-studio-code
# vscode -> CMD + , -> search 'terminal font' -> 'MesloLGS NF' | untuk fix VSCode terminal font

brew install --cask google-chrome
brew install --cask brave-browser

brew install --cask aldente

brew install openjdk@21

brew install --cask rectangle

brew install maccy

brew install stats

brew install zoxide
# eval "$(zoxide init zsh)" -> put on ~/.zshrc

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

# softwareupdate --install-rosetta
# brew install --cask docker-desktop
# brew install --cask logi-options+
# brew install --cask tunnelblick

# brew install --cask gcloud-cli
# gcloud init

# brew install --cask gpg-suite
# colok yubikey
# Yubikey --> masukin ke ~/.zshrc
# alias yubikey="killall ssh-agent; /usr/local/MacGPG2/bin/gpg-agent --daemon; export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh; ssh-add -L"
# alias recallyubikey="killall gpg-agent; killall -9 scdaemon; eval $( /usr/local/MacGPG2/bin/gpg-agent --daemon )"
# export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh

# curl -fsSL https://claude.ai/install.sh | bash
# npm install -g @google/gemini-cli
# curl -LsSf https://code.kimi.com/install.sh | bash

# git config
# [includeIf "gitdir:~/Workspace/"]
#     path = ~/.gitconfig-work
# [user]
# 	name = Rasyid Ridho
# 	email = rasyid.ridho@vidio.com

# [includeIf "gitdir:~/Learning/"]
#     path = ~/.gitconfig-personal
# [user]
# 	name = Rasyid Ridho
# 	email = rasyidridho7@gmail.com

