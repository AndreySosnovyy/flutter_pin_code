// TODO(Sosnovyy): add stack trace to every exception
// TODO(Sosnovyy): add toString to every exception and error
// TODO(Sosnovyy): export exceptions
class CantReturnTimeoutException implements Exception {
  const CantReturnTimeoutException(this.cause);

  final String cause;
}
