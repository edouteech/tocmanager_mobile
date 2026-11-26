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

  static final StreamController<void> _queueChangedController =
      StreamController<void>.broadcast();
  static Stream<void> get onQueueChanged => _queueChangedController.stream;

  static final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  static Stream<SyncStatus> get onStatusChanged => _statusController.stream;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _resyncRequested = false;
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  String? _lastError;
  String? get lastError => _lastError;

  static int parseCategoryColor(dynamic raw) => SyncParsers.parseCategoryColor(raw);
  static int parseCategoryIcon(dynamic raw) => SyncParsers.parseCategoryIcon(raw);

  void notifyLocalMutation() {
    if (!_queueChangedController.isClosed) {
      _queueChangedController.add(null);
    }
    unawaited(syncNow(forceResyncIfBusy: true));
  }

  void notifyDataReloadNeeded() {
    if (!_syncCompletedController.isClosed) {
      _syncCompletedController.add(null);
    }
  }

  void _setStatus(SyncStatus status, {String? error}) {
    _currentStatus = status;
    _lastError = error;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<SyncStatus> syncNow({bool forceResyncIfBusy = false}) async {
    if (_isSyncing) {
      if (forceResyncIfBusy) _resyncRequested = true;
      return SyncStatus.syncing;
    }
    await NetworkService.instance.ensureInitialized();
    if (!NetworkService.instance.isOnline) {
      _setStatus(SyncStatus.offline);
      return SyncStatus.offline;
    }

    final token = await SecureStorageService.getAccessToken();
    final boutiqueId = await SecureStorageService.getCurrentBoutiqueId();
    if (token == null || token.isEmpty || boutiqueId == null || boutiqueId.isEmpty) {
      _setStatus(SyncStatus.idle);
      return SyncStatus.idle;
    }

    _isSyncing = true;
    _setStatus(SyncStatus.syncing);
    try {
      do {
        _resyncRequested = false;
        final baseUrl = await SecureStorageService.getServerUrl();
        await SyncSeedService.checkAndPerformInitialSeed(baseUrl);
        await SyncPushService.pushPendingQueue(baseUrl);
        await SyncPullService.pullServerChanges(baseUrl);
      } while (_resyncRequested);

      _isSyncing = false;
      _setStatus(SyncStatus.synced);
      _syncCompletedController.add(null);
      return SyncStatus.synced;
    } catch (e) {
      debugPrint('Sync error: $e');
      _resyncRequested = false;
      _isSyncing = false;
      _setStatus(SyncStatus.error, error: e.toString());
      return SyncStatus.error;
    }
  }

  @visibleForTesting
  Future<void> pushPendingQueueWithPost(
    Future<http.Response> Function(Map<String, dynamic> body) postBatch,
  ) =>
      SyncPushService.pushPendingQueueWithPost(postBatch);

  @visibleForTesting
  Future<void> pullServerChangesWithGet(
    String baseUrl,
    Future<http.Response> Function(Uri uri) getPage,
  ) =>
      SyncPullService.pullServerChangesWithGet(baseUrl, getPage);

  @visibleForTesting
  Future<void> applyPullPayload(
    Map<String, dynamic> data, {
    bool updateCursor = true,
    String? cursorOverride,
  }) =>
      SyncPullService.applyPullPayload(
        data,
        updateCursor: updateCursor,
        cursorOverride: cursorOverride,
      );

  Future<int> getPendingQueueCount() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.rawQuery(
        "SELECT COUNT(*) as count FROM sync_queue WHERE status IS NULL OR status != 'quarantined'",
      );
      return Sqflite.firstIntValue(res) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getQuarantinedQueueCount() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.rawQuery(
        "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'quarantined'",
      );
      return Sqflite.firstIntValue(res) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
