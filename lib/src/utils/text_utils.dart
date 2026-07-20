/// Levenshtein edit distance between [a] and [b] — the minimum single-character
/// inserts, deletes, and substitutions to turn one into the other. Space-optimized
/// two-row dynamic programming (only the previous and current row are kept).
int levenshtein(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final current = [i + 1, ...List.filled(b.length, 0)];
    for (var j = 0; j < b.length; j++) {
      final substitution = previous[j] + (a[i] == b[j] ? 0 : 1);
      current[j + 1] = [substitution, previous[j + 1] + 1, current[j] + 1].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}

/// The candidate nearest [target] within [maxDistance] edits, or null — used for
/// "did you mean" typo suggestions. Prunes candidates whose length alone puts
/// them out of reach of the current best before computing the full distance.
String? closestMatch(
  String target,
  Iterable<String> candidates, {
  int maxDistance = 3,
  bool caseInsensitive = false,
}) {
  final needle = caseInsensitive ? target.toLowerCase() : target;
  String? best;
  var bestDistance = maxDistance + 1;
  for (final candidate in candidates) {
    final other = caseInsensitive ? candidate.toLowerCase() : candidate;
    if ((needle.length - other.length).abs() >= bestDistance) continue;
    final distance = levenshtein(needle, other);
    if (distance < bestDistance) {
      bestDistance = distance;
      best = candidate;
    }
  }
  return best;
}
