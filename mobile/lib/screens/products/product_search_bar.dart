import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProductSearchAndSortBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortSelected;

  const ProductSearchAndSortBar({
    super.key,
    required this.onSearchChanged,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit (nom, code)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.sort_outlined, color: AppColors.primary, size: 20),
            ),
            tooltip: 'Trier les produits',
            onSelected: onSortSelected,
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'name_asc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Nom (A - Z)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Prix le plus élevé'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stock_asc',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Stock le plus faible'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
