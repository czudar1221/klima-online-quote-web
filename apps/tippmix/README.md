# Tippmix kalkulátor

Magyar kereskedőasztal alsó menüvel: Mai szelvény, Figyelőlista, Forma, AI jegyzet, Chat. Szerkeszthető Ft tét. **Esély a tört-számításból**, az AI nem írja felül. Nincs mintaadat.

## VS Code + Android

1. Flutter + Android SDK, VS Code Flutter/Dart kiterjesztés.
2. Nyisd meg `apps/tippmix/`. A repo gyökere a HVAC webes build — ne írd felül.
3. Opcionális: `.env.example` → `.env`, `ODDS_API_KEY` (the-odds-api.com) a többi sporthoz.

```bash
cd apps/tippmix
flutter pub get
flutter run
```

Kulccsal (chat + AI jegyzet a telefonon is): `flutter run --dart-define-from-file=.env`

Release APK: `flutter build apk --release --dart-define-from-file=.env` — a `.env` gitignore-olt, ne commitold.

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
