class Timeout {
  Timeout({
    required this.durationInSeconds,
    required this.expirationTimestamp,
  });

  /// Duration of the timeout in seconds
  final int durationInSeconds;

  /// Timestamp of the expiration
  final DateTime expirationTimestamp;

  factory Timeout.fromMap(Map<String, dynamic> json) {
    return Timeout(
      durationInSeconds: json['duration'] as int,
      expirationTimestamp: DateTime.fromMillisecondsSinceEpoch(
          json['expirationTimestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'durationInSeconds': durationInSeconds,
      'expirationTimestamp': expirationTimestamp.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'Timeout('
        'durationInSeconds: $durationInSeconds, '
        'expirationTimestamp: $expirationTimestamp'
        ')';
  }
}
