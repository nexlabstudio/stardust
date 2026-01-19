/// Callback type for logging messages.
typedef LogCallback = void Function(String message);

/// Logger that handles null-safe logging with optional error fallback.
class Logger {
  final LogCallback? _onLog;
  final LogCallback? _onError;

  const Logger({LogCallback? onLog, LogCallback? onError})
      : _onLog = onLog,
        _onError = onError;

  /// Log an informational message.
  void log(String message) => _onLog?.call(message);

  /// Log an error message. Falls back to [log] if no error handler is set.
  void error(String message) => (_onError ?? _onLog)?.call(message);
}
