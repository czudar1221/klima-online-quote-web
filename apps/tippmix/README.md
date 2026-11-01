# Tippmix kalkulátor

Egy magyar képernyő: mai/élő meccsek, 1/X/2 (vagy 1/2), kiemelt tipp, **esély a szorzóból**. Nem garancia. Nincs mintaadat.

A százalék a determinisztikus motorból jön (implikált valószínűség, árrés levétel). Szoros meccsen 45% is helyes.

## VS Code + Android

1. Flutter + Android SDK, VS Code Flutter/Dart kiterjesztés.
2. Nyisd meg `apps/tippmix/`. A repo gyökere a HVAC webes build — ne írd felül.
3. Opcionális: `.env.example` → `.env`, `ODDS_API_KEY` (the-odds-api.com) a többi sporthoz.

```bash
cd apps/tippmix
flutter pub get
flutter run
```

Kulccsal: `flutter run --dart-define-from-file=.env`

## Élő adat

- **Alap (kulcs nélkül):** ESPN nyilvános scoreboard JSON (nem HTML-scrapelés): labdarúgás, kosárlabda, jégkorong, amerikai foci, tenisz/baseball/MMA, ha van szorzó.
- **Opcionális:** The Odds API (`ODDS_API_KEY`) — a forrás által listázott sportok h2h szorzói (tenisz, kézilabda, rögbi stb., ha aktív).
- Hálózat nélkül: magyar hiba + Újra. Nincs minta-visszaállítás.
- Nincs hivatalos Tippmix-feed. Nincs NB I az ESPN listáján.

## Teszt

```bash
cd apps/tippmix
flutter analyze
flutter test
```
