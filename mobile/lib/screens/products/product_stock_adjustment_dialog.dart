import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';

void showProductStockAdjustmentDialog(BuildContext context, Product product) {
  final qtyCtrl = TextEditingController(text: '1');
  String mode = 'add'; // 'add', 'remove', 'set'

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final double currentQty = product.quantity;
          final double inputQty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
          double newQty = currentQty;
          if (mode == 'add') {
            newQty = currentQty + inputQty;
          } else if (mode == 'remove') {
            newQty = (currentQty - inputQty).clamp(0, double.infinity);
          } else if (mode == 'set') {
            newQty = inputQty.clamp(0, double.infinity);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ajuster le stock : ${product.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Stock actuel', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                          const SizedBox(height: 2),
                          Text(
                            '${currentQty.toStringAsFixed(currentQty.truncateToDouble() == currentQty ? 0 : 1)} ${product.unit}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
                      Column(
                        children: [
                          const Text('Nouveau stock', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                          const SizedBox(height: 2),
                          Text(
                            '${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 1)} ${product.unit}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _modeChip('+ Ajouter', 'add', AppColors.success, mode, (m) => setSheetState(() => mode = m)),
                    const SizedBox(width: 6),
                    _modeChip('- Retirer', 'remove', AppColors.danger, mode, (m) => setSheetState(() => mode = m)),
                    const SizedBox(width: 6),
                    _modeChip('= Définir', 'set', AppColors.purple, mode, (m) => setSheetState(() => mode = m)),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: mode == 'set' ? 'Nouvelle quantité exacte' : 'Nombre d\'unités',
                    suffixText: product.unit,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final updatedProduct = product.copyWith(quantity: newQty);
                      await context.read<ProductProvider>().update(updatedProduct);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        AppToast.showSuccess(
                          context,
                          'Stock de ${product.name} mis à jour : ${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 1)} ${product.unit}',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Valider le réajustement', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _modeChip(
  String label,
  String value,
  Color color,
  String currentMode,
  ValueChanged<String> onSelect,
) {
  final isSelected = currentMode == value;
  return Expanded(
    child: ChoiceChip(
      label: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
      selected: isSelected,
      selectedColor: color,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700),
      onSelected: (val) {
        if (val) onSelect(value);
      },
    ),
  );
}
