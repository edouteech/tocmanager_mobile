import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/secure_storage_service.dart';
import '../services/api_client.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
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
        _currentUser = user;
        _isAuthenticated = true;
        _isPinLocked = hasPin; // Verrouillé par PIN au démarrage si configuré
        unawaited(ApiClient.instance.checkAndProactiveRefresh());
        unawaited(SyncService.instance.syncNow());
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
    _errorMessage = null;

    final isValid = await SecureStorageService.verifyPin(pin);
    if (isValid) {
      _isPinLocked = false;
      _pinAttemptsRemaining = 3;
      notifyListeners();

      // Contrôle proactif au déverrouillage PIN :
      // - Si access token expire dans < 5h : rafraîchi
      // - Si refresh token expire dans < 10h : renouvelé
      unawaited(ApiClient.instance.checkAndProactiveRefresh());
      unawaited(SyncService.instance.syncNow());

      return true;
    } else {
      _pinAttemptsRemaining--;
      if (_pinAttemptsRemaining <= 0) {
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
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username_or_email': usernameOrEmail.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        final user = AppUser.fromMap(data['user'] as Map<String, dynamic>);

        await SecureStorageService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await SecureStorageService.saveUser(user);

        _currentUser = user;
        _isAuthenticated = true;
        _isPinLocked = false;
        _pinAttemptsRemaining = 3;
        _isLoading = false;
        notifyListeners();

        // Lancement immédiat de la synchronisation après connexion réussie
        unawaited(SyncService.instance.syncNow());

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
    notifyListeners();
  }

  /// Déconnexion
  Future<void> logout() async {
    await SecureStorageService.clearSession();
    _currentUser = null;
    _isAuthenticated = false;
    _isPinLocked = false;
    _pinAttemptsRemaining = 3;
    _errorMessage = null;
    notifyListeners();
  }
}
