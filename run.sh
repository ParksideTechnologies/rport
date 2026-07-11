#!/bin/sh
set -e

OPTIONS_FILE="/data/options.json"
UUID_FILE="/data/rport_uuid"
CONF_FILE="/etc/rport/rport.conf"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  BIN="/rport-amd64" ;;
  aarch64) BIN="/rport-arm64" ;;
  *)
    echo "[ERROR] Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "[INFO] Detected architecture: $ARCH"
echo "[INFO] Using binary: $BIN"

# Read values from HA UI
USERNAME=$(jq -r '.Username' "$OPTIONS_FILE")
PASSWORD=$(jq -r '.Password' "$OPTIONS_FILE")
NAME=$(jq -r '."Client Name"' "$OPTIONS_FILE")
CONFIG_UUID=$(jq -r '.UUID' "$OPTIONS_FILE")

# Check for unset or placeholder credentials
if [ -z "$USERNAME" ] || [ "$USERNAME" = "null" ] || [ "$USERNAME" = "your username" ]; then
    echo "[ERROR] Valid username and/or password missing. Please enter in add-on configuration page."
    exit 1
fi

if [ -z "$PASSWORD" ] || [ "$PASSWORD" = "null" ] || [ "$PASSWORD" = "your password" ]; then
    echo "[ERROR] Valid username and/or password missing. Please enter in add-on configuration page."
    exit 1
fi

# UUID handling
if [ "$CONFIG_UUID" = "null" ] || [ "$CONFIG_UUID" = "insert unique ID or leave blank to auto generate" ]; then
    CONFIG_UUID=""
fi

if [ -n "$CONFIG_UUID" ]; then
    UUID="$CONFIG_UUID"
    echo "$UUID" > "$UUID_FILE"
    echo "Using UUID from UI: $UUID"
elif [ -f "$UUID_FILE" ] && [ -s "$UUID_FILE" ]; then
    UUID=$(cat "$UUID_FILE")
    echo "Reusing stored UUID: $UUID"
else
    UUID=$(uuidgen)
    echo "$UUID" > "$UUID_FILE"
    echo "Generated new UUID: $UUID"
fi

# Write config
mkdir -p /etc/rport
cat <<EOF > "$CONF_FILE"
[client]
server = "http://rport.au:8051"
fingerprint = "48:ab:46:7f:83:76:5c:c6:65:59:4e:df:79:33:6e:24"
auth = "${USERNAME}:${PASSWORD}"
id = "${UUID}"
name = "${NAME}"
allow_root = true
updates_interval = '0'
EOF

echo "Generated /etc/rport/rport.conf:"
cat "$CONF_FILE" | sed 's/^auth = .*/auth = [REDACTED]/'

chmod +x "$BIN"
exec "$BIN" -c "$CONF_FILE"
