import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const ClientCard({
    super.key,
    required this.client,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDebt = client.balance > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: hasDebt ? AppColors.warning.withAlpha(30) : AppColors.primarySurface,
                child: Text(
                  client.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: hasDebt ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                    if (client.phone != null && client.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMedium),
                          const SizedBox(width: 4),
                          Text(client.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasDebt ? AppColors.warning.withAlpha(30) : AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasDebt ? 'Créance: ${formatter.format(client.balance)}' : 'À jour',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: hasDebt ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void confirmDeleteClientDialog(BuildContext context, Client client, ClientProvider provider) {
  if (client.balance > 0) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text('Suppression impossible', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Le client "${client.name}" a un solde débiteur actif de ${formatter.format(client.balance)}.\n\nVeuillez d\'abord solder la créance avant de supprimer ce client.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer client', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Supprimer "${client.name}" ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            await provider.deleteClient(client.id!);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
