import 'package:flutter/material.dart';
import '../models/plan_limit_error.dart';
import '../theme/app_theme.dart';

class PlanUpsellDialog extends StatelessWidget {
  final PlanLimitError error;

  const PlanUpsellDialog({super.key, required this.error});

  static Future<void> show(BuildContext context, PlanLimitError error) {
    return showDialog<void>(
      context: context,
      builder: (_) => PlanUpsellDialog(error: error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = error.isQuotaExceeded ? 'Quota du forfait atteint' : 'Forfait supérieur requis';
    final recPlan = error.recommendedPlan.toUpperCase();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.message,
            style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.upgrade_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Forfait conseillé : $recPlan (gestion via l\'espace web)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Compris'),
        ),
      ],
    );
  }
}
