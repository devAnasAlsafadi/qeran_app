# Qeran Android Launcher Icons — Installation

## What's in this package

Complete Android adaptive icon set for Qeran:
- Foreground layers for all densities (adaptive icon)
- Legacy full icons for Android < 26
- Round variants for launchers that request them
- Adaptive icon XML config
- Wine background color (#431C33)

## Installation

Copy the contents into your Flutter project at:
`android/app/src/main/res/`

Files to replace:
- mipmap-mdpi/ic_launcher.png
- mipmap-mdpi/ic_launcher_foreground.png
- mipmap-mdpi/ic_launcher_round.png
- mipmap-hdpi/ic_launcher.png
- mipmap-hdpi/ic_launcher_foreground.png
- mipmap-hdpi/ic_launcher_round.png
- mipmap-xhdpi/ic_launcher.png
- mipmap-xhdpi/ic_launcher_foreground.png
- mipmap-xhdpi/ic_launcher_round.png
- mipmap-xxhdpi/ic_launcher.png
- mipmap-xxhdpi/ic_launcher_foreground.png
- mipmap-xxhdpi/ic_launcher_round.png
- mipmap-xxxhdpi/ic_launcher.png
- mipmap-xxxhdpi/ic_launcher_foreground.png
- mipmap-xxxhdpi/ic_launcher_round.png
- mipmap-anydpi-v26/ic_launcher.xml
- mipmap-anydpi-v26/ic_launcher_round.xml

New file (may need to merge with existing values/colors.xml):
- values/ic_launcher_background.xml
  → color name="ic_launcher_background" #431C33

## After installing

1. Uninstall the app from device
2. Rebuild: flutter clean && flutter build apk
3. Reinstall

The icon should now render at the correct size on all Android launchers
(square, round, squircle, teardrop) with the wine background and 
properly-scaled Qeran symbol.

## Design specs used

- Adaptive icon: 108dp canvas with 66dp safe zone (61%)
- Legacy icon: 55% symbol size on wine background with 22% rounded corners
- Background color: #431C33 (Qeran wine)
- Symbol: Qeran ring symbol only (no QERAN text)
