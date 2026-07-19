import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Source text with code spans replaced by collision-proof placeholder tokens.
class MaskedSource {
  final String text;
  final String _salt;
  final Map<int, String> _spans;

  MaskedSource._(this.text, this._salt, this._spans);

  /// Puts the original code spans back into [fragment].
  String restore(String fragment) {
    if (_spans.isEmpty) return fragment;
    return fragment.replaceAllMapped(
      RegExp('STARDUSTC0DE${_salt}X(\\d+)Z'),
      (match) => switch (_spans[int.parse(match.group(1) ?? '')]) {
        final span? => span,
        null => match.group(0) ?? '',
      },
    );
  }
}

/// Masks fenced code blocks and inline code spans so component scanning never
/// matches inside code. Tokens are alphanumeric (markdown-inert) and salted
/// with the content hash so real text cannot collide with them.
MaskedSource maskCodeSpans(String source) {
  var salt = sha256.convert(utf8.encode(source)).toString().substring(0, 8);
  while (source.contains('STARDUSTC0DE$salt')) {
    salt = sha256.convert(utf8.encode(salt)).toString().substring(0, 8);
  }

  final spans = <int, String>{};
  final out = StringBuffer();
  var pos = 0;

  String mask(String span) {
    final token = 'STARDUSTC0DE${salt}X${spans.length}Z';
    spans[spans.length] = span;
    return token;
  }

  while (pos < source.length) {
    final atLineStart = pos == 0 || source[pos - 1] == '\n';

    if (atLineStart) {
      if (_fenceSpanEnd(source, pos) case final end?) {
        out.write(mask(source.substring(pos, end)));
        pos = end;
        continue;
      }
    }

    if (source[pos] == '`') {
      var runEnd = pos;
      while (runEnd < source.length && source[runEnd] == '`') {
        runEnd++;
      }
      final runLength = runEnd - pos;
      if (_inlineSpanEnd(source, runEnd, runLength) case final end?) {
        out.write(mask(source.substring(pos, end)));
        pos = end;
        continue;
      }
      out.write(source.substring(pos, runEnd));
      pos = runEnd;
      continue;
    }

    final nextStop = _nextStop(source, pos);
    out.write(source.substring(pos, nextStop));
    pos = nextStop;
  }

  return MaskedSource._(out.toString(), salt, spans);
}

/// End of the fence opening at line-start [pos], or null when it opens none.
int? _fenceSpanEnd(String source, int pos) {
  var i = pos;
  while (i < source.length && i - pos < 3 && source[i] == ' ') {
    i++;
  }
  if (i >= source.length || (source[i] != '`' && source[i] != '~')) return null;

  final fenceChar = source[i];
  var fenceEnd = i;
  while (fenceEnd < source.length && source[fenceEnd] == fenceChar) {
    fenceEnd++;
  }
  final fenceLength = fenceEnd - i;
  if (fenceLength < 3) return null;

  final infoEnd = switch (source.indexOf('\n', fenceEnd)) { -1 => source.length, final n => n };
  if (fenceChar == '`' && source.substring(fenceEnd, infoEnd).contains('`')) return null;

  // Unlike CommonMark, closers may be indented >3: component inners carry
  // re-indented fences, and an over-long mask swallows real content.
  var lineStart = infoEnd + 1;
  while (lineStart < source.length) {
    final lineEnd = switch (source.indexOf('\n', lineStart)) { -1 => source.length, final n => n };
    final trimmed = source.substring(lineStart, lineEnd).trimLeft();
    if (trimmed.startsWith(fenceChar * fenceLength)) {
      final afterFence = trimmed.replaceAll(fenceChar, '');
      if (afterFence.trim().isEmpty) return lineEnd;
    }
    lineStart = lineEnd + 1;
  }
  return source.length;
}

/// End of the inline span opened by the backtick run ending at [from], or null.
int? _inlineSpanEnd(String source, int from, int runLength) {
  var i = from;
  while (i < source.length) {
    final tick = source.indexOf('`', i);
    if (tick == -1) return null;
    var tickEnd = tick;
    while (tickEnd < source.length && source[tickEnd] == '`') {
      tickEnd++;
    }
    if (tickEnd - tick == runLength) return tickEnd;
    i = tickEnd;
  }
  return null;
}

/// Next position of interest: a line start (for fences) or a backtick.
int _nextStop(String source, int pos) {
  final newline = source.indexOf('\n', pos);
  final tick = source.indexOf('`', pos);
  return switch ((newline, tick)) {
    (-1, -1) => source.length,
    (-1, final t) => t,
    (final n, -1) => n + 1,
    (final n, final t) => t < n ? t : n + 1,
  };
}
