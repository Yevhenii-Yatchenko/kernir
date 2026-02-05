#!/bin/bash
set -e

APPIMAGE_PATH="/opt/qgroundcontrol/QGroundControl.AppImage"
DOWNLOAD_URL="https://github.com/mavlink/qgroundcontrol/releases/latest/download/QGroundControl-x86_64.AppImage"

# Download if missing
if [ ! -f "$APPIMAGE_PATH" ]; then
    echo "QGroundControl.AppImage not found, downloading..."
    curl -fSL -o "$APPIMAGE_PATH" "$DOWNLOAD_URL"
    chmod +x "$APPIMAGE_PATH"
    echo "Download complete."
fi

exec "$APPIMAGE_PATH" --appimage-extract-and-run "$@"
