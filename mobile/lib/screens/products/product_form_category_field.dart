import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';

void showQuickAddCategoryDialog(
  BuildContext context,
  void Function(int? id, String name) onCreated,
) {
  final catNameCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Nouvelle catégorie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      content: TextField(
        controller: catNameCtrl,
        decoration: const InputDecoration(
          labelText: 'Nom de la catégorie',
          hintText: 'Ex: Électronique, Boissons...',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            final name = catNameCtrl.text.trim();
            if (name.isNotEmpty) {
              final newCat = Category(
                name: name,
                color: AppColors.primary.toARGB32(),
                icon: Icons.category.codePoint,
                createdAt: DateTime.now(),
              );
              final catProvider = context.read<CategoryProvider>();
              await catProvider.add(newCat);
              final createdCat = catProvider.categories.where((c) => c.name == name).firstOrNull;
              if (createdCat != null) onCreated(createdCat.id, createdCat.name);
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Créer'),
        ),
      ],
    ),
  );
}

class ProductCategoryAutocomplete extends StatelessWidget {
  final TextEditingController categoryCtrl;
  final FocusNode focusNode;
  final void Function(int? id, String? name) onSelectCategory;
  final VoidCallback onAddCategoryTap;

  const ProductCategoryAutocomplete({
    super.key,
    required this.categoryCtrl,
    required this.focusNode,
    required this.onSelectCategory,
    required this.onAddCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Consumer<CategoryProvider>(
            builder: (context, catProvider, _) {
              return RawAutocomplete<Category>(
                textEditingController: categoryCtrl,
                focusNode: focusNode,
                displayStringForOption: (Category option) => option.name,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) return catProvider.categories;
                  return catProvider.categories.where((c) => c.name.toLowerCase().contains(query));
                },
                onSelected: (Category selection) {
                  categoryCtrl.text = selection.name;
                  categoryCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: selection.name.length),
                  );
                  onSelectCategory(selection.id, selection.name);
                },
                fieldViewBuilder: (context, controller, fNode, _) {
                  return TextFormField(
                    controller: controller,
                    focusNode: fNode,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      hintText: 'Sélectionner ou saisir une catégorie',
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                controller.clear();
                                onSelectCategory(null, null);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.primarySurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      final match = catProvider.categories
                          .where((c) => c.name.toLowerCase() == val.trim().toLowerCase())
                          .firstOrNull;
                      onSelectCategory(match?.id, null);
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final query = categoryCtrl.text.trim();
                  final hasExactMatch = catProvider.categories.any(
                    (c) => c.name.toLowerCase() == query.toLowerCase(),
                  );

                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 90,
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          children: [
                            ...options.map((Category option) => ListTile(
                                  dense: true,
                                  leading: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primarySurface,
                                    child: Icon(Icons.category, size: 14, color: AppColors.primary),
                                  ),
                                  title: Text(option.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  onTap: () => onSelected(option),
                                )),
                            if (query.isNotEmpty && !hasExactMatch) ...[
                              if (options.isNotEmpty) const Divider(height: 1, color: AppColors.divider),
                              ListTile(
                                dense: true,
                                leading: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Icon(Icons.add, size: 14, color: AppColors.primary),
                                ),
                                title: Text(
                                  'Créer la catégorie "$query"',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                                ),
                                onTap: () {
                                  categoryCtrl.text = query;
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Créer une catégorie',
          onPressed: onAddCategoryTap,
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: const Icon(Icons.add, color: AppColors.primary, size: 20),
          ),
        ),
      ],
    );
  }
}
