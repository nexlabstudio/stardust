import 'dart:convert';

import '../utils/text_utils.dart';
import 'stardust_schema.dart';

/// A single problem found while validating stardust.yaml.
class ConfigIssue {
  final String path;
  final String message;
  final bool isWarning;

  const ConfigIssue(this.path, this.message, {this.isWarning = false});

  @override
  String toString() => '$path: $message';
}

/// Validates raw stardust.yaml data against the embedded JSON schema.
///
/// Type, enum, range, and required-key violations are errors; unknown keys
/// are warnings so a typo never silently changes behavior.
class SchemaValidator {
  final Map<String, dynamic> _schema;

  SchemaValidator() : _schema = jsonDecode(stardustSchemaJson) as Map<String, dynamic>;

  List<ConfigIssue> validate(Map yaml) {
    final issues = <ConfigIssue>[];
    _validateNode(_schema, yaml, 'config', issues);
    return issues;
  }

  Map<String, dynamic> _resolve(Map<String, dynamic> schema) => switch (schema[r'$ref']) {
        final String ref when ref.startsWith(r'#/$defs/') => switch (
              (_schema[r'$defs'] as Map<String, dynamic>)[ref.substring(8)]) {
            final Map<String, dynamic> resolved => resolved,
            _ => schema,
          },
        _ => schema,
      };

  void _validateNode(Map<String, dynamic> rawSchema, Object? value, String path, List<ConfigIssue> issues) {
    if (value == null) return;
    final schema = _resolve(rawSchema);

    if (schema['oneOf'] case final List branches) {
      final failures = <List<ConfigIssue>>[];
      for (final branch in branches.cast<Map<String, dynamic>>()) {
        final branchIssues = <ConfigIssue>[];
        _validateNode(branch, value, path, branchIssues);
        if (branchIssues.every((issue) => issue.isWarning)) return;
        failures.add(branchIssues);
      }
      issues.add(ConfigIssue(path, _describeOneOfFailure(branches.cast<Map<String, dynamic>>(), failures)));
      return;
    }

    if (schema['type'] case final String type) {
      if (_typeError(type, value, path) case final issue?) {
        issues.add(issue);
        return;
      }
    }

    if (schema['enum'] case final List allowed) {
      if (!allowed.contains(value)) {
        issues.add(ConfigIssue(path, 'must be one of ${allowed.join(', ')} (got "$value")'));
        return;
      }
    }

    if (schema['pattern'] case final String pattern when value is String) {
      if (!RegExp(pattern).hasMatch(value)) {
        issues.add(ConfigIssue(path, 'does not match expected format $pattern (got "$value")'));
      }
    }

    if (value is num) {
      if (schema['minimum'] case final num min when value < min) {
        issues.add(ConfigIssue(path, 'must be at least $min (got $value)'));
      }
      if (schema['maximum'] case final num max when value > max) {
        issues.add(ConfigIssue(path, 'must be at most $max (got $value)'));
      }
    }

    if (value is Map) _validateMap(schema, value, path, issues);

    if (value is List) {
      if (schema['items'] case final Map<String, dynamic> itemSchema) {
        for (final (index, item) in value.indexed) {
          _validateNode(itemSchema, item, '$path[$index]', issues);
        }
      }
    }
  }

  void _validateMap(Map<String, dynamic> schema, Map value, String path, List<ConfigIssue> issues) {
    final properties = switch (schema['properties']) {
      final Map<String, dynamic> props => props,
      _ => const <String, dynamic>{},
    };

    if (schema['required'] case final List required) {
      for (final key in required.cast<String>()) {
        if (value[key] == null) {
          issues.add(ConfigIssue(path, 'missing required key "$key"'));
        }
      }
    }

    for (final entry in value.entries) {
      final key = entry.key.toString();
      final childPath = path == 'config' ? key : '$path.$key';

      if (properties[key] case final Map<String, dynamic> childSchema) {
        _validateNode(childSchema, entry.value, childPath, issues);
      } else if (schema['additionalProperties'] case final Map<String, dynamic> extraSchema) {
        _validateNode(extraSchema, entry.value, childPath, issues);
      } else if (schema['additionalProperties'] == false && properties.isNotEmpty) {
        final hint = switch (closestMatch(key, properties.keys, maxDistance: 2, caseInsensitive: true)) {
          final suggestion? => ' — did you mean "$suggestion"?',
          null => '',
        };
        issues.add(ConfigIssue(childPath, 'unknown key (ignored)$hint', isWarning: true));
      }
    }
  }

  ConfigIssue? _typeError(String type, Object value, String path) {
    final ok = switch (type) {
      'object' => value is Map,
      'array' => value is List,
      'string' => value is String,
      'boolean' => value is bool,
      'integer' => value is int,
      'number' => value is num,
      _ => true,
    };
    if (ok) return null;
    final actual = switch (value) {
      Map() => 'a mapping',
      List() => 'a list',
      String() => 'a string ("$value")',
      bool() => 'a boolean ($value)',
      num() => 'a number ($value)',
      _ => value.runtimeType.toString(),
    };
    final expected = switch (type) {
      'object' => 'a mapping',
      'array' => 'a list',
      'boolean' => 'true or false',
      'integer' => 'an integer',
      'number' => 'a number',
      _ => 'a $type',
    };
    return ConfigIssue(path, 'expected $expected, got $actual');
  }

  String _describeOneOfFailure(List<Map<String, dynamic>> branches, List<List<ConfigIssue>> failures) {
    final types = branches.map((b) => b['type']).whereType<String>().toList();
    if (failures.length == 1) return failures.single.map((i) => i.message).join('; ');
    return 'must be ${types.isEmpty ? 'one of the allowed shapes' : types.join(' or ')}';
  }
}
