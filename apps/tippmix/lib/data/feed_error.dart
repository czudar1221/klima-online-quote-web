class FeedException implements Exception {
  FeedException(this.message);
  final String message;

  @override
  String toString() => message;
}
