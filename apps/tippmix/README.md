# Tippmix kalkulátor

Magyar kereskedőasztal alsó menüvel: Mai szelvény, Figyelőlista, Forma, AI jegyzet, Chat. Szerkeszthető Ft tét. **Esély a tört-számításból**, az AI nem írja felül. Nincs mintaadat.

## VS Code + Android

1. Flutter + Android SDK, VS Code Flutter/Dart kiterjesztés.
2. Nyisd meg `apps/tippmix/`. A repo gyökere a HVAC webes build — ne írd felül.
3. `.env.example` → `.env`. `OPENAI_API_KEY` a chathoz. `ODDS_API_KEY` (the-odds-api.com) az élő EU h2h szorzókhoz; a forma ESPN-ről jön. A `.env` gitignore-olt.

```bash
cd apps/tippmix
flutter pub get
flutter run
```

Kulccsal (chat + AI jegyzet a telefonon is): `flutter run --dart-define-from-file=.env`

Release APK: `flutter build apk --release --dart-define-from-file=.env` — a `.env` gitignore-olt, ne commitold.

## Élő adat

- **Szorzó (kulccsal a telefonos APK-ban):** The Odds API EU h2h (Tippmix-szerű ligák: EPL, La Liga, NBA, NHL, NFL, ATP/WTA, MMA, kézilabda stb.).
- **Forma / eredmény / hiányzó:** ESPN scoreboard JSON (nem HTML-scrapelés). A két forrás meccsnév szerint összefésül.
- Hálózat nélkül: magyar hiba + Újra. Nincs minta-visszaállítás.
- Nincs hivatalos Tippmix-feed. Nincs NB I az ESPN listáján.

## Teszt

```bash
cd apps/tippmix
flutter analyze
flutter test
```
