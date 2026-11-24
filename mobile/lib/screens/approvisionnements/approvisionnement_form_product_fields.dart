import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';

class ApprovisionProductAndAmountFields extends StatelessWidget {
  final int? selectedProductId;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final double total;
  final NumberFormat formatter;
  final ValueChanged<int?> onProductChanged;
  final VoidCallback onAmountsChanged;

  const ApprovisionProductAndAmountFields({
    super.key,
    required this.selectedProductId,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.total,
    required this.formatter,
    required this.onProductChanged,
    required this.onAmountsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            final validProductId =
                provider.products.any((p) => p.id == selectedProductId) ? selectedProductId : null;
            return DropdownButtonFormField<int?>(
              key: ValueKey(validProductId),
              initialValue: validProductId,
              decoration: InputDecoration(
                labelText: 'Produit *',
                filled: true,
                fillColor: AppColors.primarySurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: provider.products
                  .map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: onProductChanged,
              validator: (v) => v == null ? 'Veuillez choisir un produit' : null,
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => onAmountsChanged(),
                decoration: const InputDecoration(labelText: 'Quantité *'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Quantité obligatoire';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Quantité invalide (> 0)';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => onAmountsChanged(),
                decoration: const InputDecoration(labelText: 'Prix unitaire d\'achat', suffixText: 'F'),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final num = double.tryParse(val.trim());
                    if (num == null || num < 0) return 'Prix unitaire invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Achat :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  formatter.format(total),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
