import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

const List<String> _kPaymentModes = ['Espèces', 'Mobile Money', 'Carte', 'Crédit'];
const List<int> _kQuickCashAmounts = [1000, 2000, 5000, 10000, 20000];

class VenteFormPaymentSection extends StatelessWidget {
  final String paymentMethod;
  final TextEditingController paidCtrl;
  final double totalAmount;
  final NumberFormat formatter;
  final ValueChanged<String> onSelectPaymentMethod;
  final ValueChanged<String> onSelectQuickAmount;
  final VoidCallback onCustomPaidChanged;

  const VenteFormPaymentSection({
    super.key,
    required this.paymentMethod,
    required this.paidCtrl,
    required this.totalAmount,
    required this.formatter,
    required this.onSelectPaymentMethod,
    required this.onSelectQuickAmount,
    required this.onCustomPaidChanged,
  });

  @override
  Widget build(BuildContext context) {
    final paid = double.tryParse(paidCtrl.text.trim()) ?? 0.0;
    final hasChange = totalAmount > 0 && paid > totalAmount + 0.01;
    final hasCredit = totalAmount > 0 && paid < totalAmount - 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mode de paiement',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _kPaymentModes.map((mode) {
            final selected = paymentMethod == mode;
            return ChoiceChip(
              label: Text(mode),
              selected: selected,
              onSelected: (_) => onSelectPaymentMethod(mode),
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textMedium,
              ),
            );
          }).toList(),
        ),
        if (paymentMethod == 'Espèces' && totalAmount > 0) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: const Text('Exact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    backgroundColor: AppColors.successLight,
                    onPressed: () => onSelectQuickAmount(totalAmount.toStringAsFixed(0)),
                  ),
                ),
                ..._kQuickCashAmounts.map(
                  (amt) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text('$amt', style: const TextStyle(fontSize: 11)),
                      onPressed: () => onSelectQuickAmount(amt.toString()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: paidCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onCustomPaidChanged(),
          decoration: const InputDecoration(
            labelText: 'Montant encaissé (FCFA)',
            prefixIcon: Icon(Icons.payments_outlined, size: 18, color: AppColors.success),
          ),
        ),
        if (hasChange) ...[
          const SizedBox(height: 8),
          _statusBanner(
            'Monnaie à rendre : ${formatter.format(paid - totalAmount)}',
            AppColors.success,
            AppColors.successLight,
          ),
        ] else if (hasCredit) ...[
          const SizedBox(height: 8),
          _statusBanner(
            'Reliquat à crédit client : ${formatter.format(totalAmount - paid)}',
            AppColors.warning,
            AppColors.warningLight,
          ),
        ],
      ],
    );
  }

  Widget _statusBanner(String message, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
