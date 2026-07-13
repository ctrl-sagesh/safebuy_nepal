#!/usr/bin/env bash
# SafeBuy Nepal — run on a USB-connected Android device (debug mode).
set -e
echo "SafeBuy Nepal — Running on connected device..."
echo
echo "Checking connected devices..."
flutter devices
echo
echo "Starting app in debug mode..."
flutter run --debug
