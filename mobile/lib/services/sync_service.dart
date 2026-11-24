import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'network_service.dart';
import 'secure_storage_service.dart';
import 'sync/sync_parsers.dart';
import 'sync/sync_pull_service.dart';
import 'sync/sync_push_service.dart';
import 'sync/sync_seed_service.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class SyncService {
  static final SyncService _instance = SyncService._();
  static SyncService get instance => _instance;
  SyncService._();

  static final StreamController<void> _syncCompletedController =
      StreamController<void>.broadcast();
  static Stream<void> get onSyncCompleted => _syncCompletedController.stream;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  static int parseCategoryColor(dynamic raw) => SyncParsers.parseCategoryColor(raw);
  static int parseCategoryIcon(dynamic raw) => SyncParsers.parseCategoryIcon(raw);

  Future<SyncStatus> syncNow() async {
    if (_isSyncing) return SyncStatus.syncing;
    if (!NetworkService.instance.isOnline) return SyncStatus.offline;

    _isSyncing = true;
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        _isSyncing = false;
        return SyncStatus.error;
      }
      final baseUrl = await SecureStorageService.getServerUrl();
      await SyncSeedService.checkAndPerformInitialSeed(baseUrl);
      await SyncPushService.pushPendingQueue(baseUrl);
      await SyncPullService.pullServerChanges(baseUrl);
      _isSyncing = false;
      _syncCompletedController.add(null);
      return SyncStatus.synced;
    } catch (e) {
      debugPrint('Sync error: $e');
      _isSyncing = false;
      return SyncStatus.error;
    }
  }

  @visibleForTesting
  Future<void> pushPendingQueueWithPost(
    Future<http.Response> Function(Map<String, dynamic> body) postBatch,
  ) =>
      SyncPushService.pushPendingQueueWithPost(postBatch);

  @visibleForTesting
  Future<void> applyPullPayload(Map<String, dynamic> data) =>
      SyncPullService.applyPullPayload(data);

  Future<int> getPendingQueueCount() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
      return Sqflite.firstIntValue(res) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
