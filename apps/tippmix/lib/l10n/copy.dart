/// All user-facing strings. Hungarian only.
abstract final class Copy {
  static const appName = 'Tippmix asztal';
  static const homeTitle = 'Napi stratégia';
  static const homeHint =
      'Csak 50% feletti esély. Rangsor: nagyobb szorzó (több nyereség), nem a legnagyobb %.';
  static const esely = 'Esély';
  static const eselyFromOdds = 'Esély a szorzóból';
  static const tipp = 'Tipp';
  static const outcomeHome = '1';
  static const outcomeDraw = 'X';
  static const outcomeAway = '2';
  static const live = 'Élő';
  static const retry = 'Újra';
  static const vs = '–';
  static const minute = 'perc';
  static const stake = 'Tét';
  static const stakeFt = 'Tét (Ft)';
  static const stakeHint =
      'Írd be a tétet forintban. A szelvény és a lista nyeresége ehhez igazodik.';
  static const combinedOdds = 'Szelvény szorzó';
  static const combinedChance = 'Együttes esély';
  static const payout = 'Visszajáró';
  static const profit = 'Nyereség';
  static const bestSlip = 'Mai szelvény';
  static const watchlist = 'Figyelőlista';
  static const bestSingle = 'Legjobb egyes';
  static const noStrategy =
      'Most nincs 50% feletti esélyű kimenet a letöltött meccseken.';
  static const independence =
      'Az együttes esély a lábak szorzata, független meccseket feltételezve. Nem fogadás, csak számítás.';
  static const notABet = 'Ez nem tipp leadása és nem garancia.';
  static const retryLabel = 'Újra';

  static const disclaimer =
      'Az esély a szorzókból számolt, belsőleg konzisztens valószínűség. Nem jóslat, nem ügynökségi megbízás, nem valós tét.';

  static const errorNetwork =
      'Nem sikerült letölteni a meccseket. Ellenőrizd a netet, majd koppints az Újra gombra. Nincs mintaadat.';
  static const emptyMatches =
      'Most nincs olyan élő vagy mai meccs, aminél van fogadási szorzó.';
  static const closeMatch =
      'Szoros meccs: a piac nem emel ki egyértelmű favoritot.';
  static const favoriteHome = 'A számítás a hazai győzelmet tartja a legerősebbnek.';
  static const favoriteDraw = 'A számítás a döntetlent tartja a legerősebbnek.';
  static const favoriteAway =
      'A számítás a vendég győzelmet tartja a legerősebbnek.';

  static String statusLine({
    required int matches,
    required int live,
    required int tips,
  }) {
    return '$matches meccs · $live élő · $tips tipp 50% felett';
  }
}
