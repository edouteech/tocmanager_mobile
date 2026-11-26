import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/network_service.dart';

class SyncProvider extends ChangeNotifier {
  SyncStatus _status = SyncService.instance.currentStatus;
  SyncStatus get status => _status;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  bool _isOnline = NetworkService.instance.isOnline;
  bool get isOnline => _isOnline;

  String? get lastError => SyncService.instance.lastError;

  StreamSubscription<bool>? _netSub;
  StreamSubscription<SyncStatus>? _statusSub;
  StreamSubscription<void>? _queueSub;
  Timer? _periodicTimer;

  SyncProvider() {
    _init();
  }

  Future<void> _init() async {
    await NetworkService.instance.ensureInitialized();
    _isOnline = NetworkService.instance.isOnline;
    await refreshPendingCount();

    _statusSub = SyncService.onStatusChanged.listen((newStatus) {
      _status = newStatus;
      notifyListeners();
      if (newStatus != SyncStatus.syncing) {
        unawaited(refreshPendingCount());
      }
    });
    _queueSub = SyncService.onQueueChanged.listen((_) => unawaited(refreshPendingCount()));

    _netSub = NetworkService.instance.onConnectivityChanged.listen((online) async {
      _isOnline = online;
      if (online) {
        await syncNow();
      } else {
        _status = SyncStatus.offline;
        notifyListeners();
      }
    });

    _periodicTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      if (_isOnline && _status != SyncStatus.syncing) {
        await syncNow();
      }
    });

    if (_isOnline) {
      await syncNow();
    }
  }

  Future<void> refreshPendingCount() async {
    _pendingCount = await SyncService.instance.getPendingQueueCount();
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (_status == SyncStatus.syncing) return;

    _status = SyncStatus.syncing;
    notifyListeners();

    final result = await SyncService.instance.syncNow();
    _status = result;
    await refreshPendingCount();
    notifyListeners();
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    _statusSub?.cancel();
    _netSub?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
