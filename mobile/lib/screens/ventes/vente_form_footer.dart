import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class VenteFormDateNotesAndSubmit extends StatelessWidget {
  final DateTime date;
  final TextEditingController notesCtrl;
  final ValueChanged<DateTime> onDateChanged;
  final bool saving;
  final bool isEditing;
  final double netTotal;
  final NumberFormat formatter;
  final VoidCallback onSubmit;

  const VenteFormDateNotesAndSubmit({
    super.key,
    required this.date,
    required this.notesCtrl,
    required this.onDateChanged,
    required this.saving,
    required this.isEditing,
    required this.netTotal,
    required this.formatter,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  onDateChanged(DateTime(picked.year, picked.month, picked.day, date.hour, date.minute));
                }
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(dateFmt.format(date)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(hintText: 'Note optionnelle...'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: saving ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  isEditing
                      ? 'Mettre à jour (${formatter.format(netTotal)})'
                      : 'Encaisser (${formatter.format(netTotal)})',
                ),
        ),
      ],
    );
  }
}
