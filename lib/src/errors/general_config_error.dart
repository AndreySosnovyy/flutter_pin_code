class GeneralConfigError implements Error {
  const GeneralConfigError(this.cause);

  final String cause;

  @override
  StackTrace? get stackTrace => StackTrace.current;

  @override
  String toString() => 'GeneralConfigError: $cause';
}
