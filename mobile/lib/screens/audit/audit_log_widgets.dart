import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import 'audit_action_meta.dart';

class AuditRestrictedView extends StatelessWidget {
  const AuditRestrictedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accès restreint')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.danger, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Accès Réservé aux Responsables',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'La consultation du journal d\'audit nécessite des privilèges d\'administration ou de gestion.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMedium),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuditLogCard extends StatelessWidget {
  final AuditLogItem item;
  final VoidCallback onTap;

  const AuditLogCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = getAuditActionMeta(item.action);
    final timeStr = DateFormat('dd/MM HH:mm').format(item.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: meta['bgColor'] as Color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                meta['icon'] as IconData,
                color: meta['color'] as Color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        meta['label'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Par : ${item.userName ?? item.userId ?? 'Système'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}
