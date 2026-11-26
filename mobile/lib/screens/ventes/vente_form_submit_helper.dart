import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/client.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../providers/client_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_toast.dart';
import '../products_screen.dart';
import 'vente_filter_helpers.dart';
import 'vente_form_pricing_helper.dart';

Future<({List<VenteItem> items, String? error, bool added})> tryAddItemToVenteCart(
  BuildContext context, {
  required ProductProvider productProvider,
  required Product? selectedProduct,
  required String typedName,
  required String qtyText,
  required String priceText,
  required String clientName,
  required List<VenteItem> currentItems,
  required Vente? initialVente,
}) async {
  final qty = double.tryParse(qtyText.trim().replaceAll(',', '.')) ?? 0.0;
  if (qty <= 0) {
    return (items: currentItems, error: 'Quantité invalide (> 0).', added: false);
  }
  Product? prod = selectedProduct ??
      productProvider.products.where((p) => p.name.trim().toLowerCase() == typedName.toLowerCase()).firstOrNull;
  if (prod == null) {
    if (typedName.isEmpty) {
      return (items: currentItems, error: 'Sélectionnez ou saisissez un produit.', added: false);
    }
    final typedPrice = double.tryParse(priceText.trim().replaceAll(',', '.'));
    prod = await promptCreateNewProductForSale(
      context,
      typedName: typedName,
      initialPrice: typedPrice,
      productProvider: productProvider,
    );
    if (prod == null || !context.mounted) {
      return (items: currentItems, error: null, added: false);
    }
  }
  final avail = computeAvailableStockForProduct(
    productId: prod.id,
    productStock: prod.quantity,
    saleItems: currentItems,
    initialVente: initialVente,
  );
  if (qty > avail) {
    return (items: currentItems, error: 'Stock insuffisant (disponible : ${formatVenteQty(avail)}).', added: false);
  }
  final parsedPrice = double.tryParse(priceText.trim().replaceAll(',', '.'));
  final unitPrice = (parsedPrice != null && parsedPrice > 0)
      ? parsedPrice
      : resolveVenteUnitPrice(prod, context.read<ClientProvider>().clients, qty: qty, clientName: clientName);
  final useAvg = context.read<SettingsProvider>().settings.enableAverageCostPrice;
  final next = buildUpdatedCartAfterAdd(
    currentItems: currentItems,
    product: prod,
    qty: qty,
    unitPrice: unitPrice,
    useAverageCostPrice: useAvg,
  );
  return (items: next, error: null, added: true);
}

Future<Product?> promptCreateNewProductForSale(
  BuildContext context, {
  required String typedName,
  required double? initialPrice,
  required ProductProvider productProvider,
}) async {
  final shouldCreate = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Produit non enregistré', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Voulez-vous créer "$typedName" dans votre catalogue maintenant ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Créer le produit')),
      ],
    ),
  );
  if (shouldCreate != true || !context.mounted) return null;

  Product? created;
  final popped = await showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => ProductFormModal(
      initialName: typedName,
      initialPrice: initialPrice,
      onSave: (p) async {
        created = await productProvider.add(p);
      },
    ),
  );
  return popped ?? created;
}

Future<void> submitVenteForm(
  BuildContext context, {
  required Vente? initialVente,
  required List<VenteItem> saleItems,
  required String rawClientInput,
  required String paidText,
  required double totalAmount,
  required double discountAmount,
  required String paymentMethod,
  required DateTime date,
  required String notes,
  required Future<void> Function(Vente) onSave,
}) async {
  if (saleItems.isEmpty) {
    AppToast.showError(context, 'Ajoutez au moins un article au panier.');
    return;
  }

  final paidAmount = double.tryParse(paidText.trim().replaceAll(',', '.')) ??
      (paymentMethod == 'Crédit' ? 0.0 : totalAmount);
  final trimmedClient = rawClientInput.trim();
  final clientProvider = context.read<ClientProvider>();

  int? clientId;
  String? clientName;
  if (trimmedClient.isNotEmpty && trimmedClient.toLowerCase() != 'occasionnel') {
    final existing = clientProvider.clients
        .where((c) => c.name.trim().toLowerCase() == trimmedClient.toLowerCase())
        .firstOrNull;
    if (existing != null) {
      clientId = existing.id;
      clientName = existing.name;
    } else {
      clientName = trimmedClient;
      clientId = await clientProvider.addClient(Client(name: trimmedClient));
    }
  }

  final venteSyncId = initialVente?.syncId ?? const Uuid().v4();
  final ticketSuffix = venteSyncId.replaceAll('-', '').substring(0, 4).toUpperCase();
  final ticketNumber = initialVente?.ticketNumber.isNotEmpty == true
      ? initialVente!.ticketNumber
      : 'VNT-${DateFormat('yyyyMMddHHmmss').format(date)}-$ticketSuffix';

  final vente = Vente(
    id: initialVente?.id,
    syncId: venteSyncId,
    ticketNumber: ticketNumber,
    clientId: clientId,
    clientName: clientName,
    totalAmount: totalAmount,
    discountAmount: discountAmount,
    paidAmount: paidAmount,
    paymentMethod: paymentMethod,
    date: date,
    notes: notes.trim().isEmpty ? null : notes.trim(),
    items: saleItems,
  );

  await onSave(vente);
  if (!context.mounted) return;

  if (initialVente != null) {
    AppToast.showSuccess(context, 'Vente $ticketNumber mise à jour.');
  } else if (paidAmount > totalAmount + 0.01 && clientName != null) {
    AppToast.showSuccess(context, 'Vente enregistrée avec surplus ajouté en avoir pour $clientName.');
  } else {
    AppToast.showSuccess(context, 'Vente $ticketNumber enregistrée.');
  }
  Navigator.pop(context);
}
