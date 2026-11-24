import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import 'settings_section_card.dart';

class SettingsBackupCard extends StatelessWidget {
  final bool backingUp;
  final bool restoring;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  const SettingsBackupCard({
    super.key,
    required this.backingUp,
    required this.restoring,
    required this.onBackup,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Sauvegarde & Restauration',
      icon: Icons.cloud_sync_outlined,
      children: [
        const Text(
          'Sauvegardez régulièrement vos données (produits, ventes, créances, dépenses) pour éviter toute perte.',
          style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: backingUp ? null : onBackup,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: backingUp
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Exporter Sauvegarde'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: restoring ? null : onRestore,
                icon: const Icon(Icons.upload_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
                label: restoring
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Restaurer Sauvegarde'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SettingsDangerZoneCard extends StatelessWidget {
  final bool disabled;
  final bool clearingData;
  final VoidCallback onClearData;

  const SettingsDangerZoneCard({
    super.key,
    required this.disabled,
    required this.clearingData,
    required this.onClearData,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Zone de Danger',
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.danger,
      titleColor: AppColors.danger,
      children: [
        const Text(
          'Cette action supprime l\'ensemble des produits, stocks, ventes, créances clients, fournisseurs et dépenses. Vos coordonnées et réglages du magasin restent préservés.',
          style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: disabled ? null : onClearData,
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            label: clearingData
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                  )
                : const Text('Vider les données', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

Future<bool?> showRestoreConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Restaurer la base de données', style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text(
        'Attention : Cette action va remplacer vos données actuelles par celles du fichier de sauvegarde. Voulez-vous continuer ?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
          child: const Text('Restaurer'),
        ),
      ],
    ),
  );
}

Future<bool?> showClearDataConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
          SizedBox(width: 8),
          Text('Vider les données ?', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir supprimer toutes les données d\'activité ?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            '• Données supprimées : Produits, stocks, ventes, tickets, clients, fournisseurs, approvisionnements, dépenses.\n\n'
            '• Données conservées : Coordonnées, devise et réglages du magasin.\n\n'
            'Une sauvegarde automatique de secours sera créée avant la suppression afin de prévenir toute perte involontaire.',
            style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
          child: const Text('Confirmer la suppression'),
        ),
      ],
    ),
  );
}

Future<void> showClearDataSuccessDialog(BuildContext context, String? backupPath) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
          SizedBox(width: 8),
          Text('Données vidées', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toutes les données d\'activité ont été réinitialisées avec succès. Vos réglages de magasin ont été conservés.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          if (backupPath != null) ...[
            const SizedBox(height: 14),
            const Text(
              'Une sauvegarde automatique de secours a été créée avant la suppression à l\'emplacement suivant :',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: SelectableText(
                backupPath,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (backupPath != null)
          TextButton.icon(
            onPressed: () => Share.shareXFiles([XFile(backupPath)], text: 'Sauvegarde de secours TOC Manager'),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Partager la sauvegarde'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Compris'),
        ),
      ],
    ),
  );
}
