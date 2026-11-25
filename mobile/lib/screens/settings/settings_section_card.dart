import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/secure_storage_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import '../users_screen.dart';

class SettingsSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? titleColor;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.titleColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class SettingsCloudSyncCard extends StatelessWidget {
  const SettingsCloudSyncCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Serveur & Synchronisation Cloud',
      icon: Icons.cloud_outlined,
      children: [
        const Text(
          'Configurez l\'adresse du serveur API central pour la synchronisation automatique des ventes, du stock et l\'accès backoffice.',
          style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_done_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  SecureStorageService.apiUrl,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.lock_outline, size: 16, color: AppColors.textLight),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<SyncProvider>(
          builder: (context, syncProv, _) {
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: syncProv.status == SyncStatus.syncing
                        ? null
                        : () async {
                            await syncProv.syncNow();
                            if (!context.mounted) return;
                            if (syncProv.status == SyncStatus.synced) {
                              AppToast.showSuccess(context, 'Synchronisation terminée avec succès');
                            } else if (syncProv.status == SyncStatus.offline) {
                              AppToast.showWarning(context, 'Appareil hors-ligne : synchronisation reportée');
                            } else if (syncProv.status == SyncStatus.error) {
                              AppToast.showError(context, 'Échec de la synchronisation avec le serveur');
                            }
                          },
                    icon: const Icon(Icons.sync, size: 18),
                    label: syncProv.status == SyncStatus.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Synchroniser maintenant'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SettingsUsersAdminCard extends StatelessWidget {
  const SettingsUsersAdminCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Utilisateurs & Accès Caisse',
      icon: Icons.manage_accounts_outlined,
      children: [
        const Text(
          'Gérez les comptes d\'accès des caissiers et gérants, réinitialisez les codes PIN et configurez les droits système.',
          style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersScreen()),
              );
            },
            icon: const Icon(Icons.people_alt_rounded, size: 18),
            label: const Text('Gérer les utilisateurs & codes PIN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
