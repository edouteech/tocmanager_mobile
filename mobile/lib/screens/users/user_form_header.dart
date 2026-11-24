import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class UserFormHeader extends StatelessWidget {
  final bool isEditing;
  final String? username;
  final VoidCallback onClose;

  const UserFormHeader({
    super.key,
    required this.isEditing,
    required this.username,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isEditing ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    isEditing ? '@${username ?? ''}' : 'Attribuez des identifiants et un rôle système',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: AppColors.textLight),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}
