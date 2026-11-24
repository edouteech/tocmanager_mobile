import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import 'vente_filter_helpers.dart';

class VenteFormProductPicker extends StatelessWidget {
  final TextEditingController productCtrl;
  final FocusNode productFocusNode;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final List<VenteItem> saleItems;
  final String? itemError;
  final ValueChanged<Product> onSelectProduct;
  final ValueChanged<String> onProductTextChanged;
  final VoidCallback onClearProduct;
  final VoidCallback onInputChanged;
  final ValueChanged<ProductProvider> onAddItem;

  const VenteFormProductPicker({
    super.key,
    required this.productCtrl,
    required this.productFocusNode,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.saleItems,
    required this.itemError,
    required this.onSelectProduct,
    required this.onProductTextChanged,
    required this.onClearProduct,
    required this.onInputChanged,
    required this.onAddItem,
  });

  void _stepQty(int delta) {
    final current = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
    final next = (current + delta).clamp(1.0, 999999.0);
    qtyCtrl.text = formatVenteQty(next);
    onInputChanged();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ajouter un produit',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          RawAutocomplete<Product>(
            textEditingController: productCtrl,
            focusNode: productFocusNode,
            displayStringForOption: (p) => p.name,
            optionsBuilder: (val) {
              final q = val.text.trim().toLowerCase();
              if (q.isEmpty) return products.take(15);
              return products.where(
                (p) => p.name.toLowerCase().contains(q) || (p.barcode ?? '').toLowerCase().contains(q),
              );
            },
            onSelected: onSelectProduct,
            fieldViewBuilder: (ctx, ctrl, focus, onFieldSubmitted) => TextField(
              controller: ctrl,
              focusNode: focus,
              onChanged: onProductTextChanged,
              decoration: InputDecoration(
                hintText: 'Nom du produit ou code-barres...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                suffixIcon: ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: onClearProduct,
                      )
                    : null,
              ),
            ),
            optionsViewBuilder: (ctx, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: 420),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, idx) {
                      final p = options.elementAt(idx);
                      return ListTile(
                        dense: true,
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          'Stock: ${formatVenteQty(p.quantity)} ${p.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: p.quantity <= 0 ? AppColors.danger : AppColors.textMedium,
                          ),
                        ),
                        trailing: Text(
                          '${p.price.toStringAsFixed(0)} F',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
                        ),
                        onTap: () => onSelected(p),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () => _stepQty(-1),
                      visualDensity: VisualDensity.compact,
                    ),
                    SizedBox(
                      width: 44,
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        onChanged: (_) => onInputChanged(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => _stepQty(1),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onInputChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Prix unitaire',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onAddItem(productProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
                child: const Text('Ajouter'),
              ),
            ],
          ),
          if (itemError != null) ...[
            const SizedBox(height: 8),
            Text(
              itemError!,
              style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
