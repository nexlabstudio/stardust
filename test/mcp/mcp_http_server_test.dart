import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:stardust/src/mcp/docs_source.dart';
import 'package:stardust/src/mcp/mcp_http_server.dart';
import 'package:stardust/src/mcp/mcp_server.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';

Future<McpHttpServer> _http({Set<String>? allowedOrigins}) async {
  final fs = MockFileSystem()
    ..addFile('site/llms.json', '{"name":"Acme","pages":[{"path":"/","title":"Home","md":"/index.md"}]}')
    ..addFile('site/index.md', 'Welcome home.');
  final source = await DocsSource.load('site', fileSystem: fs);
  return McpHttpServer(McpServer(source, name: source.siteName), allowedOrigins: allowedOrigins);
}

shelf.Request _req(String method, {String path = '/mcp', Map<String, String>? headers, Object? body}) => shelf.Request(
      method,
      Uri.parse('http://localhost:8080$path'),
      headers: headers,
      body: body is Map ? jsonEncode(body) : body,
    );

void main() {
  group('POST /mcp', () {
    test('a JSON-RPC request gets a 200 application/json response', () async {
      final server = await _http();
      final res = await server.handle(_req('POST', body: {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'}));

      expect(res.statusCode, 200);
      expect(res.headers['content-type'], contains('application/json'));
      expect((jsonDecode(await res.readAsString()) as Map)['id'], 1);
    });

    test('a notification (no id) gets 202 Accepted with no body', () async {
      final server = await _http();
      final res = await server.handle(_req('POST', body: {'jsonrpc': '2.0', 'method': 'notifications/initialized'}));

      expect(res.statusCode, 202);
      expect(await res.readAsString(), isEmpty);
    });

    test('initialize round-trips over HTTP', () async {
      final server = await _http();
      final res =
          await server.handle(_req('POST', body: {'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {}}));
      final result = (jsonDecode(await res.readAsString()) as Map)['result'] as Map;
      expect(result['serverInfo'], {'name': 'Acme', 'version': 'dev'});
    });
  });

  group('method and path handling', () {
    test('GET /mcp is 405 (no server-initiated stream)', () async {
      final server = await _http();
      final res = await server.handle(_req('GET'));
      expect(res.statusCode, 405);
      expect(res.headers['allow'], 'POST');
    });

    test('DELETE /mcp is 405 (stateless, no sessions)', () async {
      final server = await _http();
      expect((await server.handle(_req('DELETE'))).statusCode, 405);
    });

    test('a wrong path is 404', () async {
      final server = await _http();
      expect((await server.handle(_req('POST', path: '/'))).statusCode, 404);
    });
  });

  group('Origin validation (DNS-rebinding guard)', () {
    Future<int> status(McpHttpServer server, String? origin) async {
      final res = await server.handle(_req('POST',
          headers: origin == null ? null : {'origin': origin}, body: {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'}));
      return res.statusCode;
    }

    test('requests with no Origin (native clients) are allowed', () async {
      expect(await status(await _http(), null), 200);
    });

    test('loopback origins are allowed', () async {
      final server = await _http();
      expect(await status(server, 'http://localhost:3000'), 200);
      expect(await status(server, 'http://127.0.0.1:9999'), 200);
    });

    test('a foreign browser origin is rejected with 403', () async {
      expect(await status(await _http(), 'https://evil.example.com'), 403);
    });

    test('an explicitly allowed origin passes', () async {
      final server = await _http(allowedOrigins: {'https://docs.acme.dev'});
      expect(await status(server, 'https://docs.acme.dev'), 200);
    });

    test('a wildcard allows any origin', () async {
      final server = await _http(allowedOrigins: {'*'});
      expect(await status(server, 'https://anything.example.com'), 200);
    });
  });
}
