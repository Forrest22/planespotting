#!/usr/bin/env python3
"""Fetch every paper Planechase plane/phenomenon from Scryfall.

Writes assets/cards.json (including artist credits) and WebP images to
assets/cards/, plus a small thumbnail of each in assets/cards_thumb/ (used by the card
browser). Idempotent: images and thumbnails that already exist are skipped. Requires Pillow
(pip install pillow).

    python3 tool/fetch_cards.py                # everything
    python3 tool/fetch_cards.py --thumbs-only  # only thumbnails, from the images already
                                               # downloaded (no network)
"""
import io
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
IMAGE_DIR = ROOT / "assets" / "cards"
THUMB_DIR = ROOT / "assets" / "cards_thumb"
THUMB_WIDTH = 360  # the files are portrait; this is the short side
JSON_PATH = ROOT / "assets" / "cards.json"
QUERY = "(t:plane or t:phenomenon) game:paper"
HEADERS = {"User-Agent": "planespotting/1.0", "Accept": "application/json"}


def get(url):
    time.sleep(0.1)  # Scryfall asks for 50-100 ms between requests.
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS)) as r:
        return r.read()


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def search():
    params = urllib.parse.urlencode({"q": QUERY, "unique": "cards", "order": "set"})
    url = f"https://api.scryfall.com/cards/search?{params}"
    while url:
        page = json.loads(get(url))
        yield from page["data"]
        url = page.get("next_page")


def sort_key(card):
    digits = re.match(r"\d+", card["number"])
    return (card["set"], int(digits.group()) if digits else 0, card["number"])


def make_thumbnails():
    """Writes a small copy of every downloaded image that doesn't have one yet."""
    THUMB_DIR.mkdir(parents=True, exist_ok=True)
    made = 0
    for path in sorted(IMAGE_DIR.glob("*.webp")):
        thumb = THUMB_DIR / path.name
        if thumb.exists():
            continue
        image = Image.open(path).convert("RGB")
        height = round(image.height * THUMB_WIDTH / image.width)
        image.resize((THUMB_WIDTH, height), Image.LANCZOS).save(thumb, "WEBP", quality=75)
        made += 1
    print(f"{made} thumbnails made, {len(list(THUMB_DIR.glob('*.webp')))} in total")


def main():
    if "--thumbs-only" in sys.argv:
        make_thumbnails()
        return
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    cards = []
    for c in search():
        file_name = f"{c['set']}-{slug(c['collector_number'])}-{slug(c['name'])}.webp"
        path = IMAGE_DIR / file_name
        if not path.exists():
            uris = c.get("image_uris") or c["card_faces"][0]["image_uris"]
            png = get(uris["png"])
            Image.open(io.BytesIO(png)).convert("RGB").save(path, "WEBP", quality=85)
        cards.append({
            "name": c["name"],
            "set": c["set"],
            "setName": c["set_name"],
            "number": c["collector_number"],
            "type": "phenomenon" if "Phenomenon" in c["type_line"] else "plane",
            "oracleText": c.get("oracle_text", ""),
            "artist": c.get("artist") or (c.get("card_faces") or [{}])[0].get("artist", ""),
            "image": f"assets/cards/{file_name}",
            "funny": c["set_type"] in ("funny", "memorabilia"),
        })
    cards.sort(key=sort_key)
    JSON_PATH.write_text(json.dumps(cards, indent=1, ensure_ascii=False) + "\n")
    for set_code, count in Counter(c["set"] for c in cards).items():
        print(f"  {set_code}: {count}")
    print(f"{len(cards)} cards, {len(list(IMAGE_DIR.glob('*.webp')))} images")
    make_thumbnails()


if __name__ == "__main__":
    main()
