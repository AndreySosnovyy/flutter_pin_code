import 'package:logger/logger.dart';

// TODO(Sosnovyy): decide if make logging configurable from outside
final logger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTime,
    printEmojis: false,
  ),
  filter: EnableLogFilter(),
);

class EnableLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}
