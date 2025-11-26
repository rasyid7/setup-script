#!/usr/bin/env bash
set -euo pipefail

# ===== Settings =====
# Allow overriding SDK_ROOT via environment variable
SDK_ROOT="${SDK_ROOT:-$HOME/Android/sdk}"
JAVA_PKG="${JAVA_PKG:-openjdk-17-jdk-headless}"

# Check for updates here: https://developer.android.com/studio#command-tools
CMDLINE_TOOLS_VER="11076708"
CMDLINE_TOOLS_ZIP="commandlinetools-linux-${CMDLINE_TOOLS_VER}_latest.zip"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}"

echo ">>> 📦 Settings:"
echo "    SDK Location: $SDK_ROOT"
echo "    Java Package: $JAVA_PKG"
echo "    Tools Ver:    $CMDLINE_TOOLS_VER"

echo ">>> 🛠️  Installing prerequisites..."
# -qq suppresses output, useful for scripts
sudo apt update -qq
sudo apt install -y -qq unzip curl ${JAVA_PKG} \
  libc6 libstdc++6 lib32z1 libbz2-1.0 libglu1-mesa \
  libxi6 libxrender1 libxrandr2 libxcursor1 libxfixes3 \
  libdbus-1-3 libpulse0 libnss3 libxcomposite1 libxshmfence1 \
  mesa-vulkan-drivers

echo ">>> 📂 Creating SDK root..."
mkdir -p "$SDK_ROOT/cmdline-tools"

# Create temp directory
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo ">>> ⬇️  Downloading command line tools..."
cd "$tmpdir"
curl -fL --progress-bar --retry 3 -o cmdtools.zip "$CMDLINE_TOOLS_URL"
unzip -q cmdtools.zip

# The zip extracts to a folder named 'cmdline-tools'. 
# We need to move it to $SDK_ROOT/cmdline-tools/latest
echo ">>> 🚚 Moving files to correct location..."
rm -rf "$SDK_ROOT/cmdline-tools/latest"
mv cmdline-tools "$SDK_ROOT/cmdline-tools/latest"

# Setup environment variables for the current session
export ANDROID_HOME="$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"
export PATH="$PATH:$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$SDK_ROOT/emulator"

# Configuration for .bashrc
RC_FILE="$HOME/.bashrc"
echo ">>> 📝 configuring $RC_FILE..."

# Helper function to append if not exists
add_to_rc() {
    local text="$1"
    if ! grep -Fq "$text" "$RC_FILE"; then
        echo "$text" >> "$RC_FILE"
    fi
}

add_to_rc "# Android SDK Configuration"
add_to_rc "export ANDROID_HOME=\"$SDK_ROOT\""
add_to_rc "export ANDROID_SDK_ROOT=\"$SDK_ROOT\""
# We use single quotes around $PATH to ensure it evaluates at runtime, not install time
add_to_rc 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"'

echo
echo "✅ Installation complete!"
echo "   SDK installed at: $SDK_ROOT"
echo
echo "🔄 To apply changes immediately, run:"
echo "   source $RC_FILE"
echo
echo "Please run this manually:"
echo "   yes | sdkmanager --sdk_root='$ANDROID_SDK_ROOT' --licenses >/dev/null"
echo "   sdkmanager --sdk_root='$ANDROID_SDK_ROOT' 'platform-tools' 'emulator' 'system-images;android-33;google_apis;x86_64'"
