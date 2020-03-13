#!/bin/bash

# Measure start time
START_TIME=$SECONDS

prgreen() {
    echo -e "\033[0;32m$1\033[0m"
}

prred() {
    echo -e "\033[0;31m$1\033[0m"
}

rm -rf ~/.FirefoxBoxes/
rm -rf ~/Library/LaunchAgents/io.github.firefox-boxes.boxes-ipc.plist
rm -rf ~/Library/Application\ Support/Mozilla/NativeMessagingHosts/boxes-ext-native-shell.json
rm -rf "/Applications/Firefox (Boxes).app"

# Measure elapsed time and print it
ELAPSED_TIME=$(($SECONDS - $START_TIME))
prgreen "Done! ("$ELAPSED_TIME"s)"
