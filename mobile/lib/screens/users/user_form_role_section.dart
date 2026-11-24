import 'package:flutter/material.dart';
import '../../models/tenant.dart';
import '../../theme/app_theme.dart';
import 'user_form_fields.dart';

class UserFormRoleAndMagasinsSection extends StatelessWidget {
  final String selectedRole;
  final List<MagasinModel> allMagasins;
  final Set<String> selectedMagasinIds;
  final ValueChanged<String> onRoleChanged;
  final void Function(String magasinId, bool checked) onToggleMagasin;

  const UserFormRoleAndMagasinsSection({
    super.key,
    required this.selectedRole,
    required this.allMagasins,
    required this.selectedMagasinIds,
    required this.onRoleChanged,
    required this.onToggleMagasin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildUserFieldLabel('Rôle Système *'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'cashier',
                  child: Row(
                    children: [
                      Icon(Icons.point_of_sale_rounded, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('Caissier (Ventes & encaissements)', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'manager',
                  child: Row(
                    children: [
                      Icon(Icons.supervised_user_circle_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Gérant (Stocks, rapports & caisse)', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'store_admin',
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppColors.purple, size: 20),
                      SizedBox(width: 8),
                      Text('Administrateur Boutique (Accès total)', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) onRoleChanged(val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (selectedRole != 'store_admin' && allMagasins.isNotEmpty) ...[
          buildUserFieldLabel('Magasins assignés (vide = tous)'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: allMagasins.map((m) {
              final selected = selectedMagasinIds.contains(m.id);
              return FilterChip(
                label: Text(m.name, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (checked) => onToggleMagasin(m.id, checked),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
