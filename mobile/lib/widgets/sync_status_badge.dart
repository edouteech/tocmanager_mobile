import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  void _showSyncDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<SyncProvider>(
          builder: (_, sync, __) {
            String statusLabel;
            Color statusColor;
            IconData statusIcon;

            switch (sync.status) {
              case SyncStatus.syncing:
                statusLabel = 'Synchronisation en cours...';
                statusColor = AppColors.warning;
                statusIcon = Icons.sync;
                break;
              case SyncStatus.synced:
                statusLabel = 'Base locale synchronisée avec le serveur';
                statusColor = AppColors.success;
                statusIcon = Icons.cloud_done_outlined;
                break;
              case SyncStatus.offline:
                statusLabel = 'Mode Hors-ligne (Opérations en file locale)';
                statusColor = AppColors.textMedium;
                statusIcon = Icons.cloud_off_outlined;
                break;
              case SyncStatus.error:
                statusLabel = 'Dernière tentative échouée';
                statusColor = AppColors.danger;
                statusIcon = Icons.error_outline;
                break;
              case SyncStatus.idle:
                statusLabel = 'Prêt pour la synchronisation';
                statusColor = AppColors.textMedium;
                statusIcon = Icons.cloud_queue_outlined;
                break;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('État du Réseau', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: sync.isOnline ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sync.isOnline ? 'En Ligne' : 'Hors-Ligne',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: sync.isOnline ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ventes en attente d\'envoi', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                            Text(
                              '${sync.pendingCount}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: sync.status == SyncStatus.syncing
                        ? null
                        : () async {
                            await sync.syncNow();
                          },
                    icon: sync.status == SyncStatus.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: const Text('Synchroniser Maintenant'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();

    Widget iconWidget;
    switch (sync.status) {
      case SyncStatus.syncing:
        iconWidget = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
        );
        break;
      case SyncStatus.synced:
        iconWidget = const Icon(
          Icons.cloud_done_outlined,
          color: AppColors.success,
          size: 22,
        );
        break;
      case SyncStatus.offline:
        iconWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.textMedium,
              size: 22,
            ),
            if (sync.pendingCount > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sync.pendingCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
        break;
      case SyncStatus.error:
        iconWidget = const Icon(
          Icons.cloud_off_outlined,
          color: AppColors.danger,
          size: 22,
        );
        break;
      case SyncStatus.idle:
        iconWidget = const Icon(
          Icons.cloud_queue_outlined,
          color: AppColors.textLight,
          size: 22,
        );
        break;
    }

    return IconButton(
      tooltip: 'Statut de Synchronisation',
      onPressed: () => _showSyncDetails(context),
      icon: iconWidget,
    );
  }
}
