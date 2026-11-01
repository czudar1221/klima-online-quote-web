/// Loose team-name matching so Odds API labels join ESPN form/history.
String foldTeamName(String raw) {
  final buf = StringBuffer();
  for (final rune in raw.toLowerCase().runes) {
    buf.write(_foldChar(rune));
  }
  final tokens = buf
      .toString()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty && !_stop.contains(t))
      .map((t) => _tokenAlias[t] ?? t)
      .where((t) => t.isNotEmpty && !_stop.contains(t))
      .toList();
  return tokens.join();
}

String canonicalTeamName(String raw) {
  final folded = foldTeamName(raw);
  return _nameAlias[folded] ?? folded;
}

Set<String> teamNameTokens(String raw) {
  final folded = canonicalTeamName(raw);
  if (folded.isEmpty) return const {};
  final parts = <String>{};
  // Keep the full canonical string plus 4+ letter chunks from the original.
  parts.add(folded);
  final buf = StringBuffer();
  for (final rune in raw.toLowerCase().runes) {
    buf.write(_foldChar(rune));
  }
  for (final t in buf.toString().split(RegExp(r'[^a-z0-9]+'))) {
    if (t.isEmpty || _stop.contains(t)) continue;
    final a = _tokenAlias[t] ?? t;
    if (a.length >= 4) parts.add(_nameAlias[a] ?? a);
  }
  return parts;
}

bool namesLooselyEqual(String a, String b) {
  final ca = canonicalTeamName(a);
  final cb = canonicalTeamName(b);
  if (ca.isEmpty || cb.isEmpty) return false;
  if (ca == cb) return true;
  if (ca.length >= 5 && cb.length >= 5 && (ca.contains(cb) || cb.contains(ca))) {
    return true;
  }
  final ta = teamNameTokens(a);
  final tb = teamNameTokens(b);
  if (ta.isEmpty || tb.isEmpty) return false;
  final shorter = ta.length <= tb.length ? ta : tb;
  final longer = ta.length <= tb.length ? tb : ta;
  final sig = shorter.where((t) => t.length >= 4).toSet();
  if (sig.isEmpty) return false;
  return sig.every(longer.contains);
}

bool fixturesLooselyMatch({
  required String sportA,
  required String homeA,
  required String awayA,
  required DateTime kickoffA,
  required String sportB,
  required String homeB,
  required String awayB,
  required DateTime kickoffB,
}) {
  if (sportA != sportB) return false;
  final sameWay =
      namesLooselyEqual(homeA, homeB) && namesLooselyEqual(awayA, awayB);
  final swapped =
      namesLooselyEqual(homeA, awayB) && namesLooselyEqual(awayA, homeB);
  if (!sameWay && !swapped) return false;
  return kickoffA.difference(kickoffB).abs() <= const Duration(hours: 48);
}

String _foldChar(int rune) {
  switch (rune) {
    case 0xE1:
    case 0xE0:
    case 0xE4:
    case 0xE5:
    case 0xE2:
    case 0xE3:
      return 'a';
    case 0xE9:
    case 0xE8:
    case 0xEB:
    case 0xEA:
      return 'e';
    case 0xED:
    case 0xEC:
    case 0xEF:
    case 0xEE:
      return 'i';
    case 0xF3:
    case 0xF2:
    case 0xF6:
    case 0xF4:
    case 0xF5:
    case 0xF8:
    case 0x151:
      return 'o';
    case 0xFA:
    case 0xF9:
    case 0xFC:
    case 0xFB:
    case 0x171:
      return 'u';
    case 0xF1:
      return 'n';
    case 0xE7:
      return 'c';
    case 0xDF:
      return 'ss';
    case 0xE6:
      return 'ae';
    default:
      return String.fromCharCode(rune);
  }
}

const _stop = {
  'fc',
  'cf',
  'sc',
  'ac',
  'afc',
  'bc',
  'bk',
  'fk',
  'if',
  'sv',
  'as',
  'rc',
  'cd',
  'ud',
  'sl',
  'al',
  'club',
  'calcio',
  'de',
  'del',
  'la',
  'el',
  'the',
  'and',
  'of',
  'basketball',
  'football',
  'soccer',
  'hotspur',
  'wanderers',
  'athletics',
};

const _tokenAlias = {
  'utd': 'united',
  'man': 'manchester',
  'ath': 'athletic',
  'wolves': 'wolverhampton',
  'spurs': 'tottenham',
  'psg': 'parissaintgermain',
  'inter': 'internazionale',
  'munich': 'munchen',
  'munchen': 'munchen',
  'koeln': 'koln',
  'cologne': 'koln',
  'la': 'losangeles',
  'ny': 'newyork',
  'gs': 'goldenstate',
  'okc': 'oklahomacity',
  'sa': 'sanantonio',
  'no': 'neworleans',
};

const _nameAlias = {
  'manutd': 'manchesterunited',
  'manchesterunitedfc': 'manchesterunited',
  'mancity': 'manchestercity',
  'manchestercityfc': 'manchestercity',
  'intermilan': 'internazionale',
  'internazionalemilano': 'internazionale',
  'internazionale': 'internazionale',
  'parissaintgermain': 'parissaintgermain',
  'parissg': 'parissaintgermain',
  'psg': 'parissaintgermain',
  'atleticomadrid': 'atleticomadrid',
  'atleticodemadrid': 'atleticomadrid',
  'bayernmunich': 'bayernmunchen',
  'fcbayernmunich': 'bayernmunchen',
  'fcbayernmunchen': 'bayernmunchen',
  'bayernmunchen': 'bayernmunchen',
  'wolves': 'wolverhampton',
  'wolverhampton': 'wolverhampton',
  'nottmforest': 'nottinghamforest',
  'nottinghamforest': 'nottinghamforest',
  'brightonhovealbion': 'brighton',
  'brightonandhovealbion': 'brighton',
  'lalakers': 'losangeleslakers',
  'laclippers': 'losangelesclippers',
  'nyknicks': 'newyorkknicks',
  'nyk': 'newyorkknicks',
  'gswarriors': 'goldenstatewarriors',
  'okcthunder': 'oklahomacitythunder',
  'bostonceltics': 'celtics',
  'celtics': 'celtics',
};
