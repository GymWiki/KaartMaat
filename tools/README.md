# Tools

`store_assets.py` maakt de Google Play-afbeeldingen (screenshots met kop, feature
graphic, icoon en contactblad). Het hoort niet bij de Flutter-app en voegt niets
toe aan `pubspec.yaml`.

## Installatie

Python 3.10 of nieuwer en Pillow:

```bash
python -m pip install pillow
```

## Gebruik

1. Maak ruwe screenshots met nepdata. Start de app op een emulator (bijvoorbeeld
   Pixel 8, API 34, 1080x2400) in demo-modus:

   ```bash
   flutter run --dart-define=DEMO=true
   ```

   Demo-modus werkt alleen in debug- en profile-builds en wist alle lokale data.
   Sla de schermen op als `store_assets/raw/01_overzicht.png` enzovoort (zie de
   lijst bovenin `store_assets.py`).
2. Bouw de afbeeldingen:

   ```bash
   python tools/store_assets.py
   ```

   Resultaat in `store_assets/play/`: `phone/01.png` t/m `08.png` (1080x1920),
   `feature_graphic.png` (1024x500), `icon_512.png` en `overzicht.png`.
3. Alleen controleren (afmeting, formaat, grootte):

   ```bash
   python tools/store_assets.py --check
   ```

De koppen staan in `SHOTS` in het script. Het lettertype is Roboto Condensed Bold
uit `assets/fonts` (Apache 2.0).

## App-iconen

`make_icons.py` maakt alle iconen uit het logo in `store_assets/logo/logo.png`
(transparant): Android (adaptief en klassiek), iOS, het Play-icoon
(`store_assets/play/icon_512.png`) en `docs/store/icon-512.png`.

```bash
python tools/make_icons.py
```

## Tablet-screenshots

`store_assets.py` maakt ook `play/tablet7/` (1200x1920) en `play/tablet10/`
(1600x2560) uit de ruwe opnames in `store_assets/raw_tablet7/` en
`store_assets/raw_tablet10/` (staand), met dezelfde koppen als de telefoonset.
De opnames kun je maken met een emulator op 1200x1920 en 1600x2560 bij 320 dpi
(`adb shell wm size 1200x1920` en `adb shell wm density 320` werkt ook op een
telefoon-emulator; zet het na afloop terug met `wm size reset` en
`wm density reset`).
