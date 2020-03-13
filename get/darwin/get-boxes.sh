#!/bin/bash

#### get-boxes.sh
## All in one script for installing Boxes on macOS

# Measure start time
START_TIME=$SECONDS

prgreen() {
    echo -e "\033[0;32m$1\033[0m"
}

prred() {
    echo -e "\033[0;31m$1\033[0m"
}

download() {
    echo "dl: $(basename "$2") --> $(dirname "$2")"
    tmpdir=$(mktemp -d)||{ prred "Failed to create temp file"; exit 1; }
    curl --progress-bar -L $1 -o "$tmpdir/download.tmp"
    expected_md5=$(curl -s -L $1.md5)
    calculated_md5=$(/sbin/md5 -q "$tmpdir/download.tmp")
    case "$calculated_md5" in
        "$expected_md5" )
            mkdir -p "$(dirname "$2")"
            mv "$tmpdir/download.tmp" "$2"
            ;;
        * )
            prred "md5 not ok: file "$1""
            exit 1
            ;;
    esac
    rm -r "$tmpdir"
}

# Make app directories
if [ ! "~/.FirefoxBoxes/" ]; then
    echo "\"~/.FirefoxBoxes/\" doesn't exist, creating..."
    mkdir ~/.FirefoxBoxes/
fi
if [ ! "~/.FirefoxBoxes/bin" ]; then
    echo "\"~/.FirefoxBoxes/bin\" doesn't exist, creating..."
    mkdir ~/.FirefoxBoxes/bin
fi

# Set prefix for all downloads
DL_PREFIX="http://firefox-boxes.github.io/get/darwin"

# Download app binaries
prgreen "==> Download binaries"
download ""$DL_PREFIX"/boxes-ext-native-shell" ~/.FirefoxBoxes/bin/boxes-ext-native-shell
download ""$DL_PREFIX"/boxes-ipc" ~/.FirefoxBoxes/bin/boxes-ipc
chmod +x ~/.FirefoxBoxes/bin/boxes-ext-native-shell
chmod +x ~/.FirefoxBoxes/bin/boxes-ipc
download "http://firefox-boxes.github.io/get/boxes-ext-latest.xpi" ~/.FirefoxBoxes/boxes-ext-latest.xpi

# Download startup agent plist file and add it to LaunchAgents
prgreen "==> Set boxes-ipc to run on startup"
download ""$DL_PREFIX"/StartupAgent.plist" ~/Library/LaunchAgents/io.github.firefox-boxes.boxes-ipc.plist
STARTUP_AGENT="$(cat ~/Library/LaunchAgents/io.github.firefox-boxes.boxes-ipc.plist)"
echo "${STARTUP_AGENT//"~"/$HOME}" > ~/Library/LaunchAgents/io.github.firefox-boxes.boxes-ipc.plist
launchctl unload ~/Library/LaunchAgents/io.github.firefox-boxes.boxes-ipc.plist
launchctl load ~/Library/LaunchAgents/io.github.firefox-boxes.boxes-ipc.plist

# Add boxes-ext-native-shell as a native messaging target for Firefox
prgreen "==> Add boxes as a native messaging target"
mkdir -p ~/Library/Application\ Support/Mozilla/NativeMessagingHosts/
echo "{\"name\": \"boxes_ext_native_shell\",\
  \"description\": \"Boxes backend shell\",\
  \"path\": \""$HOME/.FirefoxBoxes/bin/boxes-ext-native-shell"\",\
  \"type\": \"stdio\",\
  \"allowed_extensions\": [ \"boxes@whatsyouridea.com\" ]\
}" > ~/Library/Application\ Support/Mozilla/NativeMessagingHosts/boxes_ext_native_shell.json

# Initial setup of boxes
prgreen "==> Do initial setup for Boxes"
download ""$DL_PREFIX"/binary-setup" ~/.FirefoxBoxes/bin/binary-setup
chmod +x ~/.FirefoxBoxes/bin/binary-setup
~/.FirefoxBoxes/bin/binary-setup
rm ~/.FirefoxBoxes/bin/binary-setup

# Add application to launch the default box (shortcut)
prgreen "==> Install"
mkdir -p "/Applications/Firefox (Boxes).app/Contents"
download ""$DL_PREFIX"/Info.plist" "/Applications/Firefox (Boxes).app/Contents/Info.plist"
mkdir -p "/Applications/Firefox (Boxes).app/Contents/Resources"
download ""$DL_PREFIX"/icon.icns" "/Applications/Firefox (Boxes).app/Contents/Resources/icon.icns"
mkdir -p "/Applications/Firefox (Boxes).app/Contents/MacOS"
download ""$DL_PREFIX"/boxes" "/Applications/Firefox (Boxes).app/Contents/MacOS/boxes"
chmod +x "/Applications/Firefox (Boxes).app/Contents/MacOS/boxes"

# Get uninstall script
prgreen "==> Obtaining uninstall script"
download ""$DL_PREFIX"/uninstall.sh" ~/.FirefoxBoxes/uninstall.sh
chmod +x ~/.FirefoxBoxes/uninstall.sh

# Measure elapsed time and print it
ELAPSED_TIME=$(($SECONDS - $START_TIME))
prgreen "Done! ("$ELAPSED_TIME"s)"
