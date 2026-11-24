import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import 'audit_action_meta.dart';

void showAuditLogDetailModal(BuildContext context, AuditLogItem item) {
  final meta = getAuditActionMeta(item.action);
  final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(item.createdAt);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: meta['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  meta['icon'] as IconData,
                  color: meta['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta['label'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),
          _buildDetailRow('Auteur', item.userName ?? item.userId ?? 'Système'),
          if (item.entityType != null)
            _buildDetailRow('Entité concernée', '${item.entityType} (${item.entityId ?? '-'})'),
          _buildDetailRow('Identifiant d\'audit', item.id),
          const SizedBox(height: 12),
          const Text(
            'Détails techniques :',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: SingleChildScrollView(
                child: Text(
                  item.details != null
                      ? const JsonEncoder.withIndent('  ').convert(item.details)
                      : 'Aucun détail supplémentaire.',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}
