# Tippmix kalkulátor

Prémium Android-alkalmazás Flutterrel: meccsek, élő lista, előzmények és valószínűség-kalkulátor. A felhasználói felület **kizárólag magyar**.

A százalékot **nem** nyelvi modell számolja. A motor tizedes szorzókból implikált valószínűséget képez, levonja az overroundot, keveri a kurált csapatmodellel (forma + kulcsemberek, 40% modell / 60% piac, ha van keret), majd szelvény/kombináció szerint pontos törtekkel számol. Képlet a kalkulátor képernyőn és a tervben. Nem garancia.

## VS Code + Android

1. Telepítsd: [Flutter](https://docs.flutter.dev/get-started/install), Android SDK / emulátor (vagy USB-s telefon), VS Code **Flutter** és **Dart** kiterjesztés.
2. Nyisd meg ezt a mappát: `apps/tippmix/` (File → Open Folder). A repo gyökere a HVAC webes build; azt ne írd felül.
3. Másold az `.env.example` fájlt `.env` névre, és töltsd ki az `OPENAI_API_KEY` sort, ha magyarázatot is kérsz. A `.env` gitignore-olt.
4. Futtasd:

```bash
cd apps/tippmix
flutter pub get
flutter run --dart-define-from-file=.env
```

VS Code: Run and Debug → **Tippmix (Android)**. Kulcs nélkül: **Tippmix (math only)** — a kalkulátor így is működik.

## Adat: mi valódi, mi minta

- **Valódi:** a te szorzó-beviteled, a helyi előzmények, a matematikai motor.
- **Kurált (nem élő):** csapaterő, forma, kulcsemberek — `lib/data/curated_squads.dart`, a UI-n „Kurált keret”.
- **Minta (nem élő):** a beépített NB I / kupa meccsek és az „élő” percek/állások. Nincs hivatalos Tippmix-API bekötve.
- Új forrás: implementáld a `MatchFeed` interfészt (`lib/data/match_feed.dart`), és add át az `AppController`nek. Ne scrapelj.

## OpenAI

Opcionális, rövid magyar magyarázat a **már kiszámolt** számokhoz. A megjelenített `%` mindig a tesztelt motorból jön. Ha a hívás sikertelen, a kalkulátor offline marad.

A kulcsot soha ne commitold. Ha a kulcs szerepelt csevegésben, cseréld (rotate), majd írd az újat a `.env` fájlba.

## Teszt és analízis

```bash
cd apps/tippmix
flutter analyze
flutter test
```
