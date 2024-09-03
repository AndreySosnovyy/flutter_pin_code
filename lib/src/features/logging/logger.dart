// ignore_for_file: public_member_api_docs

import 'package:logger/logger.dart';

class PinLogger extends Logger {
  PinLogger({
    required super.printer,
    required this.filter,
  }) : super(filter: filter);

  final EnableLogFilter filter;
}

class EnableLogFilter extends LogFilter {
  EnableLogFilter({required this.enabled});

  bool enabled;

  @override
  bool shouldLog(LogEvent event) => enabled;
}

final logger = PinLogger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTime,
    printEmojis: false,
  ),
  filter: EnableLogFilter(enabled: false),
);
