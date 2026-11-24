import 'dart:convert';
import '../database/database_helper.dart';
import '../models/tenant.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

class TenantService {
  TenantService._();
  static final TenantService instance = TenantService._();

  Future<List<BoutiqueModel>> fetchBoutiques({bool fallbackToCache = true}) async {
    try {
      final baseUrl = await SecureStorageService.getServerUrl();
      final res = await ApiClient.instance.get(Uri.parse('$baseUrl/tenant/boutiques'));
      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body) as List<dynamic>;
        final boutiques = raw
            .map((e) => BoutiqueModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        await DatabaseHelper.instance.saveBoutiquesAndMagasins(boutiques);
        return boutiques;
      }
    } catch (_) {}
    if (!fallbackToCache) return const [];
    return DatabaseHelper.instance.getCachedBoutiques();
  }

  Future<PlanStatusModel?> loadCachedPlan() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('settings', where: 'key = ?', whereArgs: ['cached_plan_status']);
      if (rows.isEmpty) return null;
      final raw = rows.first['value'] as String?;
      if (raw == null || raw.isEmpty) return null;
      return PlanStatusModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<PlanStatusModel?> fetchPlanStatus() async {
    try {
      final baseUrl = await SecureStorageService.getServerUrl();
      final res = await ApiClient.instance.get(Uri.parse('$baseUrl/tenant/current-plan'));
      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final model = PlanStatusModel.fromMap(map);
        final db = await DatabaseHelper.instance.database;
        await db.rawInsert(
          'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
          ['cached_plan_status', jsonEncode(map)],
        );
        return model;
      }
    } catch (_) {}
    return null;
  }
}
