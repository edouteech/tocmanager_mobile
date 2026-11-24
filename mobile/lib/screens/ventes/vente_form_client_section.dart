import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';

class VenteFormClientSection extends StatelessWidget {
  final TextEditingController clientCtrl;
  final FocusNode clientFocusNode;
  final double totalAmount;
  final NumberFormat formatter;
  final ValueChanged<Client> onClientSelected;
  final VoidCallback onClientChanged;
  final void Function(double newPaid, double avoir) onUseAvoir;

  const VenteFormClientSection({
    super.key,
    required this.clientCtrl,
    required this.clientFocusNode,
    required this.totalAmount,
    required this.formatter,
    required this.onClientSelected,
    required this.onClientChanged,
    required this.onUseAvoir,
  });

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<ClientProvider>().clients;
    final normalized = clientCtrl.text.trim().toLowerCase();
    final matched = normalized.isEmpty
        ? null
        : clients.where((c) => c.name.trim().toLowerCase() == normalized).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Client',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        RawAutocomplete<Client>(
          textEditingController: clientCtrl,
          focusNode: clientFocusNode,
          displayStringForOption: (c) => c.name,
          optionsBuilder: (val) {
            final q = val.text.trim().toLowerCase();
            if (q.isEmpty) return clients.take(12);
            return clients.where(
              (c) => c.name.toLowerCase().contains(q) || (c.phone ?? '').toLowerCase().contains(q),
            );
          },
          onSelected: onClientSelected,
          fieldViewBuilder: (ctx, ctrl, focus, onSubmitted) => TextField(
            controller: ctrl,
            focusNode: focus,
            onChanged: (_) => onClientChanged(),
            decoration: const InputDecoration(
              hintText: 'Nom du client (laisser vide = Occasionnel)',
              prefixIcon: Icon(Icons.person_outline, size: 18, color: AppColors.primary),
            ),
          ),
          optionsViewBuilder: (ctx, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 420),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (_, idx) {
                    final c = options.elementAt(idx);
                    return ListTile(
                      dense: true,
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(c.typeLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                      trailing: _buildBalanceBadge(c),
                      onTap: () => onSelected(c),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (matched != null && matched.hasAvoir && totalAmount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.purple.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: AppColors.purple, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Avoir disponible : ${formatter.format(matched.avoirAmount)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purple),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final used = matched.avoirAmount >= totalAmount ? totalAmount : matched.avoirAmount;
                    onUseAvoir(used, matched.avoirAmount);
                  },
                  child: const Text('Utiliser l\'avoir', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildBalanceBadge(Client c) {
    if (c.hasCreance) {
      return Text(
        'Dette: ${formatter.format(c.creanceAmount)}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
      );
    }
    if (c.hasAvoir) {
      return Text(
        'Avoir: ${formatter.format(c.avoirAmount)}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.purple),
      );
    }
    return null;
  }
}
