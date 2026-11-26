import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../database/database_helper.dart';
import '../services/secure_storage_service.dart';
import '../services/api_client.dart';
import '../services/network_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final http.Client? _httpClient;

  AuthProvider({http.Client? httpClient}) : _httpClient = httpClient;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isPinLocked = false;
  bool get isPinLocked => _isPinLocked;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  int _pinAttemptsRemaining = 3;
  int get pinAttemptsRemaining => _pinAttemptsRemaining;
  bool get isPinBlocked => _pinAttemptsRemaining <= 0;

  int _expectedPinLength = 4;
  int get expectedPinLength => _expectedPinLength;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Initialisation au démarrage de l'app (Splash / vérification locale)
  Future<void> checkInitialSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await SecureStorageService.getUser();
      final token = await SecureStorageService.getAccessToken();
      final hasPin = await SecureStorageService.hasPinConfigured();

      if (user != null && token != null) {
        if (user.isSuperAdmin) {
          await SecureStorageService.clearSession();
          _isAuthenticated = false;
          _isPinLocked = false;
          _currentUser = null;
        } else {
          _currentUser = user;
          _isAuthenticated = true;
          _expectedPinLength = await SecureStorageService.getPinLength();
          _isPinLocked = hasPin;
          unawaited(ApiClient.instance.checkAndProactiveRefresh());
        }
      } else {
        _isAuthenticated = false;
        _isPinLocked = false;
        _currentUser = null;
      }
    } catch (_) {
      _isAuthenticated = false;
      _isPinLocked = false;
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Déverrouillage local hors-ligne avec le code PIN
  Future<bool> unlockWithPin(String pin) async {
    if (_pinAttemptsRemaining <= 0) {
      _errorMessage = 'Trop de tentatives erronées. Veuillez vous reconnecter avec votre mot de passe.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;

    final isValid = await SecureStorageService.verifyPin(pin);
    if (isValid) {
      _isPinLocked = false;
      _pinAttemptsRemaining = 3;
      notifyListeners();

      unawaited(ApiClient.instance.checkAndProactiveRefresh());
      final boutiqueId = await SecureStorageService.getCurrentBoutiqueId();
      final magasinId = await SecureStorageService.getCurrentMagasinId();
      final isCons = await SecureStorageService.isConsolidatedMode();
      if (boutiqueId != null && (isCons || magasinId != null)) {
        unawaited(SyncService.instance.syncNow());
      }

      return true;
    } else {
      _pinAttemptsRemaining = (_pinAttemptsRemaining - 1).clamp(0, 3);
      if (_pinAttemptsRemaining == 0) {
        await SecureStorageService.clearPinAndTokens();
        _errorMessage = 'Trop de tentatives erronées. Veuillez vous reconnecter avec votre mot de passe.';
      } else {
        _errorMessage = 'Code PIN incorrect ($_pinAttemptsRemaining tentative(s) restante(s)).';
      }
      notifyListeners();
      return false;
    }
  }

  /// Connexion en ligne avec nom d'utilisateur/email et mot de passe
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
    String? serverUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final baseUrl = serverUrl ?? await SecureStorageService.getServerUrl();
      if (serverUrl != null) {
        await SecureStorageService.setServerUrl(serverUrl);
      }

      final uri = Uri.parse('$baseUrl/auth/login');
      final client = _httpClient;
      final postFuture = client != null
          ? client.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username_or_email': usernameOrEmail.trim(),
                'password': password,
              }),
            )
          : http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username_or_email': usernameOrEmail.trim(),
                'password': password,
              }),
            );
      final response = await postFuture.timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = AppUser.fromMap(data['user'] as Map<String, dynamic>);

        if (user.isSuperAdmin) {
          _errorMessage = 'Les comptes SuperAdmin doivent utiliser l\'interface web /admin.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;

        await SecureStorageService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await SecureStorageService.saveUser(user);

        _currentUser = user;
        _isAuthenticated = true;
        _isPinLocked = false;
        _pinAttemptsRemaining = 3;
        _expectedPinLength = await SecureStorageService.getPinLength();
        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Échec de la connexion (Code ${response.statusCode})';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Impossible de joindre le serveur. Vérifiez votre connexion ou l\'adresse API.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Enregistrement du code PIN
  Future<void> setLocalPin(String pin) async {
    await SecureStorageService.savePin(pin);
    _expectedPinLength = pin.trim().length;
    notifyListeners();
  }

  /// Déconnexion avec synchronisation best-effort et purge locale complète
  Future<void> logout({bool trySyncFirst = true}) async {
    if (trySyncFirst && NetworkService.instance.isOnline) {
      try {
        final pending = await SyncService.instance.getPendingQueueCount();
        if (pending > 0) {
          await SyncService.instance.syncNow();
        }
      } catch (_) {}
    }

    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final accessToken = await SecureStorageService.getAccessToken();
        final baseUrl = await SecureStorageService.getServerUrl();
        final uri = Uri.parse('$baseUrl/auth/logout');
        final headers = {
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
        };
        final payload = jsonEncode({'refresh_token': refreshToken});
        final client = _httpClient;
        final logoutFuture = client != null
            ? client.post(uri, headers: headers, body: payload)
            : http.post(uri, headers: headers, body: payload);
        await logoutFuture.timeout(const Duration(seconds: 5));
      }
    } catch (_) {}

    await DatabaseHelper.instance.clearAllBusinessData();
    await SecureStorageService.clearSession();
    _currentUser = null;
    _isAuthenticated = false;
    _isPinLocked = false;
    _pinAttemptsRemaining = 3;
    _expectedPinLength = 4;
    _errorMessage = null;
    notifyListeners();
  }
}
