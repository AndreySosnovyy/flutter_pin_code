class WrongPinCodeFormatException implements Exception {
  const WrongPinCodeFormatException(this.cause);

  final String cause;
}
