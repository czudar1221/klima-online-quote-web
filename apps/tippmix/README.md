# Tippmix kalkulátor

Magyar kereskedőasztal: mai szelvény (50%+ esély, szorzó szerint), szerkeszthető Ft tét (alap 50 000), visszajáró/nyereség, alatta figyelőlista. **Esély a szorzóból**, nem garancia, nem valós tét. Nincs mintaadat.

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
