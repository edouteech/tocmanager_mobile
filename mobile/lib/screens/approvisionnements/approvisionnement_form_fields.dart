import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';

class ApprovisionSupplierSelector extends StatelessWidget {
  final int? selectedSupplierId;
  final TextEditingController supplierCtrl;
  final void Function(int? id, String? name) onSupplierChanged;

  const ApprovisionSupplierSelector({
    super.key,
    required this.selectedSupplierId,
    required this.supplierCtrl,
    required this.onSupplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(
      builder: (context, supplierProv, child) {
        final suppliers = supplierProv.suppliers;
        final validSupplierId = suppliers.any((s) => s.id == selectedSupplierId) ? selectedSupplierId : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int?>(
              key: ValueKey(validSupplierId),
              initialValue: validSupplierId,
              decoration: InputDecoration(
                labelText: 'Sélectionner un Fournisseur',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Aucun / Saisie libre')),
                ...suppliers.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
              ],
              onChanged: (val) {
                if (val != null) {
                  final s = suppliers.firstWhere((item) => item.id == val);
                  onSupplierChanged(val, s.name);
                } else {
                  onSupplierChanged(null, null);
                }
              },
            ),
            if (selectedSupplierId == null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: supplierCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du Fournisseur (Saisie libre)',
                  hintText: 'Ex: Nestlé CI',
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ApprovisionPaymentSection extends StatelessWidget {
  final bool isFullPayment;
  final TextEditingController paidCtrl;
  final double remaining;
  final NumberFormat formatter;
  final ValueChanged<bool> onFullPaymentChanged;
  final VoidCallback onPaidChanged;

  const ApprovisionPaymentSection({
    super.key,
    required this.isFullPayment,
    required this.paidCtrl,
    required this.remaining,
    required this.formatter,
    required this.onFullPaymentChanged,
    required this.onPaidChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Règlement Fournisseur', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Payé Cash')),
                selected: isFullPayment,
                selectedColor: AppColors.success,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: isFullPayment ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (val) {
                  if (val) onFullPaymentChanged(true);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Règlement partiel / Crédit')),
                selected: !isFullPayment,
                selectedColor: AppColors.danger,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: !isFullPayment ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (val) {
                  if (val) onFullPaymentChanged(false);
                },
              ),
            ),
          ],
        ),
        if (!isFullPayment) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: paidCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => onPaidChanged(),
            decoration: const InputDecoration(
              labelText: 'Montant Acompte Versé (FCFA)',
              suffixText: 'F',
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Reliquat restant dû (Crédit Fournisseur) : ${formatter.format(remaining)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
            ),
          ],
        ],
      ],
    );
  }
}

class ApprovisionDateAndNotesFields extends StatelessWidget {
  final DateTime date;
  final TextEditingController notesCtrl;
  final VoidCallback onPickDate;

  const ApprovisionDateAndNotesFields({
    super.key,
    required this.date,
    required this.notesCtrl,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text(
                  DateFormat('dd/MM/yyyy', 'fr_FR').format(date),
                  style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(labelText: 'Notes', hintText: 'Remarques optionnelles'),
          maxLines: 2,
        ),
      ],
    );
  }
}
