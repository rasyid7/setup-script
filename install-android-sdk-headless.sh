#!/usr/bin/env bash
set -euo pipefail

# ===== Settings =====
SDK_ROOT="${SDK_ROOT:-$HOME/Android/sdk}"
JAVA_PKG="${JAVA_PKG:-openjdk-17-jdk-headless}"

CMDLINE_TOOLS_ZIP="${CMDLINE_TOOLS_ZIP:-commandlinetools-linux-11076708_latest.zip}"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}"

PLATFORMS="${PLATFORMS:-platforms;android-34}"
BUILD_TOOLS="${BUILD_TOOLS:-build-tools;34.0.0}"
SYSTEM_IMAGE="${SYSTEM_IMAGE:-system-images;android-34;google_apis;x86_64}"
AVD_NAME="${AVD_NAME:-pixel_6_api34}"
DEVICE_NAME="${DEVICE_NAME:-pixel_6}"

echo ">>> Installing prerequisites"
sudo apt update -y
sudo apt install -y unzip curl ${JAVA_PKG} \
  libc6 libstdc++6 lib32z1 libbz2-1.0 libglu1-mesa \
  libxi6 libxrender1 libxrandr2 libxcursor1 libxfixes3 \
  libdbus-1-3 libpulse0 libnss3 libxcomposite1 libxshmfence1 \
  mesa-vulkan-drivers

echo ">>> Creating SDK root: $SDK_ROOT"
mkdir -p "$SDK_ROOT/cmdline-tools"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"
echo ">>> Downloading command line tools"
curl -fL --retry 3 -o cmdtools.zip "$CMDLINE_TOOLS_URL"
unzip -q cmdtools.zip

mkdir -p "$SDK_ROOT/cmdline-tools/latest"
mv cmdline-tools/* "$SDK_ROOT/cmdline-tools/latest" || true

echo ">>> Adding environment variables to ~/.bashrc"
if ! grep -q "ANDROID_SDK_ROOT" "$HOME/.bashrc" ; then
cat >> "$HOME/.bashrc" <<EOF

# Android SDK
export ANDROID_SDK_ROOT="$SDK_ROOT"
export ANDROID_HOME="$SDK_ROOT"
export PATH="\$PATH:$SDK_ROOT/platform-tools:$SDK_ROOT/emulator:$SDK_ROOT/cmdline-tools/latest/bin"
EOF
fi

# Apply environment now
export ANDROID_SDK_ROOT="$SDK_ROOT"
export ANDROID_HOME="$SDK_ROOT"
export PATH="$PATH:$SDK_ROOT/platform-tools:$SDK_ROOT/emulator:$SDK_ROOT/cmdline-tools/latest/bin"

echo ">>> Accepting licenses and installing packages"
yes | sdkmanager --licenses >/dev/null
sdkmanager --install "platform-tools" "emulator" "$PLATFORMS" "$BUILD_TOOLS" "$SYSTEM_IMAGE"

echo ">>> Creating AVD: $AVD_NAME"
yes | avdmanager create avd -n "$AVD_NAME" -k "$SYSTEM_IMAGE" --device "$DEVICE_NAME" || true

echo
echo "✅ Installation complete"
echo
echo "Reload your shell:"
echo "  source ~/.bashrc"
echo
echo "Start emulator headless:"
echo "  emulator -avd $AVD_NAME -no-window -gpu swiftshader_indirect -no-snapshot -noaudio"
echo
