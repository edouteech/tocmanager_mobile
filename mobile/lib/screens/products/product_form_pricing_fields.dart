import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';

class ProductFormPricingFields extends StatelessWidget {
  final int? supplierId;
  final ValueChanged<int?> onSupplierChanged;
  final TextEditingController priceCtrl;
  final TextEditingController costCtrl;
  final TextEditingController priceSemiWholesaleCtrl;
  final TextEditingController minQtySemiWholesaleCtrl;
  final TextEditingController priceWholesaleCtrl;
  final TextEditingController minQtyWholesaleCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController alertCtrl;

  const ProductFormPricingFields({
    super.key,
    required this.supplierId,
    required this.onSupplierChanged,
    required this.priceCtrl,
    required this.costCtrl,
    required this.priceSemiWholesaleCtrl,
    required this.minQtySemiWholesaleCtrl,
    required this.priceWholesaleCtrl,
    required this.minQtyWholesaleCtrl,
    required this.qtyCtrl,
    required this.alertCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<SupplierProvider>(
          builder: (context, suppProvider, _) {
            final validSupplierId =
                suppProvider.suppliers.any((s) => s.id == supplierId) ? supplierId : null;
            return DropdownButtonFormField<int?>(
              key: ValueKey(validSupplierId),
              initialValue: validSupplierId,
              decoration: InputDecoration(
                labelText: 'Fournisseur (facultatif)',
                prefixIcon: const Icon(Icons.business_outlined, size: 20),
                filled: true,
                fillColor: AppColors.primarySurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Aucun fournisseur')),
                ...suppProvider.suppliers
                    .map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
              ],
              onChanged: onSupplierChanged,
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix de vente (Détail) *', suffixText: 'FCFA'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Prix de vente obligatoire';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Prix invalide (> 0)';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Prix d'achat", suffixText: 'FCFA'),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final num = double.tryParse(val.trim());
                    if (num == null || num < 0) return "Prix d'achat invalide (>= 0)";
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sell_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Tarifs Gros & Demi-Gros (Optionnel)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceSemiWholesaleCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix Demi-Gros',
                        suffixText: 'FCFA',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: minQtySemiWholesaleCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qté Min Demi-Gros',
                        hintText: 'ex: 5',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceWholesaleCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix Grossiste',
                        suffixText: 'FCFA',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: minQtyWholesaleCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qté Min Gros',
                        hintText: 'ex: 20',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantité *'),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Quantité obligatoire';
            final num = double.tryParse(val.trim());
            if (num == null || num < 0) return 'Quantité invalide (>= 0)';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: alertCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Seuil d'alerte stock",
            hintText: '5',
            prefixIcon: Icon(Icons.warning_amber_outlined, color: AppColors.warning),
          ),
          validator: (val) {
            if (val != null && val.trim().isNotEmpty) {
              final num = double.tryParse(val.trim());
              if (num == null || num < 0) return 'Seuil invalide (>= 0)';
            }
            return null;
          },
        ),
      ],
    );
  }
}
