#!/usr/bin/env bash
# Setup zsh + dev tools di Ubuntu (konversi dari setup macOS/Homebrew)
set -eo pipefail

# 1. Paket dasar + zsh + plugin (tersedia di apt, pengganti brew)
sudo apt update
sudo apt install -y zsh git curl ca-certificates \
  zsh-autosuggestions zsh-syntax-highlighting

# zoxide via installer resmi (terpasang di ~/.local/bin)
if ! command -v zoxide >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/zoxide" ]; then
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# 2. Oh My Zsh (unattended: tidak langsung masuk zsh / ganti shell di tengah script)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 3. Powerlevel10k (tidak ada di apt -> clone dari GitHub)
if [ ! -d "$HOME/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
fi
# Matikan tema bawaan oh-my-zsh agar tidak bentrok dengan p10k
sed -i 's/^ZSH_THEME=.*/ZSH_THEME=""/' "$HOME/.zshrc"

# 4. Tambahkan ke ~/.zshrc (tidak duplikat kalau script dijalankan ulang)
add_line() { grep -qxF "$1" "$HOME/.zshrc" || echo "$1" >> "$HOME/.zshrc"; }
add_line 'source ~/powerlevel10k/powerlevel10k.zsh-theme'
add_line 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
add_line 'export PATH="$HOME/.local/bin:$PATH"'
add_line 'eval "$(zoxide init zsh)"'
# syntax-highlighting sebaiknya di-source paling akhir
add_line 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'

# 5. OpenJDK 21
sudo apt install -y openjdk-21-jdk

# 6. nvm + Node 24 (PROFILE memastikan nvm menulis ke ~/.zshrc, bukan ~/.bashrc)
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | PROFILE="$HOME/.zshrc" bash
fi
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install 24
nvm alias default 24

# 7. Yarn via npm — JANGAN `apt install yarn`
npm install -g yarn

# 8. Jadikan zsh sebagai default shell
if [ "$SHELL" != "$(command -v zsh)" ]; then
  chsh -s "$(command -v zsh)"
fi

echo
echo "Selesai. Logout/login lagi, lalu jalankan: p10k configure"
