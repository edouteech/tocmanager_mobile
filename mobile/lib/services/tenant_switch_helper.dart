import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import 'network_service.dart';
import 'secure_storage_service.dart';
import 'sync/sync_push_service.dart';
import 'sync_service.dart';

class TenantSwitchHelper {
  /// Best-effort push of pending queue items, then clear tenant business data.
  static Future<void> prepareBoutiqueSwitchIfNeeded({
    String? currentBoutiqueId,
    required String nextBoutiqueId,
    bool triggerPush = true,
  }) async {
    final previousId = currentBoutiqueId ?? await SecureStorageService.getCurrentBoutiqueId();
    if (previousId == null || previousId.isEmpty || previousId == nextBoutiqueId) {
      return;
    }

    if (triggerPush && !SyncService.instance.isSyncing) {
      try {
        final pending = await SyncService.instance.getPendingQueueCount();
        if (pending > 0) {
          await NetworkService.instance.ensureInitialized();
          final token = await SecureStorageService.getAccessToken();
          if (NetworkService.instance.isOnline && token != null && token.isNotEmpty) {
            final baseUrl = await SecureStorageService.getServerUrl();
            await SyncPushService.pushPendingQueue(baseUrl);
          }
        }
      } catch (e) {
        debugPrint('Best-effort push before boutique switch skipped: $e');
      }
    }

    await DatabaseHelper.instance.clearAllBusinessData(keepTenants: true);
  }
}
