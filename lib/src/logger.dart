import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTime,
    methodCount: 1,
    printEmojis: false,
  ),
  filter: EnableLogFilter(),
);

class EnableLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}
