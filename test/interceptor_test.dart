import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';

import 'helpers/mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = MockAdapter()..enqueueJson(200, {'ok': true});
    dio = mockDio(adapter);
  });

  test('adds a bearer header when a token is stored', () async {
    dio.interceptors.add(JwtAuthInterceptor(InMemoryTokenStorage('abc')));

    await dio.get<dynamic>('https://example.com/wp-json/wp/v2/posts');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });

  test('sends nothing when storage is empty', () async {
    dio.interceptors.add(JwtAuthInterceptor(InMemoryTokenStorage()));

    await dio.get<dynamic>('https://example.com/wp-json/wp/v2/posts');

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('keeps an explicit Authorization header', () async {
    dio.interceptors.add(JwtAuthInterceptor(InMemoryTokenStorage('abc')));

    await dio.get<dynamic>(
      'https://example.com/wp-json/wp/v2/posts',
      options: Options(headers: {'Authorization': 'Basic xyz'}),
    );

    expect(adapter.requests.single.headers['Authorization'], 'Basic xyz');
  });
}
