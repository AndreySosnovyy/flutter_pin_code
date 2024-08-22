class CantWasteAttemptException implements Exception {
  const CantWasteAttemptException(this.cause);

  final String cause;

  @override
  String toString() => 'CantWasteAttemptException: $cause';
}
