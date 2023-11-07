import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

import 'src/options.dart';

class Dhttpd {
  final HttpServer _server;
  final String path;

  Dhttpd._(this._server, this.path);

  String get host => _server.address.host;

  int get port => _server.port;

  String get urlBase => 'http://$host:$port/';

  /// [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [start] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  static Future<Dhttpd> start({
    String? path,
    int port = defaultPort,
    Object address = defaultHost,
  }) async {
    path ??= Directory.current.path;

    var inner = createStaticHandler(path, defaultDocument: 'index.html');

    final wrapper = (Request request) async {
      var response = await inner(request);
      return response.change(headers: {
        "Cross-Origin-Embedder-Policy": "require-corp",
        "Cross-Origin-Opener-Policy": "same-origin"
      });
    };

    final pipeline =
        const Pipeline().addMiddleware(logRequests()).addHandler(wrapper);

    final server = await io.serve(pipeline, address, port);
    return Dhttpd._(server, path);
  }

  Future<void> destroy() => _server.close();
}
