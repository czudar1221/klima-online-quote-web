import 'models.dart';

/// Plug-in point for a real odds feed. Keep implementations legal (official API
/// or licensed data). Do not scrape Tippmix pages from this app.
abstract class MatchFeed {
  Future<List<SportsMatch>> upcoming();
  Future<List<SportsMatch>> live();
}
