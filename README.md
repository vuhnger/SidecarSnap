# SidecarSnap

When you use an iPad as a Sidecar display, macOS doesn't know which side of the Mac it is on. SidecarSnap figures it out from your cursor. Push the mouse against the edge of the Mac screen where the iPad sits, and after about a second the iPad display moves to that side.

macOS also drops Sidecar when the Mac sleeps and doesn't reconnect it. If the iPad was connected when the Mac went to sleep, SidecarSnap reconnects it after wake.

It is a [Hammerspoon](https://www.hammerspoon.org/) Spoon and starts at login.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/vuhnger/SidecarSnap/main/install.sh | bash
```

The script installs Hammerspoon with Homebrew if it is missing, copies the Spoon to `~/.hammerspoon/Spoons`, builds the reconnect helper, adds two lines to `~/.hammerspoon/init.lua`, and turns on launch at login. Building the helper needs the Xcode Command Line Tools (`xcode-select --install`). Without them, everything works except reconnecting after sleep.

macOS then asks you to give Hammerspoon Accessibility access in System Settings > Privacy & Security > Accessibility. Without it, Hammerspoon can't see the cursor. If the iPad still doesn't move after you allow it, quit and reopen Hammerspoon.

## Use

1. Connect the iPad with Sidecar (Control Center > Screen Mirroring > Extend to).
2. Push the cursor against the Mac screen edge on the side where the iPad is.

The iPad display moves to that side, with its bottom edge aligned to the Mac screen's.

## Settings

Set these before `:start()` in `~/.hammerspoon/init.lua`:

```lua
local snap = hs.loadSpoon("SidecarSnap")
snap.pushThreshold = 15
snap.namePatterns = { "Sidecar", "iPad" }
snap.reconnectOnWake = true
snap.deviceName = "Joe's iPad"
snap:start()
```

`pushThreshold` is how many mouse-move events against the edge it takes to move the display. Lower it to make SidecarSnap react faster. `namePatterns` are Lua patterns matched against display names.

`deviceName` picks which iPad to reconnect after wake. Leave it out if you have only one. To see the names the Mac can reach, run `~/.hammerspoon/Spoons/SidecarSnap.spoon/bin/sidecar-connect "?"`.

## How reconnecting works

`sidecar-connect.swift` is a small helper that calls `SidecarDisplayManager` in Apple's private SidecarCore framework, the same approach as [SidecarLauncher](https://github.com/Ocasio-J/SidecarLauncher). Because the API is private, a macOS update can break it. If that happens, the snapping keeps working, and you reconnect from Control Center by hand.

## Uninstall

Delete `~/.hammerspoon/Spoons/SidecarSnap.spoon`, remove the two SidecarSnap lines from `~/.hammerspoon/init.lua`, and reload Hammerspoon.

## Develop

```sh
lua tests/logic_test.lua
luacheck --globals hs -- SidecarSnap.spoon tests
shellcheck install.sh
xcrun swiftc -O SidecarSnap.spoon/sidecar-connect.swift -o /tmp/sidecar-connect
```
