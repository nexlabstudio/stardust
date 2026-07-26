import 'dart:convert';

import '../utils/logger.dart';
import 'docs_source.dart';

/// A minimal, dependency-free MCP server over the stdio transport: newline-
/// delimited JSON-RPC 2.0 on stdin/stdout, per the MCP spec. It exposes a
/// [DocsSource] through three tools (`list_pages`, `search_docs`, `read_page`)
/// and one resource per page, so a Claude/Cursor user can browse and search a
/// built site's docs.
///
/// The protocol core is [handle] (pure — one request string in, one response
/// string or null out), kept separate from the [serve] IO loop for testing.
class McpServer {
  /// The protocol version advertised when a client doesn't request one.
  static const defaultProtocolVersion = '2025-06-18';

  final DocsSource source;
  final String name;
  final String version;
  final Logger logger;

  McpServer(this.source, {required this.name, this.version = 'dev', this.logger = const Logger()});

  /// Reads one JSON-RPC message per line and writes each response line. Ends
  /// when [input] closes (e.g. the client terminates the subprocess).
  Future<void> serve(Stream<String> input, void Function(String) output) async {
    await for (final line in input) {
      if (line.trim().isEmpty) continue;
      if (await handle(line) case final response?) output(response);
    }
  }

  /// Handles one raw request and returns the response JSON, or null for
  /// notifications (JSON-RPC messages without an `id`).
  Future<String?> handle(String requestJson) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(requestJson);
    } catch (_) {
      return jsonEncode(_error(null, -32700, 'Parse error'));
    }
    if (decoded is! Map) return jsonEncode(_error(null, -32600, 'Invalid Request'));

    final id = decoded['id'];
    final isNotification = !decoded.containsKey('id');
    final params = switch (decoded['params']) {
      final Map params => params,
      _ => const {},
    };

    try {
      final result = await _dispatch(decoded['method'], params);
      if (identical(result, _noResponse) || isNotification) return null;
      return jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result});
    } on _McpError catch (e) {
      return isNotification ? null : jsonEncode(_error(id, e.code, e.message));
    } catch (e) {
      logger.error('mcp: ${decoded['method']} failed: $e');
      return isNotification ? null : jsonEncode(_error(id, -32603, 'Internal error'));
    }
  }

  Future<Object?> _dispatch(Object? method, Map params) async => switch (method) {
        'initialize' => {
            'protocolVersion': switch (params['protocolVersion']) {
              final String requested when requested.isNotEmpty => requested,
              _ => defaultProtocolVersion,
            },
            'capabilities': {'tools': {}, 'resources': {}},
            'serverInfo': {'name': name, 'version': version},
          },
        'notifications/initialized' || 'notifications/cancelled' => _noResponse,
        'ping' => const {},
        'tools/list' => {'tools': _toolDefs},
        'tools/call' => await _callTool(params),
        'resources/list' => {'resources': _resourceDefs()},
        'resources/read' => await _readResource(params),
        _ => throw const _McpError(-32601, 'Method not found'),
      };

  Future<Object?> _callTool(Map params) async {
    final args = switch (params['arguments']) {
      final Map args => args,
      _ => const {},
    };
    switch (params['name']) {
      case 'list_pages':
        final prefix = switch (args['prefix']) {
          final String p when p.isNotEmpty => p,
          _ => '',
        };
        final pages = source.pages.where((page) => page.path.startsWith(prefix)).toList();
        if (pages.isEmpty) return _text(prefix.isEmpty ? 'No pages.' : 'No pages under "$prefix".');
        final buffer = StringBuffer();
        for (final page in pages) {
          buffer.write('- ${page.path} — ${page.title}');
          if (page.description case final desc?) buffer.write(': $desc');
          buffer.writeln();
        }
        return _text(buffer.toString().trimRight());
      case 'search_docs':
        if (args['query'] case final String query when query.trim().isNotEmpty) {
          final limit = switch (args['limit']) {
            final int n when n > 0 => n,
            _ => 10,
          };
          final hits = await source.search(query, limit: limit);
          if (hits.isEmpty) return _text('No results for "$query".');
          final buffer = StringBuffer();
          for (final hit in hits) {
            buffer.writeln('## ${hit.page.title}  (${hit.page.path})');
            if (hit.snippet.isNotEmpty) buffer.writeln(hit.snippet);
            buffer.writeln();
          }
          return _text(buffer.toString().trimRight());
        }
        return _text('Provide a non-empty "query".', isError: true);
      case 'read_page':
        if (args['path'] case final String path when path.isNotEmpty) {
          return switch (await source.readPage(path)) {
            final String md => _text(md),
            null => _text('No page at "$path".', isError: true),
          };
        }
        return _text('Provide a "path", e.g. /introduction.', isError: true);
      default:
        throw const _McpError(-32602, 'Unknown tool');
    }
  }

  Future<Object?> _readResource(Map params) async {
    if (params['uri'] case final String uri) {
      final path = uri.startsWith(_uriScheme) ? uri.substring(_uriScheme.length) : uri;
      return switch (await source.readPage(path)) {
        final String md => {
            'contents': [
              {'uri': uri, 'mimeType': 'text/markdown', 'text': md},
            ],
          },
        null => throw _McpError(-32602, 'Resource not found: $uri'),
      };
    }
    throw const _McpError(-32602, 'Missing uri');
  }

  List<Map<String, Object?>> _resourceDefs() => [
        for (final page in source.pages)
          {
            'uri': '$_uriScheme${page.path}',
            'name': page.title,
            if (page.description case final desc?) 'description': desc,
            'mimeType': 'text/markdown',
          },
      ];

  static Map<String, Object?> _text(String text, {bool isError = false}) => {
        'content': [
          {'type': 'text', 'text': text},
        ],
        if (isError) 'isError': true,
      };

  static Map<String, Object?> _error(Object? id, int code, String message) => {
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': code, 'message': message}
      };

  static const _uriScheme = 'stardust://';

  static final Object _noResponse = Object();

  static const _toolDefs = [
    {
      'name': 'list_pages',
      'description': 'List the documentation pages (path, title, description) — the table of contents. '
          'Optionally filter by a path prefix. Use read_page to fetch a page by its path.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'prefix': {
            'type': 'string',
            'description': 'Only list pages whose path starts with this prefix, e.g. /features'
          },
        },
      },
    },
    {
      'name': 'search_docs',
      'description': 'Full-text search across the documentation. Returns matching pages with a snippet and '
          'their path; use read_page to fetch a page\'s full markdown.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Search terms'},
          'limit': {'type': 'integer', 'description': 'Maximum number of results (default 10)'},
        },
        'required': ['query'],
      },
    },
    {
      'name': 'read_page',
      'description': 'Return the full markdown source of a documentation page by its path (e.g. "/introduction").',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'Page path, e.g. /introduction'},
        },
        'required': ['path'],
      },
    },
  ];
}

class _McpError implements Exception {
  final int code;
  final String message;

  const _McpError(this.code, this.message);
}
