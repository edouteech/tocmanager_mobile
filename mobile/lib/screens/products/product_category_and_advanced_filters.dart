import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';

class ProductCategoryFilterRow extends StatelessWidget {
  final int? filterCategoryId;
  final ValueChanged<int?> onCategorySelected;
  final VoidCallback onOpenAdvancedFilters;

  const ProductCategoryFilterRow({
    super.key,
    required this.filterCategoryId,
    required this.onCategorySelected,
    required this.onOpenAdvancedFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(null, 'Toutes cat.'),
                    ...catProvider.categories.map((c) => _filterChip(c.id, c.name)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primary, size: 20),
              onPressed: onOpenAdvancedFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int? catId, String label) {
    final selected = filterCategoryId == catId;
    return GestureDetector(
      onTap: () => onCategorySelected(catId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMedium,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

void showProductAdvancedFiltersSheet(
  BuildContext context, {
  required int? initialCategoryId,
  required String? initialStatut,
  required void Function(int? categoryId, String? statut) onApply,
  required VoidCallback onReset,
}) {
  final catProvider = context.read<CategoryProvider>();
  int? pendingCategoryId = initialCategoryId;
  String? pendingStatut = initialStatut;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Filtres avancés',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        pendingCategoryId = null;
                        pendingStatut = null;
                      });
                      onReset();
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int?>(
                key: ValueKey(pendingCategoryId),
                initialValue: pendingCategoryId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Toutes les catégories')),
                  ...catProvider.categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setSheetState(() => pendingCategoryId = v),
              ),
              const SizedBox(height: 14),
              const Text('Statut du stock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                key: ValueKey(pendingStatut),
                initialValue: pendingStatut,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Tous les statuts')),
                  DropdownMenuItem<String?>(value: 'en_stock', child: Text('En stock')),
                  DropdownMenuItem<String?>(value: 'lowStock', child: Text('Stock faible & Rupture')),
                  DropdownMenuItem<String?>(value: 'faible', child: Text('Stock faible uniquement')),
                  DropdownMenuItem<String?>(value: 'rupture', child: Text('Rupture uniquement')),
                ],
                onChanged: (v) => setSheetState(() => pendingStatut = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onApply(pendingCategoryId, pendingStatut);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Appliquer les filtres'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
