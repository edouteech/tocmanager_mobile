import 'dart:convert';
import '../models/user.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

class UserService {
  static final UserService instance = UserService._internal();
  UserService._internal();

  /// Récupère la liste de tous les utilisateurs (Admin/Manager)
  Future<List<AppUser>> getUsers() async {
    final baseUrl = await SecureStorageService.getServerUrl();
    final url = Uri.parse('$baseUrl/users');

    final response = await ApiClient.instance.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromMap(json as Map<String, dynamic>)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Impossible de récupérer la liste des utilisateurs.');
    }
  }

  /// Crée un nouvel utilisateur (Admin uniquement)
  Future<AppUser> createUser({
    required String username,
    required String password,
    String? fullName,
    String? email,
    required String role,
    String? pin,
  }) async {
    final baseUrl = await SecureStorageService.getServerUrl();
    final url = Uri.parse('$baseUrl/users');

    final payload = <String, dynamic>{
      'username': username.trim(),
      'password': password,
      'full_name': fullName?.trim().isNotEmpty == true ? fullName!.trim() : null,
      'email': email?.trim().isNotEmpty == true ? email!.trim() : null,
      'role': role,
      'pin': pin?.trim().isNotEmpty == true ? pin!.trim() : null,
    };

    final response = await ApiClient.instance.post(
      url,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AppUser.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erreur lors de la création de l\'utilisateur.');
    }
  }

  /// Modifie un utilisateur existant (Admin uniquement)
  Future<AppUser> updateUser(
    String userId, {
    String? fullName,
    String? email,
    String? role,
    String? password,
    String? pin,
    bool? isActive,
  }) async {
    final baseUrl = await SecureStorageService.getServerUrl();
    final url = Uri.parse('$baseUrl/users/$userId');

    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName.trim();
    if (email != null) payload['email'] = email.trim();
    if (role != null) payload['role'] = role;
    if (password != null && password.isNotEmpty) payload['password'] = password;
    if (pin != null) payload['pin'] = pin.trim();
    if (isActive != null) payload['is_active'] = isActive;

    final response = await ApiClient.instance.put(
      url,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return AppUser.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erreur lors de la modification de l\'utilisateur.');
    }
  }

  /// Supprime un utilisateur (Admin uniquement)
  Future<void> deleteUser(String userId) async {
    final baseUrl = await SecureStorageService.getServerUrl();
    final url = Uri.parse('$baseUrl/users/$userId');

    final response = await ApiClient.instance.delete(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Erreur lors de la suppression de l\'utilisateur.');
    }
  }
}
