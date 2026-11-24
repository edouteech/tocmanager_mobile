import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'product_detail_vente_form_fields.dart';

class ProductVenteInlineForm extends StatefulWidget {
  final Product product;
  final Future<void> Function(Vente) onSave;

  const ProductVenteInlineForm({super.key, required this.product, required this.onSave});

  @override
  State<ProductVenteInlineForm> createState() => _ProductVenteInlineFormState();
}

class _ProductVenteInlineFormState extends State<ProductVenteInlineForm> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController(text: '1');
  final _clientCtrl = TextEditingController();
  final _clientFocusNode = FocusNode();
  final _notesCtrl = TextEditingController();
  late final _priceCtrl = TextEditingController(text: widget.product.price.toStringAsFixed(0));
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _clientCtrl.dispose();
    _clientFocusNode.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vendre — ${widget.product.name}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMedium),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Stock disponible : ${widget.product.quantity.toStringAsFixed(0)} ${widget.product.unit}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              ProductInlineQtyPriceRow(
                product: widget.product,
                qtyCtrl: _qtyCtrl,
                priceCtrl: _priceCtrl,
                onChanged: () => setState(() {}),
              ),
              if (_total > 0) ...[
                const SizedBox(height: 8),
                Text('Total : ${formatter.format(_total)}',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
              const SizedBox(height: 12),
              ProductInlineClientAutocomplete(
                clientCtrl: _clientCtrl,
                focusNode: _clientFocusNode,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              ProductInlineDateTile(
                date: _date,
                onDateSelected: (picked) => setState(() => _date = picked),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', hintText: 'Remarques optionnelles'),
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Enregistrer la vente'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez corriger la quantité ou le prix de vente.');
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text);
    final price = double.tryParse(_priceCtrl.text);
    if (qty == null || qty <= 0 || price == null) return;
    if (qty > widget.product.quantity) {
      AppToast.showError(
        context,
        'Stock insuffisant (${widget.product.quantity.toStringAsFixed(0)} ${widget.product.unit} disponible).',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final clientProvider = context.read<ClientProvider>();
      final rawClientInput = _clientCtrl.text.trim();
      int? clientId;
      String clientName;

      if (rawClientInput.isEmpty) {
        clientName = 'Non précisé';
        final existingDefault = clientProvider.clients
            .where((c) => c.name.trim().toLowerCase() == 'non précisé' || c.name.trim().toLowerCase() == 'non precise')
            .firstOrNull;
        clientId = existingDefault != null
            ? existingDefault.id
            : await clientProvider.addClient(Client(name: 'Non précisé', notes: 'Client par défaut'));
      } else {
        final existingClient = clientProvider.clients
            .where((c) => c.name.trim().toLowerCase() == rawClientInput.toLowerCase())
            .firstOrNull;
        if (existingClient != null) {
          clientId = existingClient.id;
          clientName = existingClient.name;
        } else {
          clientName = rawClientInput;
          clientId = await clientProvider.addClient(Client(name: rawClientInput));
        }
      }

      final vente = Vente(
        ticketNumber: '',
        clientId: clientId,
        clientName: clientName,
        totalAmount: qty * price,
        paidAmount: qty * price,
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        items: [
          VenteItem(
            productId: widget.product.id!,
            productName: widget.product.name,
            quantity: qty,
            unitPrice: price,
            total: qty * price,
          ),
        ],
      );
      await widget.onSave(vente);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) AppToast.showError(context, 'Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
