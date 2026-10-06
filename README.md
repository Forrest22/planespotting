# Planespotting

A companion app for playing the Magic the Gathering format Planechase. Created by Forrest.

## Card images (setup required)

The card art is Wizards of the Coast's, so `assets/cards/` and `assets/planeschase/` are gitignored and are not in the repo. `assets/cards.json` (card metadata) is tracked. After cloning, download the images before running or building the app:

```sh
pip install pillow
python3 tool/fetch_cards.py
```

This pulls all 206 paper planes and phenomena from [Scryfall](https://scryfall.com), saves them as WebP in `assets/cards/` and regenerates `assets/cards.json`. Re-running it skips images that already exist, so it also picks up newly released sets. `flutter build` fails if `assets/cards/` is missing.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Personally I found [this guide](https://docs.flutter.dev/get-started/install/linux/android) very helpful when trying to set up Flutter for the first time.

Notes to self:

- padding to the UI
- swipe to go next and back
- pinch to zoom
