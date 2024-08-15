class CantWasteAttemptException implements Exception {
  const CantWasteAttemptException(this.cause);

  final String cause;
}
