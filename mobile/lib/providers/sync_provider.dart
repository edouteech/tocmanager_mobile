import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/network_service.dart';

class SyncProvider extends ChangeNotifier {
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  StreamSubscription? _netSub;
  Timer? _periodicTimer;

  SyncProvider() {
    _init();
  }

  Future<void> _init() async {
    await NetworkService.instance.initialize();
    _isOnline = NetworkService.instance.isOnline;
    await refreshPendingCount();

    _netSub = NetworkService.instance.onConnectivityChanged.listen((online) async {
      _isOnline = online;
      if (online) {
        // Retour en ligne : synchronisation automatique en arrière-plan
        await syncNow();
      } else {
        _status = SyncStatus.offline;
        notifyListeners();
      }
    });

    // Synchronisation périodique toutes les 10 minutes si connecté
    _periodicTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      if (_isOnline && _status != SyncStatus.syncing) {
        await syncNow();
      }
    });

    // Synchro initiale si déjà en ligne
    if (_isOnline) {
      syncNow();
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
    _netSub?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
