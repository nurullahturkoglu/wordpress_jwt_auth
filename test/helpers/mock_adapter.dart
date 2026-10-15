import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef Responder = ResponseBody Function(RequestOptions options);

/// Replaces Dio's HTTP layer with queued, scripted responses.
class MockAdapter implements HttpClientAdapter {
  final Queue<Responder> _queue = Queue();
  final List<RequestOptions> requests = [];

  void enqueue(Responder responder) => _queue.add(responder);

  void enqueueJson(int status, Object body) =>
      enqueue((_) => jsonResponse(status, body));

  void enqueueFailure(Object error) => enqueue((_) => throw error);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_queue.isEmpty) {
      throw StateError(
        'No response queued for ${options.method} ${options.uri}',
      );
    }
    return _queue.removeFirst()(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody htmlResponse(int status, String html) => ResponseBody.fromString(
  html,
  status,
  headers: {
    Headers.contentTypeHeader: ['text/html; charset=UTF-8'],
  },
);

Dio mockDio(MockAdapter adapter) => Dio()..httpClientAdapter = adapter;

/// Builds an unsigned JWT with the plugin's payload shape.
String fakeToken({
  Object userId = '13',
  int? exp,
  String issuer = 'https://example.com',
}) {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final payload = {
    'iss': issuer,
    'iat': now,
    'nbf': now,
    'exp': exp ?? now + 7 * 24 * 3600,
    'data': {
      'user': {'id': userId},
    },
  };
  String encode(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${encode({'typ': 'JWT', 'alg': 'HS256'})}.${encode(payload)}.sig';
}

Map<String, Object> wpError(String code, String message, int status) => {
  'code': code,
  'message': message,
  'data': {'status': status},
};
