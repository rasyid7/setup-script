#!/usr/bin/env bash
# VNC_USER=rasyid VNC_PASSWORD='wasd123' VNC_GEOMETRY=1280x720 VNC_DISPLAY=:1 VNC_LOCALHOST=no sudo bash vnc.sh

set -euo pipefail

# =========================
# Config (env overrides)
# =========================
VNC_USER="${VNC_USER:-${SUDO_USER:-${USER}}}"   # user who will own/run VNC
VNC_DISPLAY="${VNC_DISPLAY:-:1}"                # :1 => TCP 5901
VNC_GEOMETRY="${VNC_GEOMETRY:-1920x1080}"
VNC_LOCALHOST="${VNC_LOCALHOST:-yes}"           # yes=bind 127.0.0.1 only (safer on cloud); no=all interfaces
VNC_DESKTOP="${VNC_DESKTOP:-xfce}"              # xfce implemented
# Optional: VNC_PASSWORD (if unset you’ll be prompted)

# =========================
# Preflight
# =========================
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo bash $0"; exit 1
fi
id "$VNC_USER" &>/dev/null || { echo "User '$VNC_USER' does not exist."; exit 1; }
USER_HOME="$(getent passwd "$VNC_USER" | cut -d: -f6)"
[[ -d "$USER_HOME" ]] || { echo "Home dir for '$VNC_USER' not found: $USER_HOME"; exit 1; }

# Cloud/VMs sometimes lack locales
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y locales || true
locale-gen en_US.UTF-8 || true
update-locale LANG=en_US.UTF-8 || true
export LANG=en_US.UTF-8

# =========================
# Install GUI + VNC
# =========================
apt-get install -y \
  tigervnc-standalone-server tigervnc-common tigervnc-tools \
  dbus-x11 xterm

if [[ "$VNC_DESKTOP" == "xfce" ]]; then
  apt-get install -y xfce4 xfce4-goodies
else
  echo "Unsupported desktop '$VNC_DESKTOP'. Only 'xfce' is implemented."
  exit 1
fi

# Ensure PATH covers minimal service users (jenkins, etc.)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# =========================
# VNC password
# =========================
sudo -u "$VNC_USER" mkdir -p "$USER_HOME/.vnc"
if [[ -n "${VNC_PASSWORD:-}" ]]; then
  echo "Setting VNC password for $VNC_USER (non-interactive)..."
  su - "$VNC_USER" -c "umask 077; printf '%s\n' \"$VNC_PASSWORD\" | vncpasswd -f > ~/.vnc/passwd"
else
  echo "No VNC_PASSWORD provided. You will be prompted (as $VNC_USER)..."
  su - "$VNC_USER" -c "umask 077; vncpasswd"
fi
chmod 600 "$USER_HOME/.vnc/passwd"
chown -R "$VNC_USER:$VNC_USER" "$USER_HOME/.vnc"

# =========================
# xstartup
# =========================
XSTARTUP_PATH="$USER_HOME/.vnc/xstartup"
cat > "$XSTARTUP_PATH" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
# Start XFCE if available
if command -v startxfce4 >/dev/null 2>&1; then
  exec startxfce4
fi
[ -x /etc/X11/xinit/xinitrc ] && exec /etc/X11/xinit/xinitrc
[ -x /usr/bin/xterm ] && exec xterm
EOF
chmod +x "$XSTARTUP_PATH"
chown "$VNC_USER:$VNC_USER" "$XSTARTUP_PATH"

# =========================
# systemd service
# =========================
SERVICE_PATH="/etc/systemd/system/vncserver@.service"
# TigerVNC creates PID as ~/.vnc/<hostname>:<display>.pid
# Use %H:%i.pid where %i (instance) = username (we pass display via ExecStart)
cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=TigerVNC server for %i
After=network.target

[Service]
Type=forking
User=%i
PAMName=login
Environment=LANG=en_US.UTF-8
PIDFile=%h/.vnc/%H:${VNC_DISPLAY#:}.pid
ExecStartPre=/bin/sh -c '/usr/bin/test -f %h/.vnc/passwd || (echo "VNC password not set for %i"; exit 1)'
ExecStart=/usr/bin/vncserver ${VNC_DISPLAY} -geometry ${VNC_GEOMETRY} -localhost ${VNC_LOCALHOST} -SecurityTypes VncAuth
ExecStop=/usr/bin/vncserver -kill ${VNC_DISPLAY}

# Hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=no

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "vncserver@${VNC_USER}.service"
# If a stale lock exists from previous runs, clean it
su - "$VNC_USER" -c "vncserver -kill ${VNC_DISPLAY} >/dev/null 2>&1 || true"
systemctl restart "vncserver@${VNC_USER}.service"

# =========================
# Firewall notes (UFW + GCE)
# =========================
# UFW: open local port if UFW is active
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -q "Status: active"; then
    DISPLAY_NUM="${VNC_DISPLAY#:}"
    PORT=$((5900 + DISPLAY_NUM))
    echo "UFW active; allowing TCP ${PORT}"
    ufw allow "${PORT}/tcp" || true
  fi
fi

# Summary
DISPLAY_NUM="${VNC_DISPLAY#:}"
PORT=$((5900 + DISPLAY_NUM))
PUB_IP="$(curl -s --max-time 2 http://checkip.amazonaws.com || true)"
cat <<SUMMARY

✅ TigerVNC + XFCE set up and running on systemd.

User       : $VNC_USER
Display    : $VNC_DISPLAY
Resolution : $VNC_GEOMETRY
Bind mode  : ${VNC_LOCALHOST}  (yes=127.0.0.1 only; no=all interfaces)
Service    : vncserver@${VNC_USER}.service
Local port : ${PORT} (5900 + display number)

On GCE:
- Safer (default): keep LOCALHOST=yes and tunnel:
    ssh -L ${PORT}:127.0.0.1:${PORT} ${VNC_USER}@<external-ip>
    # Then connect your VNC viewer to 127.0.0.1:${PORT}
- Public access (not recommended): set VNC_LOCALHOST=no and open a VPC firewall rule to allow TCP ${PORT} to your VM.

Check logs:
  journalctl -u vncserver@${VNC_USER} -e

If you change geometry or display, re-run this script or:
  sudo systemctl restart vncserver@${VNC_USER}.service

SUMMARY
