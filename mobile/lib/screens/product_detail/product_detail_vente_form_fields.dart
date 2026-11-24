import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../models/product.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';

class ProductInlineDateTile extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;

  const ProductInlineDateTile({super.key, required this.date, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Text(DateFormat('dd/MM/yyyy', 'fr_FR').format(date),
                style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class ProductInlineQtyPriceRow extends StatelessWidget {
  final Product product;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final VoidCallback onChanged;

  const ProductInlineQtyPriceRow({
    super.key,
    required this.product,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  final val = double.tryParse(qtyCtrl.text.trim()) ?? 1;
                  if (val > 1) {
                    final newQty = val - 1;
                    qtyCtrl.text = newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 1);
                    onChanged();
                  }
                },
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
              Expanded(
                child: TextFormField(
                  controller: qtyCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(labelText: 'Quantité *', suffixText: product.unit),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Quantité obligatoire';
                    final num = double.tryParse(val.trim());
                    if (num == null || num <= 0) return 'Quantité invalide (> 0)';
                    if (num > product.quantity) return 'Dépasse le stock disponible';
                    return null;
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  final val = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final newQty = val + 1;
                  if (newQty <= product.quantity) {
                    qtyCtrl.text = newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 1);
                    onChanged();
                  } else {
                    AppToast.showError(context, 'Stock insuffisant (${product.quantity.toStringAsFixed(0)} dispo).');
                  }
                },
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Prix unitaire *', suffixText: 'FCFA'),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Prix unitaire obligatoire';
              final num = double.tryParse(val.trim());
              if (num == null || num < 0) return 'Prix unitaire invalide';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class ProductInlineClientAutocomplete extends StatelessWidget {
  final TextEditingController clientCtrl;
  final FocusNode focusNode;
  final VoidCallback onChanged;

  const ProductInlineClientAutocomplete({
    super.key,
    required this.clientCtrl,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientProvider>(
      builder: (context, clientProvider, child) {
        return RawAutocomplete<Client>(
          textEditingController: clientCtrl,
          focusNode: focusNode,
          displayStringForOption: (Client option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return clientProvider.clients;
            return clientProvider.clients.where((Client client) {
              final nameMatch = client.name.toLowerCase().contains(query);
              final phoneMatch = client.phone != null && client.phone!.contains(query);
              return nameMatch || phoneMatch;
            });
          },
          onSelected: (Client selection) {
            clientCtrl.text = selection.name;
            clientCtrl.selection = TextSelection.fromPosition(TextPosition(offset: selection.name.length));
          },
          fieldViewBuilder: (context, controller, fNode, _) {
            return TextFormField(
              controller: controller,
              focusNode: fNode,
              decoration: InputDecoration(
                labelText: 'Client',
                hintText: 'Rechercher ou saisir un nom (vide = Non précisé)',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.clear();
                          onChanged();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.primarySurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) => onChanged(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  width: MediaQuery.of(context).size.width - 48,
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final Client option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primarySurface,
                          child: Icon(Icons.person, size: 14, color: AppColors.primary),
                        ),
                        title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: option.phone != null && option.phone!.isNotEmpty
                            ? Text(option.phone!, style: const TextStyle(fontSize: 11, color: AppColors.textLight))
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
