import 'package:test/test.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';

import 'helpers/mock_adapter.dart';

void main() {
  test('decodes the plugin payload and parses the string user id', () {
    final claims = JwtClaims.decode(fakeToken(userId: '13', exp: 1800000000));

    expect(claims.issuer, 'https://example.com');
    expect(claims.userId, 13);
    expect(claims.expiresAt, DateTime.utc(2027, 1, 15, 8, 0));
    expect(claims.issuedAt, isNotNull);
    expect(claims.notBefore, isNotNull);
    expect(claims.raw['data'], isA<Map<String, dynamic>>());
  });

  test('accepts an integer user id', () {
    expect(JwtClaims.decode(fakeToken(userId: 7)).userId, 7);
  });

  test('isExpired follows exp', () {
    final past = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;
    expect(JwtClaims.decode(fakeToken(exp: past)).isExpired, isTrue);
    expect(JwtClaims.decode(fakeToken()).isExpired, isFalse);
  });

  test('tryDecode returns null for garbage', () {
    expect(JwtClaims.tryDecode('not-a-token'), isNull);
    expect(JwtClaims.tryDecode('a.b.c'), isNull);
    expect(() => JwtClaims.decode('a.b'), throwsFormatException);
  });
}
