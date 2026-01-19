import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../utils/exceptions.dart';
import '../utils/logger.dart';
import '../utils/patterns.dart';

/// Imports OpenAPI/Swagger specs and generates Stardust markdown docs
class OpenApiImporter {
  final String specPath;
  final String outputDir;
  final OpenApiOptions options;
  final Logger logger;

  OpenApiImporter({
    required this.specPath,
    required this.outputDir,
    this.options = const OpenApiOptions(),
    this.logger = const Logger(),
  });

  /// Import the OpenAPI spec and generate markdown files
  ///
  /// Throws [OpenApiException] if the spec file is not found, cannot be parsed,
  /// or is not a valid OpenAPI/Swagger spec.
  Future<int> import() async {
    final file = File(specPath);
    if (!file.existsSync()) {
      throw OpenApiException('OpenAPI spec not found: $specPath');
    }

    logger.log('📖 Parsing OpenAPI spec: $specPath');

    final content = await file.readAsString();
    final Map<String, dynamic> spec;

    try {
      if (specPath.endsWith('.yaml') || specPath.endsWith('.yml')) {
        final yaml = loadYaml(content);
        spec = Map<String, dynamic>.from(_convertYaml(yaml) as Map);
      } else {
        spec = jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      throw OpenApiException('Failed to parse OpenAPI spec', e);
    }

    final isOpenApi3 = spec.containsKey('openapi');
    final isSwagger2 = spec.containsKey('swagger');

    if (!isOpenApi3 && !isSwagger2) {
      throw const OpenApiException('Invalid OpenAPI/Swagger spec: missing version field');
    }

    logger.log('   Version: ${isOpenApi3 ? spec['openapi'] : spec['swagger']}');

    final outDir = Directory(outputDir);
    if (!outDir.existsSync()) {
      await outDir.create(recursive: true);
    }

    final info = spec['info'] as Map<String, dynamic>? ?? {};
    final title = info['title'] as String? ?? 'API Reference';
    final description = info['description'] as String?;
    final version = info['version'] as String?;
    final paths = spec['paths'] as Map<String, dynamic>? ?? {};
    final endpointsByTag = <String, List<_Endpoint>>{};
    final untaggedEndpoints = <_Endpoint>[];

    paths.forEach((path, methods) {
      if (methods is! Map) return;

      methods.forEach((method, operation) {
        if (method.toString().startsWith('x-')) return;
        if (operation is! Map) return;

        final endpoint = _parseEndpoint(
          path: path.toString(),
          method: method.toString(),
          operation: Map<String, dynamic>.from(operation),
          spec: spec,
        );

        if (endpoint.deprecated && !options.includeDeprecated) {
          logger.log('   Skipping deprecated: ${endpoint.method} ${endpoint.path}');
          return;
        }

        logger.log('   Found: ${endpoint.method} ${endpoint.path}');

        if (endpoint.tags.isEmpty) {
          untaggedEndpoints.add(endpoint);
        } else {
          for (final tag in endpoint.tags) {
            endpointsByTag.putIfAbsent(tag, () => []).add(endpoint);
          }
        }
      });
    });

    var fileCount = 0;

    switch (options.groupBy) {
      case OpenApiGroupBy.tag:
        await _generateIndexPage(title, description, version, endpointsByTag);
        fileCount++;

        for (final entry in endpointsByTag.entries) {
          await _generateTagPage(entry.key, entry.value, spec);
          fileCount++;
        }

        if (untaggedEndpoints.isNotEmpty) {
          await _generateTagPage('Other', untaggedEndpoints, spec);
          fileCount++;
        }
        break;

      case OpenApiGroupBy.path:
        await _generateIndexPage(title, description, version, endpointsByTag);
        fileCount++;

        final seenEndpoints = <String>{};
        final allEndpoints = <_Endpoint>[];
        for (final endpoint in [
          ...endpointsByTag.values.expand((e) => e),
          ...untaggedEndpoints,
        ]) {
          final key = '${endpoint.method}:${endpoint.path}';
          if (seenEndpoints.add(key)) {
            allEndpoints.add(endpoint);
          }
        }

        final endpointsByPath = <String, List<_Endpoint>>{};
        for (final endpoint in allEndpoints) {
          final pathKey = _pathToKey(endpoint.path);
          endpointsByPath.putIfAbsent(pathKey, () => []).add(endpoint);
        }

        for (final entry in endpointsByPath.entries) {
          await _generatePathPage(entry.key, entry.value, spec);
          fileCount++;
        }
        break;

      case OpenApiGroupBy.none:
        final seenEndpoints = <String>{};
        final allEndpoints = <_Endpoint>[];
        for (final endpoint in [
          ...endpointsByTag.values.expand((e) => e),
          ...untaggedEndpoints,
        ]) {
          final key = '${endpoint.method}:${endpoint.path}';
          if (seenEndpoints.add(key)) {
            allEndpoints.add(endpoint);
          }
        }
        await _generateSinglePage(title, description, version, allEndpoints, spec);
        fileCount++;
        break;
    }

    logger.log('✅ Generated $fileCount API documentation files');
    return fileCount;
  }

  /// Parse a single endpoint from the spec
  _Endpoint _parseEndpoint({
    required String path,
    required String method,
    required Map<String, dynamic> operation,
    required Map<String, dynamic> spec,
  }) {
    final tags = (operation['tags'] as List?)?.cast<String>() ?? <String>[];
    final summary = operation['summary'] as String?;
    final description = operation['description'] as String?;
    final deprecated = operation['deprecated'] as bool? ?? false;
    final parameters = <_Parameter>[];
    _RequestBody? requestBody;
    final paramsList = operation['parameters'] as List? ?? [];

    for (final param in paramsList) {
      if (param is! Map) continue;
      final resolved = Map<String, dynamic>.from(_resolveRef(param, spec) as Map);

      if (resolved['in'] == 'body') {
        final schema = resolved['schema'] as Map<String, dynamic>?;
        if (schema != null) {
          final resolvedSchema = Map<String, dynamic>.from(_resolveRef(schema, spec) as Map);
          requestBody = _RequestBody(
            description: resolved['description'] as String?,
            content: {'application/json': resolvedSchema},
          );
        }
        continue;
      }

      if (resolved['in'] == 'formData') {
        resolved['in'] = 'body';
      }

      parameters.add(_parseParameter(resolved));
    }

    if (requestBody == null) {
      if (operation['requestBody'] case final Map rb) {
        final resolved = _resolveRef(rb, spec);
        requestBody = _parseRequestBody(Map<String, dynamic>.from(resolved as Map), spec);
      }
    }

    final responses = <String, _Response>{};
    final responsesMap = operation['responses'] as Map? ?? {};
    responsesMap.forEach((status, response) {
      if (response is! Map) return;
      final resolved = _resolveRef(response, spec);
      responses[status.toString()] = _parseResponse(Map<String, dynamic>.from(resolved), spec);
    });

    final security = <String>[];
    final securityList = operation['security'] as List? ?? spec['security'] as List? ?? [];
    for (final sec in securityList) {
      if (sec is Map) {
        security.addAll(sec.keys.cast<String>());
      }
    }

    return _Endpoint(
      path: path,
      method: method.toUpperCase(),
      tags: tags,
      summary: summary,
      description: description,
      deprecated: deprecated,
      parameters: parameters,
      requestBody: requestBody,
      responses: responses,
      security: security,
    );
  }

  _Parameter _parseParameter(Map<String, dynamic> param) => _Parameter(
        name: param['name'] as String? ?? '',
        location: param['in'] as String? ?? 'query',
        description: param['description'] as String?,
        required: param['required'] as bool? ?? false,
        schema: param['schema'] as Map<String, dynamic>? ?? {'type': param['type'] ?? 'string'},
      );

  _RequestBody _parseRequestBody(Map<String, dynamic> body, Map<String, dynamic> spec) {
    final description = body['description'] as String?;
    final content = body['content'] as Map<String, dynamic>? ?? {};

    final schemas = <String, Map<String, dynamic>>{};
    content.forEach((mediaType, mediaContent) {
      if (mediaContent is Map && mediaContent['schema'] != null) {
        final resolved = _resolveRef(mediaContent['schema'], spec);
        schemas[mediaType] = Map<String, dynamic>.from(resolved);
      }
    });

    return _RequestBody(
      description: description,
      content: schemas,
    );
  }

  _Response _parseResponse(Map<String, dynamic> response, Map<String, dynamic> spec) {
    final description = response['description'] as String? ?? '';
    final content = response['content'] as Map<String, dynamic>? ?? {};

    final schemas = <String, Map<String, dynamic>>{};
    content.forEach((mediaType, mediaContent) {
      if (mediaContent is Map && mediaContent['schema'] != null) {
        final resolved = _resolveRef(mediaContent['schema'], spec);
        schemas[mediaType] = Map<String, dynamic>.from(resolved);
      }
    });

    return _Response(
      description: description,
      content: schemas,
    );
  }

  /// Resolve $ref references in the spec with circular reference protection
  dynamic _resolveRef(
    dynamic value,
    Map<String, dynamic> spec, [
    Set<String>? visitedRefs,
  ]) {
    if (value is! Map) return value;

    visitedRefs ??= {};

    final ref = value[r'$ref'] as String?;
    if (ref != null) {
      if (visitedRefs.contains(ref)) {
        return {'type': 'object', '_circular': ref};
      }

      final parts = ref.split('/');
      if (parts.isEmpty || parts.first != '#') return value;

      dynamic resolved = spec;
      for (var i = 1; i < parts.length; i++) {
        if (resolved is Map) {
          resolved = resolved[parts[i]];
        } else {
          return value;
        }
      }

      if (resolved == null) return value;

      return _resolveRef(
        resolved,
        spec,
        {...visitedRefs, ref},
      );
    }

    if (value['allOf'] case final List allOf) {
      final merged = <String, dynamic>{};
      final mergedProperties = <String, dynamic>{};
      final mergedRequired = <String>[];

      for (final schema in allOf) {
        if (schema is! Map) continue;
        final resolved = Map<String, dynamic>.from(_resolveRef(schema, spec, visitedRefs));

        if (resolved['properties'] case final Map props) {
          mergedProperties.addAll(Map<String, dynamic>.from(props));
        }

        if (resolved['required'] case final List req) {
          mergedRequired.addAll(req.cast<String>());
        }

        for (final key in resolved.keys) {
          if (key != 'properties' && key != 'required' && key != 'allOf') {
            merged[key] = resolved[key];
          }
        }
      }

      if (mergedProperties.isNotEmpty) {
        merged['properties'] = mergedProperties;
      }
      if (mergedRequired.isNotEmpty) {
        merged['required'] = mergedRequired.toSet().toList();
      }
      merged['type'] ??= 'object';

      return merged;
    }

    if (value['oneOf'] case final List oneOf) {
      if (oneOf.isNotEmpty && oneOf.first is Map) {
        final resolved = _resolveRef(oneOf.first, spec, visitedRefs);
        final result = Map<String, dynamic>.from(resolved as Map);
        result['_oneOf'] = oneOf.length;
        return result;
      }
    }

    if (value['anyOf'] case final List anyOf) {
      if (anyOf.isNotEmpty && anyOf.first is Map) {
        final resolved = _resolveRef(anyOf.first, spec, visitedRefs);
        final result = Map<String, dynamic>.from(resolved as Map);
        result['_anyOf'] = anyOf.length;
        return result;
      }
    }

    return value;
  }

  /// Convert YamlMap/YamlList to regular Dart types recursively
  dynamic _convertYaml(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map((key, value) => MapEntry(key.toString(), _convertYaml(value)));
    }
    if (yaml is YamlList) {
      return yaml.map(_convertYaml).toList();
    }
    if (yaml is Map) {
      return yaml.map((key, value) => MapEntry(key.toString(), _convertYaml(value)));
    }
    if (yaml is List) {
      return yaml.map(_convertYaml).toList();
    }
    return yaml;
  }

  String _pathToKey(String path) => path
      .replaceAll(bracesPattern, '')
      .replaceAll('/', '-')
      .replaceAll(leadingTrailingDashPattern, '')
      .replaceAll(multipleDashPattern, '-');

  String _tagToFilename(String tag) =>
      tag.toLowerCase().replaceAll(nonAlphanumericPattern, '-').replaceAll(leadingTrailingDashPattern, '');

  /// Generate index page
  Future<void> _generateIndexPage(
    String title,
    String? description,
    String? version,
    Map<String, List<_Endpoint>> endpointsByTag,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln('---');
    buffer.writeln('title: $title');
    if (description != null) {
      buffer.writeln('description: ${_escapeYaml(description)}');
    }
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# $title');
    buffer.writeln();

    if (version != null) {
      buffer.writeln('**Version:** $version');
      buffer.writeln();
    }

    if (description != null) {
      buffer.writeln(description);
      buffer.writeln();
    }

    if (endpointsByTag.isNotEmpty) {
      buffer.writeln('## Endpoints');
      buffer.writeln();

      for (final tag in endpointsByTag.keys) {
        final filename = _tagToFilename(tag);
        buffer.writeln('- [$tag](./$filename)');
      }
    }

    final filePath = p.join(outputDir, 'index.md');
    await File(filePath).writeAsString(buffer.toString());
    logger.log('   📄 index.md');
  }

  /// Generate a page for a tag group
  Future<void> _generateTagPage(
    String tag,
    List<_Endpoint> endpoints,
    Map<String, dynamic> spec,
  ) async {
    final buffer = StringBuffer();
    final filename = _tagToFilename(tag);
    String? tagDescription;
    final tags = spec['tags'] as List? ?? [];
    for (final t in tags) {
      if (t is Map && t['name'] == tag) {
        tagDescription = t['description'] as String?;
        break;
      }
    }

    buffer.writeln('---');
    buffer.writeln('title: $tag');
    if (tagDescription != null) {
      buffer.writeln('description: ${_escapeYaml(tagDescription)}');
    }
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# $tag');
    buffer.writeln();

    if (tagDescription != null) {
      buffer.writeln(tagDescription);
      buffer.writeln();
    }

    endpoints.sort((a, b) => a.path.compareTo(b.path));

    for (final endpoint in endpoints) {
      _writeEndpoint(buffer, endpoint, spec);
    }

    final filePath = p.join(outputDir, '$filename.md');
    await File(filePath).writeAsString(buffer.toString());
    logger.log('   📄 $filename.md (${endpoints.length} endpoints)');
  }

  /// Generate a page for a path group
  Future<void> _generatePathPage(
    String pathKey,
    List<_Endpoint> endpoints,
    Map<String, dynamic> spec,
  ) async {
    final buffer = StringBuffer();
    final title = endpoints.first.path;

    buffer.writeln('---');
    buffer.writeln('title: "$title"');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# `$title`');
    buffer.writeln();

    final methodOrder = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
    endpoints.sort((a, b) {
      final aIndex = methodOrder.indexOf(a.method);
      final bIndex = methodOrder.indexOf(b.method);
      return aIndex.compareTo(bIndex);
    });

    for (final endpoint in endpoints) {
      _writeEndpoint(buffer, endpoint, spec);
    }

    final filePath = p.join(outputDir, '$pathKey.md');
    await File(filePath).writeAsString(buffer.toString());
    logger.log('   📄 $pathKey.md (${endpoints.length} methods)');
  }

  /// Generate single page with all endpoints
  Future<void> _generateSinglePage(
    String title,
    String? description,
    String? version,
    List<_Endpoint> endpoints,
    Map<String, dynamic> spec,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln('---');
    buffer.writeln('title: $title');
    if (description != null) {
      buffer.writeln('description: ${_escapeYaml(description)}');
    }
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# $title');
    buffer.writeln();

    if (version != null) {
      buffer.writeln('**Version:** $version');
      buffer.writeln();
    }

    if (description != null) {
      buffer.writeln(description);
      buffer.writeln();
    }

    endpoints.sort((a, b) {
      final pathCompare = a.path.compareTo(b.path);
      if (pathCompare != 0) return pathCompare;
      return a.method.compareTo(b.method);
    });

    for (final endpoint in endpoints) {
      _writeEndpoint(buffer, endpoint, spec);
    }

    final filePath = p.join(outputDir, 'index.md');
    await File(filePath).writeAsString(buffer.toString());
    logger.log('   📄 index.md (${endpoints.length} endpoints)');
  }

  /// Write a single endpoint to the buffer
  void _writeEndpoint(StringBuffer buffer, _Endpoint endpoint, Map<String, dynamic> spec) {
    final authAttr = endpoint.security.isNotEmpty ? ' auth="${endpoint.security.first}"' : '';

    final titleAttr = endpoint.summary != null ? ' title="${_escapeAttr(endpoint.summary!)}"' : '';

    buffer.writeln('<Api method="${endpoint.method}" path="${endpoint.path}"$titleAttr$authAttr>');
    buffer.writeln();

    if (endpoint.deprecated) {
      buffer.writeln('<Warning>');
      buffer.writeln('This endpoint is deprecated.');
      buffer.writeln('</Warning>');
      buffer.writeln();
    }

    if (endpoint.description != null) {
      buffer.writeln(endpoint.description);
      buffer.writeln();
    }

    if (endpoint.parameters.isNotEmpty) {
      buffer.writeln('### Parameters');
      buffer.writeln();

      for (final param in endpoint.parameters) {
        final typeStr = _schemaToType(param.schema);
        final reqAttr = param.required ? ' required' : '';
        final defaultVal = param.schema['default'];
        final defaultAttr = defaultVal != null ? ' default="$defaultVal"' : '';

        buffer.writeln(
            '<ParamField name="${param.name}" type="$typeStr" paramType="${param.location}"$reqAttr$defaultAttr>');
        if (param.description != null) {
          buffer.writeln(param.description);
        }
        buffer.writeln('</ParamField>');
        buffer.writeln();
      }
    }

    if (endpoint.requestBody != null) {
      buffer.writeln('### Request Body');
      buffer.writeln();

      if (endpoint.requestBody!.description != null) {
        buffer.writeln(endpoint.requestBody!.description);
        buffer.writeln();
      }

      for (final entry in endpoint.requestBody!.content.entries) {
        if (endpoint.requestBody!.content.length > 1) {
          buffer.writeln('**${entry.key}:**');
          buffer.writeln();
        }

        _writeSchemaFields(buffer, entry.value, spec, isRequest: true);
      }
    }

    if (endpoint.responses.isNotEmpty) {
      buffer.writeln('### Response');
      buffer.writeln();

      for (final entry in endpoint.responses.entries) {
        final status = entry.key;
        final response = entry.value;

        buffer.writeln('#### $status ${_statusText(status)}');
        buffer.writeln();

        if (response.description.isNotEmpty) {
          buffer.writeln(response.description);
          buffer.writeln();
        }

        for (final contentEntry in response.content.entries) {
          if (response.content.length > 1) {
            buffer.writeln('**${contentEntry.key}:**');
            buffer.writeln();
          }

          _writeSchemaFields(buffer, contentEntry.value, spec, isRequest: false);
        }
      }
    }

    buffer.writeln('</Api>');
    buffer.writeln();
  }

  void _writeSchemaFields(
    StringBuffer buffer,
    Map<String, dynamic> schema,
    Map<String, dynamic> spec, {
    required bool isRequest,
  }) {
    final resolved = _resolveRef(schema, spec);
    if (resolved is! Map) {
      buffer.writeln('Type: `any`');
      buffer.writeln();
      return;
    }
    final resolvedSchema = Map<String, dynamic>.from(resolved);

    if (resolvedSchema['type'] == 'array' && resolvedSchema['items'] != null) {
      final items = resolvedSchema['items'];
      if (items is Map) {
        buffer.writeln('*Returns an array of:*');
        buffer.writeln();
        _writeSchemaFields(buffer, Map<String, dynamic>.from(items), spec, isRequest: isRequest);
      } else {
        buffer.writeln('Type: `array`');
        buffer.writeln();
      }
      return;
    }

    final properties = resolvedSchema['properties'] as Map<String, dynamic>?;
    if (properties == null || properties.isEmpty) {
      final type = _schemaToType(resolvedSchema);
      buffer.writeln('Type: `$type`');
      buffer.writeln();
      return;
    }

    final required = (resolvedSchema['required'] as List?)?.cast<String>() ?? [];

    properties.forEach((name, propSchema) {
      if (propSchema is! Map) return;

      final type = _schemaToType(Map<String, dynamic>.from(propSchema));
      final resolvedProp = _resolveRef(propSchema, spec);
      if (resolvedProp is! Map) return;
      final propMap = Map<String, dynamic>.from(resolvedProp);

      final isRequired = required.contains(name);
      final description = propMap['description'] as String?;
      final nullable = propMap['nullable'] as bool? ?? false;

      if (isRequest) {
        final reqAttr = isRequired ? ' required' : '';
        buffer.writeln('<ParamField name="$name" type="$type" paramType="body"$reqAttr>');
      } else {
        final nullAttr = nullable ? ' nullable="true"' : '';
        buffer.writeln('<ResponseField name="$name" type="$type"$nullAttr>');
      }

      if (description != null) {
        buffer.writeln(description);
      }

      if (isRequest) {
        buffer.writeln('</ParamField>');
      } else {
        buffer.writeln('</ResponseField>');
      }
      buffer.writeln();
    });
  }

  String _schemaToType(Map<String, dynamic> schema) {
    final typeValue = schema['type'];
    final type = typeValue is String ? typeValue : null;
    final formatValue = schema['format'];
    final format = formatValue is String ? formatValue : null;
    final ref = schema[r'$ref'] as String?;

    if (ref != null) {
      final parts = ref.split('/');
      return parts.last;
    }

    if (schema['enum'] case final List enumValues) {
      if (enumValues.isNotEmpty) {
        final firstVal = enumValues.first;
        if (firstVal is String) return 'string';
        if (firstVal is int) return 'integer';
        if (firstVal is num) return 'number';
        if (firstVal is bool) return 'boolean';
      }
    }

    if (type == 'array') {
      final items = schema['items'];
      if (items is Map<String, dynamic>) {
        return '${_schemaToType(items)}[]';
      }
      return 'array';
    }

    if (type == 'object') {
      return 'object';
    }

    if (type != null && format != null && format != type) {
      return '$type<$format>';
    }

    if (type == null && schema.containsKey('properties')) {
      return 'object';
    }

    return type ?? 'any';
  }

  String _escapeYaml(String value) {
    if (value.contains('\n') || value.contains(':') || value.contains('#')) {
      return '"${value.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
    }
    return value;
  }

  String _escapeAttr(String value) => value.replaceAll('"', '&quot;').replaceAll('\n', ' ');

  String _statusText(String status) {
    const statusTexts = {
      '200': 'OK',
      '201': 'Created',
      '204': 'No Content',
      '301': 'Moved Permanently',
      '302': 'Found',
      '304': 'Not Modified',
      '400': 'Bad Request',
      '401': 'Unauthorized',
      '403': 'Forbidden',
      '404': 'Not Found',
      '405': 'Method Not Allowed',
      '409': 'Conflict',
      '422': 'Unprocessable Entity',
      '429': 'Too Many Requests',
      '500': 'Internal Server Error',
      '502': 'Bad Gateway',
      '503': 'Service Unavailable',
    };
    return statusTexts[status] ?? '';
  }
}

/// Configuration options for OpenAPI import
class OpenApiOptions {
  /// How to group endpoints into pages
  final OpenApiGroupBy groupBy;

  /// Include deprecated endpoints
  final bool includeDeprecated;

  const OpenApiOptions({
    this.groupBy = OpenApiGroupBy.tag,
    this.includeDeprecated = true,
  });
}

/// How to group endpoints into pages
enum OpenApiGroupBy {
  /// One page per tag
  tag,

  /// One page per path
  path,

  /// All endpoints in a single page
  none,
}

class _Endpoint {
  final String path;
  final String method;
  final List<String> tags;
  final String? summary;
  final String? description;
  final bool deprecated;
  final List<_Parameter> parameters;
  final _RequestBody? requestBody;
  final Map<String, _Response> responses;
  final List<String> security;

  _Endpoint({
    required this.path,
    required this.method,
    required this.tags,
    this.summary,
    this.description,
    this.deprecated = false,
    this.parameters = const [],
    this.requestBody,
    this.responses = const {},
    this.security = const [],
  });
}

class _Parameter {
  final String name;
  final String location;
  final String? description;
  final bool required;
  final Map<String, dynamic> schema;

  _Parameter({
    required this.name,
    required this.location,
    this.description,
    this.required = false,
    required this.schema,
  });
}

class _RequestBody {
  final String? description;
  final Map<String, Map<String, dynamic>> content;

  _RequestBody({this.description, required this.content});
}

class _Response {
  final String description;
  final Map<String, Map<String, dynamic>> content;

  _Response({required this.description, required this.content});
}
