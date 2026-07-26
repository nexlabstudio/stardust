import 'package:shelf/shelf.dart' as shelf;

import '../utils/logger.dart';
import 'mcp_server.dart';

/// The MCP [Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports)
/// over an [McpServer]: a single `/mcp` endpoint answering JSON-RPC POSTs. This
/// is the "run it as a service" path for self-hosters (VPS, on-prem, air-gapped)
/// who want a live endpoint; a pure static host uses the static `llms.json`/`.md`
/// files instead.
///
/// The server is stateless (no `Mcp-Session-Id`) and has no server-initiated
/// messages, so `GET` returns 405. It validates the `Origin` header to prevent
/// DNS-rebinding attacks: loopback origins and non-browser clients (no `Origin`)
/// are always allowed; other browser origins must be listed in [allowedOrigins].
class McpHttpServer {
  /// The single endpoint path clients POST to.
  static const endpoint = 'mcp';

  final McpServer server;

  /// Extra browser origins to accept (exact match, or `*` for any).
  final Set<String> allowedOrigins;
  final Logger logger;

  McpHttpServer(this.server, {Set<String>? allowedOrigins, this.logger = const Logger()})
      : allowedOrigins = allowedOrigins ?? const {};

  Future<shelf.Response> handle(shelf.Request request) async {
    if (request.url.path != endpoint) return shelf.Response.notFound('Not found — POST to /$endpoint.');
    if (!_originAllowed(request.headers['origin'])) return shelf.Response.forbidden('Origin not allowed.');

    return switch (request.method) {
      'POST' => await _post(request),
      // No server-initiated stream, and no sessions to terminate.
      'GET' || 'DELETE' => shelf.Response(405, headers: const {'allow': 'POST'}),
      _ => shelf.Response(405, headers: const {'allow': 'POST'}),
    };
  }

  Future<shelf.Response> _post(shelf.Request request) async {
    final response = await server.handle(await request.readAsString());
    // A JSON-RPC notification/response (no id) yields no reply → 202 Accepted.
    if (response == null) return shelf.Response(202);
    return shelf.Response.ok(response, headers: const {'content-type': 'application/json'});
  }

  bool _originAllowed(String? origin) {
    if (origin == null) return true;
    if (allowedOrigins.contains('*') || allowedOrigins.contains(origin)) return true;
    return switch (Uri.tryParse(origin)?.host) {
      'localhost' || '127.0.0.1' || '::1' => true,
      _ => false,
    };
  }
}
