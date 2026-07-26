import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stardust/src/core/file_system.dart';
import 'package:stardust/src/mcp/docs_source.dart';
import 'package:stardust/src/mcp/mcp_server.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

/// Wraps a [MockFileSystem] but throws on `readFile` for paths ending in
/// [throwFor] — so a manifest can load yet a page body read blows up.
class _ReadThrowsFileSystem implements FileSystem {
  final MockFileSystem inner;
  final String throwFor;

  _ReadThrowsFileSystem(this.inner, this.throwFor);

  @override
  Future<String> readFile(String path) async {
    if (path.replaceAll('\\', '/').endsWith(throwFor)) throw const FileSystemException('boom');
    return inner.readFile(path);
  }

  @override
  Future<bool> fileExists(String path) => inner.fileExists(path);
  @override
  Future<bool> directoryExists(String path) => inner.directoryExists(path);
  @override
  Future<Uint8List> readFileBytes(String path) => inner.readFileBytes(path);
  @override
  Future<void> writeFile(String path, String content) => inner.writeFile(path, content);
  @override
  Future<void> writeFileBytes(String path, Uint8List bytes) => inner.writeFileBytes(path, bytes);
  @override
  Future<void> copyFile(String source, String destination) => inner.copyFile(source, destination);
  @override
  Stream<FileSystemEntity> listDirectory(String path, {bool recursive = false}) =>
      inner.listDirectory(path, recursive: recursive);
  @override
  Future<DateTime> lastModified(String path) => inner.lastModified(path);
  @override
  Future<void> createDirectory(String path, {bool recursive = false}) =>
      inner.createDirectory(path, recursive: recursive);
  @override
  Future<void> deleteDirectory(String path, {bool recursive = false}) =>
      inner.deleteDirectory(path, recursive: recursive);
}

Future<McpServer> _server() async {
  final fs = MockFileSystem()
    ..addFile(
        'site/llms.json',
        '{"name":"Acme Docs","pages":['
            '{"path":"/","title":"Home","description":"Landing.","md":"/index.md"},'
            '{"path":"/guide","title":"User Guide","md":"/guide.md"}]}')
    ..addFile('site/index.md', 'Welcome home.')
    ..addFile('site/guide.md', 'A guide about widgets.');
  final source = await DocsSource.load('site', fileSystem: fs);
  return McpServer(source, name: source.siteName, version: '1.2.3');
}

/// Sends one request and decodes the JSON-RPC response (fails if none).
Future<Map<String, dynamic>> _call(McpServer server, Map<String, dynamic> request) async {
  final raw = await server.handle(jsonEncode(request));
  expect(raw, isNotNull, reason: 'expected a response for ${request['method']}');
  return jsonDecode(raw as String) as Map<String, dynamic>;
}

void main() {
  group('initialize', () {
    test('echoes the requested protocol version and advertises capabilities', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {'protocolVersion': '2025-11-25'},
      });

      final result = res['result'] as Map;
      expect(result['protocolVersion'], '2025-11-25');
      expect((result['capabilities'] as Map).keys, containsAll(<String>['tools', 'resources']));
      expect(result['serverInfo'], {'name': 'Acme Docs', 'version': '1.2.3'});
    });

    test('falls back to the default protocol version when none is requested', () async {
      final server = await _server();
      final res = await _call(server, {'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {}});
      expect((res['result'] as Map)['protocolVersion'], McpServer.defaultProtocolVersion);
    });
  });

  group('notifications', () {
    test('notifications/initialized produces no response', () async {
      final server = await _server();
      expect(await server.handle(jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/initialized'})), isNull);
    });

    test('an unknown notification (no id) produces no response', () async {
      final server = await _server();
      expect(await server.handle(jsonEncode({'jsonrpc': '2.0', 'method': 'x/unknown'})), isNull);
    });
  });

  group('tools', () {
    test('tools/list advertises list_pages, search_docs, and read_page with input schemas', () async {
      final server = await _server();
      final res = await _call(server, {'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'});

      final tools = ((res['result'] as Map)['tools'] as List).cast<Map>();
      expect(tools.map((t) => t['name']), containsAll(<String>['list_pages', 'search_docs', 'read_page']));
      expect(tools.every((t) => t['inputSchema'] is Map), isTrue);
    });

    test('tools/call list_pages returns the full catalog, and a prefix filters it', () async {
      final server = await _server();

      final all = await _call(server, {
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/call',
        'params': {'name': 'list_pages', 'arguments': {}},
      });
      final allText = ((all['result'] as Map)['content'] as List).first['text'] as String;
      expect(allText, contains('/ — Home'));
      expect(allText, contains('/guide — User Guide'));

      final filtered = await _call(server, {
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'tools/call',
        'params': {
          'name': 'list_pages',
          'arguments': {'prefix': '/guide'}
        },
      });
      final filteredText = ((filtered['result'] as Map)['content'] as List).first['text'] as String;
      expect(filteredText, contains('/guide — User Guide'));
      expect(filteredText, isNot(contains('/ — Home')));
    });

    test('tools/call search_docs returns a text hit', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'tools/call',
        'params': {
          'name': 'search_docs',
          'arguments': {'query': 'widgets'}
        },
      });

      final content = ((res['result'] as Map)['content'] as List).cast<Map>();
      expect(content.single['type'], 'text');
      expect(content.single['text'], contains('/guide'));
      expect((res['result'] as Map).containsKey('isError'), isFalse);
    });

    test('tools/call search_docs with no results reports so (not an error)', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'tools/call',
        'params': {
          'name': 'search_docs',
          'arguments': {'query': 'zzzznotfound'}
        },
      });
      final result = res['result'] as Map;
      expect((result['content'] as List).first['text'], contains('No results'));
      expect(result.containsKey('isError'), isFalse);
    });

    test('tools/call search_docs with empty query is a tool error', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'tools/call',
        'params': {
          'name': 'search_docs',
          'arguments': {'query': '  '}
        },
      });
      expect((res['result'] as Map)['isError'], isTrue);
    });

    test('tools/call read_page returns the page markdown', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'tools/call',
        'params': {
          'name': 'read_page',
          'arguments': {'path': '/guide'}
        },
      });
      expect(((res['result'] as Map)['content'] as List).first['text'], 'A guide about widgets.');
    });

    test('tools/call read_page for a missing page is a tool error', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'tools/call',
        'params': {
          'name': 'read_page',
          'arguments': {'path': '/nope'}
        },
      });
      expect((res['result'] as Map)['isError'], isTrue);
    });

    test('tools/call read_page with an empty path is a tool error', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'tools/call',
        'params': {
          'name': 'read_page',
          'arguments': {'path': ''}
        },
      });
      expect((res['result'] as Map)['isError'], isTrue);
    });

    test('an unexpected error while serving a tool surfaces as JSON-RPC -32603', () async {
      // Manifest loads fine, but reading the page body throws — exercising the
      // internal-error fallback.
      final fs = MockFileSystem()
        ..addFile('site/llms.json', '{"name":"X","pages":[{"path":"/boom","title":"Boom","md":"/boom.md"}]}')
        ..addFile('site/boom.md', 'body');
      final source = await DocsSource.load('site', fileSystem: _ReadThrowsFileSystem(fs, 'boom.md'));
      final server = McpServer(source, name: 'X');

      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'tools/call',
        'params': {
          'name': 'read_page',
          'arguments': {'path': '/boom'}
        },
      });
      expect((res['error'] as Map)['code'], -32603);
    });
  });

  group('resources', () {
    test('resources/list exposes one markdown resource per page', () async {
      final server = await _server();
      final res = await _call(server, {'jsonrpc': '2.0', 'id': 5, 'method': 'resources/list'});

      final resources = ((res['result'] as Map)['resources'] as List).cast<Map>();
      expect(resources.map((r) => r['uri']), ['stardust:///', 'stardust:///guide']);
      expect(resources.every((r) => r['mimeType'] == 'text/markdown'), isTrue);
    });

    test('resources/read returns the page contents by uri', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 6,
        'method': 'resources/read',
        'params': {'uri': 'stardust:///guide'},
      });
      final contents = ((res['result'] as Map)['contents'] as List).cast<Map>();
      expect(contents.single['uri'], 'stardust:///guide');
      expect(contents.single['text'], 'A guide about widgets.');
    });

    test('resources/read for an unknown uri returns a JSON-RPC error', () async {
      final server = await _server();
      final res = await _call(server, {
        'jsonrpc': '2.0',
        'id': 6,
        'method': 'resources/read',
        'params': {'uri': 'stardust:///nope'},
      });
      expect((res['error'] as Map)['code'], -32602);
    });
  });

  group('protocol basics', () {
    test('ping returns an empty result', () async {
      final server = await _server();
      final res = await _call(server, {'jsonrpc': '2.0', 'id': 7, 'method': 'ping'});
      expect(res['result'], isEmpty);
    });

    test('an unknown method (with id) returns method-not-found', () async {
      final server = await _server();
      final res = await _call(server, {'jsonrpc': '2.0', 'id': 8, 'method': 'does/notexist'});
      expect((res['error'] as Map)['code'], -32601);
    });

    test('invalid json returns a parse error with null id', () async {
      final server = await _server();
      final res = jsonDecode((await server.handle('{ not json')) as String) as Map;
      expect((res['error'] as Map)['code'], -32700);
      expect(res['id'], isNull);
    });
  });

  group('serve loop', () {
    test('reads newline-delimited requests and writes each response, skipping notifications', () async {
      final server = await _server();
      final input = Stream.fromIterable([
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'}),
        '', // blank line ignored
        jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/initialized'}), // no response
        jsonEncode({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'}),
      ]);
      final out = <String>[];
      await server.serve(input, out.add);

      expect(out, hasLength(2));
      expect((jsonDecode(out[0]) as Map)['id'], 1);
      expect((jsonDecode(out[1]) as Map)['id'], 2);
    });
  });
}
