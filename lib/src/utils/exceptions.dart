sealed class StardustException implements Exception {
  final String message;
  final Object? cause;

  const StardustException(this.message, [this.cause]);

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

class ConfigException extends StardustException {
  const ConfigException(super.message, [super.cause]);
}

class GeneratorException extends StardustException {
  const GeneratorException(super.message, [super.cause]);
}

class ContentException extends StardustException {
  final String? sourcePath;

  const ContentException(String message, {this.sourcePath, Object? cause}) : super(message, cause);

  @override
  String toString() {
    final buffer = StringBuffer('ContentException: $message');
    if (sourcePath != null) {
      buffer.write(' (in $sourcePath)');
    }
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

class OpenApiException extends StardustException {
  const OpenApiException(super.message, [super.cause]);
}

class PagefindException extends StardustException {
  const PagefindException(super.message, [super.cause]);
}
