# LiveContainerAutoDarkIcon

A LiveContainer tweak that makes guest app icons follow the system
appearance automatically: light icons in light mode, dark icons in dark
mode, with no manual switch to flip.

## Why

LiveContainer already has dark icons for guest apps, but the switch
behind them (`darkModeIcon`) is manual and defaults to off — it never
follows the system appearance. This tweak makes it automatic.

## How it works

- It answers `LCAppInfo`'s `iconIsDarkIcon:` from the live system
  appearance, so the displayed icon always matches the current mode.
- It also syncs the `darkModeIcon` flag in the app-group defaults to
  the live appearance after launch and on every icon fetch. That
  matters because banner colors are picked from cached light/dark
  colors by that flag, not from the displayed icon — syncing only the
  icon would leave banner colors on the light set.
- While the tweak is loaded, the manual switch is driven by the tweak
  and has no effect on icons.

## Installation

1. Download `AutoDarkIcon.dylib` from the nightly release.
2. Put it in LiveContainer's global Tweaks folder.
3. Sign it.
4. In LiveContainer Settings, tap the version number 5 times and enable
   **Load Tweaks to LiveContainer Itself**.
5. Restart LiveContainer.

On every update: delete the old dylib, put the new one in, sign it, and
restart LiveContainer.

## Notes

Pure runtime, no CydiaSubstrate, so it loads on jailed devices. The
constructor only installs method swizzles — it never touches UIKit,
Security/keychain, or UserDefaults there; all syncing is deferred to
after launch and wrapped in exception protection, so a bad state cannot
take LiveContainer down at startup.

If LiveContainer crashes on launch with an old build, rename the dylib
to `.disabled` (or delete it) and reopen LiveContainer.

## Building

Pushes to `main` trigger the nightly workflow (Theos), which publishes
the dylib to the nightly release.

## Tested on

LiveContainer 3.8.11, iOS 27.0.1, iPhone17,2.
