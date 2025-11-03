#!/usr/bin/env bash
# VNC_USER=rasyid VNC_PASSWORD='wasd123' VNC_GEOMETRY=1280x720 VNC_DISPLAY=:1 VNC_LOCALHOST=no sudo bash vnc.sh

set -euo pipefail

# === Config (override with environment variables) ===
VNC_USER="${VNC_USER:-${SUDO_USER:-${USER}}}"   # target login user to own/run VNC
VNC_DISPLAY="${VNC_DISPLAY:-:1}"                # e.g. :1 -> port 5901
VNC_GEOMETRY="${VNC_GEOMETRY:-1920x1080}"
VNC_LOCALHOST="${VNC_LOCALHOST:-no}"            # yes = bind 127.0.0.1 only; no = listen on all
VNC_DESKTOP="${VNC_DESKTOP:-xfce}"              # currently supports 'xfce'
# If VNC_PASSWORD not set, script will prompt interactively.

# === Sanity checks ===
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo bash $0"
  exit 1
fi

id "$VNC_USER" &>/dev/null || { echo "User '$VNC_USER' does not exist."; exit 1; }
USER_HOME="$(getent passwd "$VNC_USER" | cut -d: -f6)"
[[ -d "$USER_HOME" ]] || { echo "Home dir for '$VNC_USER' not found: $USER_HOME"; exit 1; }

# === Install packages ===
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
  tigervnc-standalone-server tigervnc-common \
  dbus-x11 xterm

if [[ "$VNC_DESKTOP" == "xfce" ]]; then
  apt-get install -y xfce4 xfce4-goodies
else
  echo "Unsupported desktop '$VNC_DESKTOP'. Only 'xfce' is implemented."
  exit 1
fi

# === Create VNC password ===
# If $VNC_PASSWORD is provided, set non-interactively; otherwise prompt.
sudo -u "$VNC_USER" mkdir -p "$USER_HOME/.vnc"
if [[ -n "${VNC_PASSWORD:-}" ]]; then
  echo "Setting VNC password for $VNC_USER (non-interactive)..."
  # Use vncpasswd -f to create hashed password to stdout; write to ~/.vnc/passwd
  su - "$VNC_USER" -c "umask 077; printf '%s\n' \"$VNC_PASSWORD\" | vncpasswd -f > ~/.vnc/passwd"
else
  echo "No VNC_PASSWORD provided. You'll be prompted to set a VNC password for $VNC_USER..."
  su - "$VNC_USER" -c "umask 077; vncpasswd"
fi
chmod 600 "$USER_HOME/.vnc/passwd"
chown -R "$VNC_USER:$VNC_USER" "$USER_HOME/.vnc"

# === xstartup (launch desktop session) ===
XSTARTUP_PATH="$USER_HOME/.vnc/xstartup"
if [[ "$VNC_DESKTOP" == "xfce" ]]; then
  cat > "$XSTARTUP_PATH" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
# Start XFCE
if command -v startxfce4 >/dev/null 2>&1; then
  exec startxfce4
fi
# Fallbacks
[ -x /etc/X11/xinit/xinitrc ] && exec /etc/X11/xinit/xinitrc
[ -x /usr/bin/xterm ] && exec xterm
EOF
fi
chmod +x "$XSTARTUP_PATH"
chown "$VNC_USER:$VNC_USER" "$XSTARTUP_PATH"

# === systemd service (template) ===
# We'll use the instance name as the *username* and pin the display in ExecStart.
# Example: systemctl enable --now vncserver@alice.service  -> runs as user 'alice' on :1 by default.
SERVICE_PATH="/etc/systemd/system/vncserver@.service"
cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=TigerVNC server for %i
After=network.target

[Service]
Type=forking
User=%i
PAMName=login
PIDFile=%h/.vnc/%H$(echo "$VNC_DISPLAY" | sed 's/:/./').pid
# Ensure password exists before starting
ExecStartPre=/bin/sh -c '/usr/bin/test -f %h/.vnc/passwd || (echo "VNC password not set for %i"; exit 1)'
# Start with desired geometry and binding
ExecStart=/usr/bin/vncserver ${VNC_DISPLAY} -geometry ${VNC_GEOMETRY} -localhost ${VNC_LOCALHOST} -SecurityTypes VncAuth
ExecStop=/usr/bin/vncserver -kill ${VNC_DISPLAY}

# Hardening (optional but good practice)
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=no

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "vncserver@${VNC_USER}.service"
systemctl restart "vncserver@${VNC_USER}.service"

# === Firewall (UFW) ===
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -q "Status: active"; then
    # Map :N -> port 590N
    DISPLAY_NUM="$(echo "$VNC_DISPLAY" | sed 's/^://')"
    PORT=$((5900 + DISPLAY_NUM))
    echo "UFW is active; allowing TCP ${PORT}"
    ufw allow "${PORT}/tcp" || true
  fi
fi

# === Output summary ===
DISPLAY_NUM="$(echo "$VNC_DISPLAY" | sed 's/^://')"
PORT=$((5900 + DISPLAY_NUM))
cat <<SUMMARY

✅ TigerVNC is installed and running.

User      : $VNC_USER
Display   : $VNC_DISPLAY
Resolution: $VNC_GEOMETRY
Bind mode : ${VNC_LOCALHOST}  (yes=127.0.0.1 only; no=all interfaces)
Service   : vncserver@${VNC_USER}.service
Port      : ${PORT} (5900 + display number)

Connect using a VNC viewer to:
  - If LOCALHOST=no : <server-ip>:${PORT}
  - If LOCALHOST=yes: via SSH tunnel, e.g.
      ssh -L 5901:127.0.0.1:5901 ${VNC_USER}@<server-ip>
      # then connect VNC viewer to 127.0.0.1:5901

To change resolution:
  sudo systemctl stop vncserver@${VNC_USER}
  sudo VNC_GEOMETRY=2560x1440 bash $0   # or edit the service and rerun
  sudo systemctl start vncserver@${VNC_USER}

Logs:
  journalctl -u vncserver@${VNC_USER} -e

SUMMARY
