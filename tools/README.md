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
