import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';

class UserCard extends StatelessWidget {
  final AppUser user;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color roleColor = user.isAdmin
        ? AppColors.purple
        : user.isManager
            ? AppColors.primary
            : AppColors.success;
    final String roleLabel = user.isAdmin
        ? 'Administrateur'
        : user.isManager
            ? 'Gérant'
            : 'Caissier';
    final initial = (user.fullName?.isNotEmpty == true ? user.fullName![0] : user.username[0]).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withAlpha(30),
            child: Text(initial, style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName ?? user.username,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Vous', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}${user.email != null ? ' • ${user.email}' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _chip(roleLabel, roleColor, roleColor.withAlpha(25), borderColor: roleColor.withAlpha(60)),
                    _pinBadge(user.hasPin),
                    _chip(
                      user.isActive ? 'Actif' : 'Inactif',
                      user.isActive ? AppColors.success : AppColors.danger,
                      user.isActive ? AppColors.successLight : AppColors.dangerLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textMedium),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (action) {
              if (action == 'edit') onEdit();
              if (action == 'toggle_status') onToggleStatus();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Modifier le compte', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      user.isActive ? Icons.block_flipped : Icons.check_circle_outline,
                      size: 18,
                      color: user.isActive ? AppColors.warning : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isActive ? 'Désactiver' : 'Réactiver', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              if (!isSelf)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(fontSize: 13, color: AppColors.danger)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color textColor, Color bgColor, {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Widget _pinBadge(bool hasPin) {
    final c = hasPin ? AppColors.success : AppColors.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasPin ? AppColors.successLight : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasPin ? Icons.lock_rounded : Icons.lock_open_rounded, size: 12, color: c),
          const SizedBox(width: 4),
          Text(hasPin ? 'PIN Actif' : 'Sans PIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}
