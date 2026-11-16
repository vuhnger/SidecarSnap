#!/usr/bin/env bash
set -euo pipefail

repo="vuhnger/SidecarSnap"
config="$HOME/.hammerspoon"

if [ ! -d /Applications/Hammerspoon.app ]; then
  if ! command -v brew >/dev/null; then
    echo "Install Homebrew first: https://brew.sh" >&2
    exit 1
  fi
  brew install --cask --no-binaries hammerspoon
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://github.com/$repo/archive/refs/heads/main.tar.gz" | tar -xz -C "$tmp"

mkdir -p "$config/Spoons"
rm -rf "$config/Spoons/SidecarSnap.spoon"
cp -R "$tmp/SidecarSnap-main/SidecarSnap.spoon" "$config/Spoons/"

spoon="$config/Spoons/SidecarSnap.spoon"
if xcrun --find swiftc >/dev/null 2>&1; then
  mkdir -p "$spoon/bin"
  xcrun swiftc -O "$spoon/sidecar-connect.swift" -o "$spoon/bin/sidecar-connect"
else
  echo "Xcode Command Line Tools are missing, so reconnecting after sleep is off." >&2
  echo "Run xcode-select --install, then run this script again." >&2
fi

touch "$config/init.lua"
if ! grep -q 'loadSpoon("SidecarSnap")' "$config/init.lua"; then
  printf '\nhs.loadSpoon("SidecarSnap"):start()\nhs.autoLaunch(true)\n' >> "$config/init.lua"
fi

pkill -x Hammerspoon || true
for _ in $(seq 50); do
  pgrep -x Hammerspoon >/dev/null || break
  sleep 0.2
done
open -a Hammerspoon

echo "SidecarSnap installed. Give Hammerspoon Accessibility access when macOS asks."
