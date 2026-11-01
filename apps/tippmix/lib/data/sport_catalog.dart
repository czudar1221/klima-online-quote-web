String sportLabelHu(String sport) {
  return switch (sport) {
    'soccer' => 'Labdarúgás',
    'basketball' => 'Kosárlabda',
    'hockey' || 'icehockey' => 'Jégkorong',
    'tennis' => 'Tenisz',
    'football' || 'americanfootball' => 'Amerikai foci',
    'baseball' => 'Baseball',
    'handball' => 'Kézilabda',
    'volleyball' => 'Röplabda',
    'rugby' || 'rugbyleague' => 'Rögbi',
    'mma' => 'MMA',
    'boxing' => 'Ökölvívás',
    'cricket' => 'Krikett',
    'golf' => 'Golf',
    'waterpolo' || 'water-polo' => 'Vízilabda',
    'aussierules' => 'Ausztrál foci',
    _ => _title(sport),
  };
}

String _title(String sport) {
  if (sport.isEmpty) return sport;
  return sport[0].toUpperCase() + sport.substring(1);
}

/// The Odds API sport keys that map onto Tippmix-like markets.
String sportFromOddsKey(String key) {
  if (key.startsWith('soccer_')) return 'soccer';
  if (key.startsWith('basketball_')) return 'basketball';
  if (key.startsWith('icehockey_')) return 'hockey';
  if (key.startsWith('tennis_')) return 'tennis';
  if (key.startsWith('americanfootball_')) return 'football';
  if (key.startsWith('baseball_')) return 'baseball';
  if (key.startsWith('handball_')) return 'handball';
  if (key.startsWith('volleyball_')) return 'volleyball';
  if (key.startsWith('rugby')) return 'rugby';
  if (key.startsWith('mma_')) return 'mma';
  if (key.startsWith('boxing_')) return 'boxing';
  if (key.startsWith('cricket_')) return 'cricket';
  if (key.startsWith('golf_')) return 'golf';
  if (key.startsWith('aussierules_')) return 'aussierules';
  return key.split('_').first;
}
