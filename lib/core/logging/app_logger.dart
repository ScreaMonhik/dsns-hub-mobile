import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final appLogger = Logger(
  filter: _AppLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 6,
    dateTimeFormat: DateTimeFormat.none,
  ),
  output: _AppLogOutput(),
);

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.error.index;
    }
    return true;
  }
}

class _AppLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (!kReleaseMode) {
      for (final line in event.lines) {
        debugPrint(line);
      }
    }

    if (event.level.index >= Level.error.index) {
      final message = _sanitize(event.lines.join('\n'));
      FirebaseCrashlytics.instance.log(message);
    }
  }
}

String _sanitize(String value) {
  return value
      .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-._]+', caseSensitive: false), 'Bearer [redacted]')
      .replaceAll(RegExp(r'(password|token|authorization)\s*[:=]\s*\S+', caseSensitive: false), r'$1=[redacted]');
}

Future<void> recordNonFatalError(Object error, StackTrace stack) {
  final sanitized = _sanitize(error.toString());
  return FirebaseCrashlytics.instance.recordError(
    sanitized,
    stack,
    fatal: false,
  );
}

Future<void> recordFatalError(Object error, StackTrace stack) {
  final sanitized = _sanitize(error.toString());
  return FirebaseCrashlytics.instance.recordError(
    sanitized,
    stack,
    fatal: true,
  );
}
