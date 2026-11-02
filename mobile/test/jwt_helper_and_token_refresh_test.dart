import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tocmanager/utils/jwt_helper.dart';

void main() {
  group('JwtHelper Tests', () {
    String generateMockJwt({required Duration expiresIn}) {
      final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
      final exp = (DateTime.now().toUtc().add(expiresIn).millisecondsSinceEpoch ~/ 1000);
      final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': 'test-user', 'exp': exp})));
      return '$header.$payload.mock_signature';
    }

    test('isExpiringWithin detects token expiring in less than 5 hours', () {
      // Token expiring in 4 hours
      final token4h = generateMockJwt(expiresIn: const Duration(hours: 4));
      expect(JwtHelper.isExpiringWithin(token4h, const Duration(hours: 5)), isTrue);

      // Token expiring in 10 hours
      final token10h = generateMockJwt(expiresIn: const Duration(hours: 10));
      expect(JwtHelper.isExpiringWithin(token10h, const Duration(hours: 5)), isFalse);
    });

    test('isExpiringWithin detects refresh token expiring in less than 10 hours', () {
      // Refresh token expiring in 8 hours
      final token8h = generateMockJwt(expiresIn: const Duration(hours: 8));
      expect(JwtHelper.isExpiringWithin(token8h, const Duration(hours: 10)), isTrue);

      // Refresh token expiring in 48 hours
      final token48h = generateMockJwt(expiresIn: const Duration(hours: 48));
      expect(JwtHelper.isExpiringWithin(token48h, const Duration(hours: 10)), isFalse);
    });

    test('isExpired detects already expired tokens', () {
      final expiredToken = generateMockJwt(expiresIn: const Duration(minutes: -1));
      expect(JwtHelper.isExpired(expiredToken), isTrue);

      final validToken = generateMockJwt(expiresIn: const Duration(hours: 24));
      expect(JwtHelper.isExpired(validToken), isFalse);
    });

    test('Handles malformed or null tokens gracefully without throwing', () {
      expect(JwtHelper.isExpiringWithin(null, const Duration(hours: 5)), isTrue);
      expect(JwtHelper.isExpiringWithin('', const Duration(hours: 5)), isTrue);
      expect(JwtHelper.isExpiringWithin('invalid.jwt', const Duration(hours: 5)), isTrue);
      expect(JwtHelper.getExpiryDate('garbage'), isNull);
    });
  });
}
