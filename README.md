# Planespotting

A companion app for the Magic: The Gathering format Planechase. Created by Forrest.

## Features

- Draws a random plane or phenomenon from your chosen sets and types, with swipe-back history, rotate and pinch/double-tap zoom.
- A planar die with a casino-style roll, and a card text panel with the artist credit.
- A card browser with search (name, rules text, artist) and filters, where you can exclude single cards from the deck.
- Options for sets, Un-cards and types, and a switch to keep the screen on during a game.

## Setup

The card art is Wizards of the Coast's, so `assets/cards/`, `assets/cards_thumb/` and `assets/planeschase/` are gitignored and are not in the repo. `assets/cards.json` (card metadata) is tracked. After cloning, download the images before running or building the app:

```sh
pip install pillow
python3 tool/fetch_cards.py
```

This pulls all 206 paper planes and phenomena from [Scryfall](https://scryfall.com), saves them as WebP in `assets/cards/`, makes the 360 px thumbnails the browser uses in `assets/cards_thumb/`, and regenerates `assets/cards.json`. Re-running it skips images that already exist, so it also picks up newly released sets. `python3 tool/fetch_cards.py --thumbs-only` rebuilds just the thumbnails from the images you already have, without the network. `flutter build` fails if `assets/cards/` or `assets/cards_thumb/` is missing.

New to Flutter on Linux? [This guide](https://docs.flutter.dev/get-started/install/linux/android) is a good start.

## Run, test, build

```sh
flutter pub get
flutter run                 # add -d linux / -d chrome for desktop / web
flutter analyze
flutter test
flutter build apk --debug
```

The Android launcher icon is generated from `assets/icon/` with `dart run flutter_launcher_icons`. There is no Linux window icon.

## Credits

Card images and data come from [Scryfall](https://scryfall.com), which is not affiliated with this app. Planespotting is unofficial Fan Content permitted under the Wizards of the Coast Fan Content Policy. It is not approved or endorsed by Wizards. Portions of the materials used are property of Wizards of the Coast. ©Wizards of the Coast LLC.

Notes to self:

- custom cards?
