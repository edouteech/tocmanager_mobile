import 'dart:convert';

class JwtHelper {
  /// Décode le payload d'un token JWT sans dépendance externe
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final payloadBytes = base64Url.decode(normalized);
      final payloadString = utf8.decode(payloadBytes);
      return jsonDecode(payloadString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Récupère la date et l'heure d'expiration du token
  static DateTime? getExpiryDate(String token) {
    final payload = decodePayload(token);
    if (payload == null || !payload.containsKey('exp')) return null;

    final expSec = payload['exp'];
    if (expSec is int) {
      return DateTime.fromMillisecondsSinceEpoch(expSec * 1000, isUtc: true);
    }
    return null;
  }

  /// Calcule la durée restante avant expiration du token
  static Duration? getRemainingTime(String token) {
    final expiry = getExpiryDate(token);
    if (expiry == null) return null;

    final now = DateTime.now().toUtc();
    return expiry.difference(now);
  }

  /// Vérifie si le token expire dans un délai inférieur au seuil indiqué (ex: 5 heures)
  static bool isExpiringWithin(String? token, Duration threshold) {
    if (token == null || token.isEmpty) return true;

    final remaining = getRemainingTime(token);
    if (remaining == null) return true;

    return remaining <= threshold;
  }

  /// Vérifie si le token est déjà expiré
  static bool isExpired(String? token) {
    return isExpiringWithin(token, Duration.zero);
  }
}
