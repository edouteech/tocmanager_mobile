import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/tenant.dart';
import '../models/user.dart';
import '../services/secure_storage_service.dart';
import '../services/sync_service.dart';
import '../services/tenant_service.dart';

class TenantProvider extends ChangeNotifier {
  List<BoutiqueModel> _boutiques = [];
  BoutiqueModel? _currentBoutique;
  MagasinModel? _currentMagasin;
  bool _isConsolidatedMode = false;
  bool _openConsolidatedReportsPending = false;
  PlanStatusModel? _planStatus;
  AppUser? _activeUser;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<BoutiqueModel> get boutiques => _boutiques;
  BoutiqueModel? get currentBoutique => _currentBoutique;
  MagasinModel? get currentMagasin => _currentMagasin;
  bool get isConsolidatedMode => _isConsolidatedMode;
  PlanStatusModel? get planStatus => _planStatus;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MagasinModel> get allBoutiqueMagasins {
    final b = _currentBoutique;
    if (b == null) return const [];
    return b.magasins.where((m) => m.isActive).toList();
  }

  List<MagasinModel> get magasins {
    final allActive = allBoutiqueMagasins;
    if (_activeUser == null) return allActive;
    final role = (_currentBoutique?.userRole ?? _activeUser!.role).toLowerCase();
    if (role == 'owner' || role == 'merchant' || role == 'store_admin' || role == 'admin') {
      return allActive;
    }
    final assigned = _currentBoutique?.assignedMagasinIds.isNotEmpty == true
        ? _currentBoutique!.assignedMagasinIds
        : _activeUser!.assignedMagasinIds;
    if (assigned.isEmpty) return allActive;
    return allActive.where((m) => assigned.contains(m.id)).toList();
  }

  bool get canConsolidate {
    final u = _activeUser;
    if (u == null) return false;
    final role = (_currentBoutique?.userRole ?? u.role).toLowerCase();
    if (role == 'owner' || role == 'merchant' || role == 'store_admin' || role == 'admin') {
      return true;
    }
    if (role == 'manager') {
      final assigned = _currentBoutique?.assignedMagasinIds.isNotEmpty == true
          ? _currentBoutique!.assignedMagasinIds
          : u.assignedMagasinIds;
      return assigned.isEmpty;
    }
    return false;
  }

  bool get needsBoutiqueSelection =>
      _isInitialized && _currentBoutique == null && _boutiques.length > 1;

  bool get needsMagasinSelection =>
      _isInitialized && _currentBoutique != null && !_isConsolidatedMode && _currentMagasin == null;

  bool hasFeature(String code) => _planStatus?.hasFeature(code) ?? false;
  int getLimit(String code) => _planStatus?.getLimit(code) ?? 0;

  bool needsOperationalMagasin({required bool isSale}) {
    if (_isConsolidatedMode || _currentMagasin == null) return true;
    if (isSale && _currentMagasin!.isWarehouse) return true;
    return false;
  }

  List<MagasinModel> operationalMagasins({required bool isSale}) {
    return magasins.where((m) => m.isActive && (!isSale || !m.isWarehouse)).toList();
  }

  bool consumeOpenConsolidatedReports() {
    if (!_openConsolidatedReportsPending) return false;
    _openConsolidatedReportsPending = false;
    return true;
  }

  Future<void> initializeForUser(
    AppUser user, {
    List<BoutiqueModel>? preloadedBoutiques,
    bool triggerSync = true,
  }) async {
    _activeUser = user;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (preloadedBoutiques != null) {
        _boutiques = preloadedBoutiques;
        await DatabaseHelper.instance.saveBoutiquesAndMagasins(preloadedBoutiques);
      } else {
        _boutiques = await TenantService.instance.fetchBoutiques();
      }

      if (_boutiques.isEmpty) {
        _boutiques = await DatabaseHelper.instance.getCachedBoutiques();
      }

      final savedBoutiqueId = await SecureStorageService.getCurrentBoutiqueId();
      final selected = (savedBoutiqueId != null
              ? _boutiques.where((b) => b.id == savedBoutiqueId).firstOrNull
              : null) ??
          (_boutiques.length == 1 ? _boutiques.first : null);

      _currentBoutique = selected;
      if (selected != null) {
        await _resolveMagasinOnBoutique(selected);
        await DatabaseHelper.instance.backfillTenantIds(selected.id, _currentMagasin?.id);
        _planStatus = await TenantService.instance.loadCachedPlan();
        if (triggerSync && preloadedBoutiques == null) {
          unawaited(refreshPlanStatus());
          if (_isConsolidatedMode || _currentMagasin != null) {
            unawaited(SyncService.instance.syncNow(forceResyncIfBusy: true));
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Impossible de charger les boutiques.';
      debugPrint('Tenant init error: $e');
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _resolveMagasinOnBoutique(BoutiqueModel boutique) async {
    final available = magasins;
    final savedConsolidated = await SecureStorageService.isConsolidatedMode();
    if (savedConsolidated && canConsolidate) {
      _isConsolidatedMode = true;
      _currentMagasin = null;
      await SecureStorageService.saveTenantContext(boutiqueId: boutique.id, isConsolidated: true);
      return;
    }

    final savedMagId = await SecureStorageService.getCurrentMagasinId();
    final matched = (savedMagId != null
            ? available.where((m) => m.id == savedMagId).firstOrNull
            : null) ??
        (!canConsolidate && available.length == 1 ? available.first : null);

    _currentMagasin = matched;
    _isConsolidatedMode = false;
    await SecureStorageService.saveTenantContext(
      boutiqueId: boutique.id,
      magasinId: matched?.id,
      isConsolidated: false,
    );
  }

  Future<void> selectBoutique(BoutiqueModel boutique, {bool triggerSync = true}) async {
    final changed = _currentBoutique?.id != boutique.id;
    _currentBoutique = boutique;
    _currentMagasin = null;
    _isConsolidatedMode = false;

    if (changed) {
      await SecureStorageService.saveTenantContext(boutiqueId: boutique.id);
      await DatabaseHelper.instance.clearSyncCursor();
    }
    await _resolveMagasinOnBoutique(boutique);
    await DatabaseHelper.instance.backfillTenantIds(boutique.id, _currentMagasin?.id);
    notifyListeners();

    if (triggerSync) {
      unawaited(refreshPlanStatus());
      if (_isConsolidatedMode || _currentMagasin != null) {
        unawaited(SyncService.instance.syncNow(forceResyncIfBusy: true));
      }
    }
  }

  Future<void> selectMagasin(MagasinModel magasin, {bool triggerSync = true}) async {
    if (_currentBoutique == null) return;
    _currentMagasin = magasin;
    _isConsolidatedMode = false;
    _openConsolidatedReportsPending = false;
    await SecureStorageService.saveTenantContext(
      boutiqueId: _currentBoutique!.id,
      magasinId: magasin.id,
      isConsolidated: false,
    );
    await DatabaseHelper.instance.backfillTenantIds(_currentBoutique!.id, magasin.id);
    await DatabaseHelper.instance.clearSyncCursor();
    notifyListeners();

    if (triggerSync) {
      unawaited(SyncService.instance.syncNow(forceResyncIfBusy: true));
    }
  }

  Future<void> enterConsolidatedMode({bool openReports = true, bool triggerSync = true}) async {
    if (_currentBoutique == null || !canConsolidate) return;
    _currentMagasin = null;
    _isConsolidatedMode = true;
    _openConsolidatedReportsPending = openReports;
    await SecureStorageService.saveTenantContext(
      boutiqueId: _currentBoutique!.id,
      magasinId: null,
      isConsolidated: true,
    );
    await DatabaseHelper.instance.clearSyncCursor();
    notifyListeners();

    if (triggerSync) {
      unawaited(SyncService.instance.syncNow(forceResyncIfBusy: true));
    }
  }

  Future<void> refreshPlanStatus() async {
    if (_currentBoutique == null) return;
    final fresh = await TenantService.instance.fetchPlanStatus();
    if (fresh != null) {
      _planStatus = fresh;
      notifyListeners();
    }
  }

  void reset() {
    _boutiques = [];
    _currentBoutique = null;
    _currentMagasin = null;
    _isConsolidatedMode = false;
    _openConsolidatedReportsPending = false;
    _planStatus = null;
    _activeUser = null;
    _isInitialized = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
