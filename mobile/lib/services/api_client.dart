import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/jwt_helper.dart';
import 'secure_storage_service.dart';

/// Client HTTP intelligent pour Flutter avec :
/// 1. Rafraîchissement proactif si le token expire dans moins de 5 heures.
/// 2. Interception automatique des erreurs 401 avec mutex et retry transparent.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();

  Completer<bool>? _refreshCompleter;

  /// Vérifie proactivement l'état des jetons et déclenche un renouvellement si nécessaire :
  /// - Access Token : rafraîchi si expiration dans < 5 heures
  /// - Refresh Token : renouvelé si expiration dans < 10 heures
  Future<bool> checkAndProactiveRefresh() async {
    final accessToken = await SecureStorageService.getAccessToken();
    final refreshToken = await SecureStorageService.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final accessNeedsRefresh = JwtHelper.isExpiringWithin(accessToken, const Duration(hours: 5));
    final refreshNeedsRefresh = JwtHelper.isExpiringWithin(refreshToken, const Duration(hours: 10));

    if (accessNeedsRefresh || refreshNeedsRefresh) {
      debugPrint('[ApiClient] Rafraîchissement proactif déclenché (Access < 5h ou Refresh < 10h)');
      return await refreshTokens();
    }

    return true;
  }

  /// Rafraîchissement sécurisé des tokens avec verrou (Mutex) anti-concurrence
  Future<bool> refreshTokens() async {
    // Si un rafraîchissement est déjà en cours, attendre sa fin
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final baseUrl = await SecureStorageService.getServerUrl();
      final refreshToken = await SecureStorageService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        return false;
      }

      final url = Uri.parse('$baseUrl/auth/refresh');
      final res = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = (data['refresh_token'] as String?) ?? refreshToken;

        await SecureStorageService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        debugPrint('[ApiClient] Tokens renouvelés avec succès via rotation glissante');
        _refreshCompleter!.complete(true);
        _refreshCompleter = null;
        return true;
      } else {
        debugPrint('[ApiClient] Échec du rafraîchissement (${res.statusCode}): ${res.body}');
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        return false;
      }
    } catch (e) {
      debugPrint('[ApiClient] Erreur réseau lors du rafraîchissement des tokens: $e');
      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      return false;
    }
  }

  /// Exécute une requête GET authentifiée avec interception 401 et retry
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return _sendWithRetry(
      () => _buildHeaders(headers),
      (h) => _httpClient.get(url, headers: h).timeout(timeout),
    );
  }

  /// Exécute une requête POST authentifiée avec interception 401 et retry
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return _sendWithRetry(
      () => _buildHeaders(headers),
      (h) => _httpClient.post(url, headers: h, body: body).timeout(timeout),
    );
  }

  /// Exécute une requête PUT authentifiée avec interception 401 et retry
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return _sendWithRetry(
      () => _buildHeaders(headers),
      (h) => _httpClient.put(url, headers: h, body: body).timeout(timeout),
    );
  }

  /// Exécute une requête DELETE authentifiée avec interception 401 et retry
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return _sendWithRetry(
      () => _buildHeaders(headers),
      (h) => _httpClient.delete(url, headers: h).timeout(timeout),
    );
  }

  /// Construit les headers par défaut en injectant le Bearer token
  Future<Map<String, String>> _buildHeaders(Map<String, String>? customHeaders) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?customHeaders,
    };

    final token = await SecureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Cœur de l'orchestration : vérification préventive à 5h + retry automatique sur 401
  Future<http.Response> _sendWithRetry(
    Future<Map<String, String>> Function() headersBuilder,
    Future<http.Response> Function(Map<String, String> headers) requestExecutor,
  ) async {
    // 1. Contrôle proactif (expiration dans < 5 heures)
    await checkAndProactiveRefresh();

    var headers = await headersBuilder();
    var response = await requestExecutor(headers);

    // 2. Si 401 Unauthorized reçu, intercepter et tenter un rafraîchissement + replay
    if (response.statusCode == 401) {
      debugPrint('[ApiClient] 401 Unauthorized détecté sur ${response.request?.url}. Tentative de rafraîchissement...');
      
      final refreshed = await refreshTokens();
      if (refreshed) {
        debugPrint('[ApiClient] Jeton renouvelé avec succès. Rejeu de la requête initiale...');
        headers = await headersBuilder();
        response = await requestExecutor(headers);
      } else {
        debugPrint('[ApiClient] Impossible de rafraîchir le token. L\'utilisateur doit se réauthentifier.');
      }
    }

    return response;
  }
}
