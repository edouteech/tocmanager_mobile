import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class VenteFormDiscountCard extends StatelessWidget {
  final double subtotalAmount;
  final double computedDiscountAmount;
  final double totalAmount;
  final TextEditingController discountCtrl;
  final String discountType;
  final NumberFormat formatter;
  final ValueChanged<String> onToggleDiscountType;
  final VoidCallback onDiscountChanged;

  const VenteFormDiscountCard({
    super.key,
    required this.subtotalAmount,
    required this.computedDiscountAmount,
    required this.totalAmount,
    required this.discountCtrl,
    required this.discountType,
    required this.formatter,
    required this.onToggleDiscountType,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sous-total', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
              Text(
                formatter.format(subtotalAmount),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: discountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onDiscountChanged(),
                  decoration: InputDecoration(
                    labelText: discountType == 'percent' ? 'Remise (%)' : 'Remise (FCFA)',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _typeChip('FCFA', discountType == 'amount', () => onToggleDiscountType('amount')),
              const SizedBox(width: 6),
              _typeChip('%', discountType == 'percent', () => onToggleDiscountType('percent')),
            ],
          ),
          if (computedDiscountAmount > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remise appliquée', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                Text(
                  '- ${formatter.format(computedDiscountAmount)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                ),
              ],
            ),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL NET', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                Text(
                  formatter.format(totalAmount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.primary : AppColors.textMedium,
      ),
    );
  }
}
