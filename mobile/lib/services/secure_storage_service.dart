import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../models/user.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _kAccessToken = 'toc_access_token';
  static const _kRefreshToken = 'toc_refresh_token';
  static const _kUserProfile = 'toc_user_profile';
  static const _kPinHash = 'toc_pin_hash';
  static const _kPinSalt = 'toc_pin_salt';
  static const _kServerUrl = 'toc_server_url';
  static const _kInitialSeedDone = 'toc_initial_seed_done';

  /// URL unique et définitive de l'API en production sur Coolify
  static const String apiUrl = 'https://api.tocmanager.locarapide.com/api/v1';

  static String get defaultServerUrl => apiUrl;

  /// Indique si le téléversement initial des données préexistantes a été effectué
  static Future<bool> hasInitialSeedDone() async {
    final val = await _storage.read(key: _kInitialSeedDone);
    return val == 'true';
  }

  static Future<void> setInitialSeedDone() async {
    await _storage.write(key: _kInitialSeedDone, value: 'true');
  }

  /// Sauvegarde les tokens d'authentification
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: _kAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _kRefreshToken);
  }

  /// Sauvegarde le profil utilisateur local
  static Future<void> saveUser(AppUser user) async {
    await _storage.write(key: _kUserProfile, value: jsonEncode(user.toMap()));
  }

  static Future<AppUser?> getUser() async {
    final str = await _storage.read(key: _kUserProfile);
    if (str == null) return null;
    try {
      return AppUser.fromMap(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Hachage et enregistrement sécurisé du code PIN hors-ligne
  static Future<void> savePin(String pin) async {
    // Génère un sel unique
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final combined = '$pin:$salt:tocmanager_device_key';
    final hash = sha256.convert(utf8.encode(combined)).toString();

    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hash);
  }

  /// Vérifie si un PIN est déjà enregistré
  static Future<bool> hasPinConfigured() async {
    final hash = await _storage.read(key: _kPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// Vérification locale du code PIN en mode hors-ligne
  static Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kPinSalt);
    final savedHash = await _storage.read(key: _kPinHash);
    if (salt == null || savedHash == null) return false;

    final combined = '$pin:$salt:tocmanager_device_key';
    final computedHash = sha256.convert(utf8.encode(combined)).toString();
    return computedHash == savedHash;
  }

  /// URL du serveur API (fixe et non modifiable)
  static Future<String> getServerUrl() async {
    return apiUrl;
  }

  static Future<void> setServerUrl(String url) async {
    // URL fixe et non modifiable
  }

  /// Déconnexion / purge de session
  static Future<void> clearSession() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUserProfile);
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSalt);
  }
}
