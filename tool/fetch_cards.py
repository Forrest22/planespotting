#!/usr/bin/env python3
"""Fetch every paper Planechase plane/phenomenon from Scryfall.

Writes assets/cards.json and WebP images to assets/cards/. Idempotent: images
that already exist are skipped. Requires Pillow (pip install pillow).

    python3 tool/fetch_cards.py
"""
import io
import json
import re
import time
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
IMAGE_DIR = ROOT / "assets" / "cards"
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


def main():
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
            "image": f"assets/cards/{file_name}",
            "funny": c["set_type"] in ("funny", "memorabilia"),
        })
    cards.sort(key=sort_key)
    JSON_PATH.write_text(json.dumps(cards, indent=1, ensure_ascii=False) + "\n")
    for set_code, count in Counter(c["set"] for c in cards).items():
        print(f"  {set_code}: {count}")
    print(f"{len(cards)} cards, {len(list(IMAGE_DIR.glob('*.webp')))} images")


if __name__ == "__main__":
    main()
