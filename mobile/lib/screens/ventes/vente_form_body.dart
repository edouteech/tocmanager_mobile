import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/client.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import 'vente_form_cart_list.dart';
import 'vente_form_client_section.dart';
import 'vente_form_discount_card.dart';
import 'vente_form_footer.dart';
import 'vente_form_payment_section.dart';
import 'vente_form_product_picker.dart';

class VenteFormControllers {
  final productCtrl = TextEditingController();
  final productFocusNode = FocusNode();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();
  final paidCtrl = TextEditingController();
  final clientCtrl = TextEditingController();
  final clientFocusNode = FocusNode();
  final notesCtrl = TextEditingController();
  final discountCtrl = TextEditingController();

  void initFromVente(Vente? v) {
    if (v != null) {
      clientCtrl.text = v.clientName ?? '';
      notesCtrl.text = v.notes ?? '';
      paidCtrl.text = v.paidAmount.toStringAsFixed(0);
      if (v.discountAmount > 0) discountCtrl.text = v.discountAmount.toStringAsFixed(0);
    } else {
      paidCtrl.text = '0';
    }
  }

  void dispose() {
    for (final c in [productCtrl, qtyCtrl, priceCtrl, paidCtrl, clientCtrl, notesCtrl, discountCtrl]) {
      c.dispose();
    }
    productFocusNode.dispose();
    clientFocusNode.dispose();
  }
}

class VenteFormSheetFrame extends StatelessWidget {
  final bool isEditing;
  final Widget child;

  const VenteFormSheetFrame({super.key, required this.isEditing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Modifier la vente' : 'Nouvelle vente',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class VenteFormSectionsBody extends StatelessWidget {
  final VenteFormControllers ctrls;
  final List<VenteItem> saleItems;
  final String? itemError;
  final String discountType;
  final String paymentMethod;
  final DateTime date;
  final double subtotal;
  final double computedDiscount;
  final double netTotal;
  final bool saving;
  final bool isEditing;
  final NumberFormat formatter;
  final ValueChanged<Product> onSelectProduct;
  final ValueChanged<String> onProductTextChanged;
  final VoidCallback onClearProduct;
  final VoidCallback onInputChanged;
  final ValueChanged<ProductProvider> onAddItem;
  final void Function(int, VenteItem, Product?, ProductProvider) onEditUnitPrice;
  final ValueChanged<int> onDecrement;
  final void Function(int, ProductProvider) onIncrement;
  final ValueChanged<int> onRemove;
  final void Function(int, double) onSelectTierPrice;
  final ValueChanged<String> onToggleDiscountType;
  final VoidCallback onDiscountChanged;
  final ValueChanged<Client> onClientSelected;
  final VoidCallback onClientChanged;
  final void Function(double, double) onUseAvoir;
  final ValueChanged<String> onSelectPaymentMethod;
  final ValueChanged<String> onSelectQuickAmount;
  final VoidCallback onCustomPaidChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onSubmit;

  const VenteFormSectionsBody({
    super.key,
    required this.ctrls,
    required this.saleItems,
    required this.itemError,
    required this.discountType,
    required this.paymentMethod,
    required this.date,
    required this.subtotal,
    required this.computedDiscount,
    required this.netTotal,
    required this.saving,
    required this.isEditing,
    required this.formatter,
    required this.onSelectProduct,
    required this.onProductTextChanged,
    required this.onClearProduct,
    required this.onInputChanged,
    required this.onAddItem,
    required this.onEditUnitPrice,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
    required this.onSelectTierPrice,
    required this.onToggleDiscountType,
    required this.onDiscountChanged,
    required this.onClientSelected,
    required this.onClientChanged,
    required this.onUseAvoir,
    required this.onSelectPaymentMethod,
    required this.onSelectQuickAmount,
    required this.onCustomPaidChanged,
    required this.onDateChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VenteFormProductPicker(
          productCtrl: ctrls.productCtrl,
          productFocusNode: ctrls.productFocusNode,
          qtyCtrl: ctrls.qtyCtrl,
          priceCtrl: ctrls.priceCtrl,
          saleItems: saleItems,
          itemError: itemError,
          onSelectProduct: onSelectProduct,
          onProductTextChanged: onProductTextChanged,
          onClearProduct: onClearProduct,
          onInputChanged: onInputChanged,
          onAddItem: onAddItem,
        ),
        const SizedBox(height: 12),
        VenteFormCartList(
          saleItems: saleItems,
          formatter: formatter,
          totalAmount: subtotal,
          onEditUnitPrice: onEditUnitPrice,
          onDecrement: onDecrement,
          onIncrement: onIncrement,
          onRemove: onRemove,
          onSelectTierPrice: onSelectTierPrice,
        ),
        const SizedBox(height: 12),
        VenteFormDiscountCard(
          subtotalAmount: subtotal,
          computedDiscountAmount: computedDiscount,
          totalAmount: netTotal,
          discountCtrl: ctrls.discountCtrl,
          discountType: discountType,
          formatter: formatter,
          onToggleDiscountType: onToggleDiscountType,
          onDiscountChanged: onDiscountChanged,
        ),
        const SizedBox(height: 14),
        VenteFormClientSection(
          clientCtrl: ctrls.clientCtrl,
          clientFocusNode: ctrls.clientFocusNode,
          totalAmount: netTotal,
          formatter: formatter,
          onClientSelected: onClientSelected,
          onClientChanged: onClientChanged,
          onUseAvoir: onUseAvoir,
        ),
        const SizedBox(height: 14),
        VenteFormPaymentSection(
          paymentMethod: paymentMethod,
          paidCtrl: ctrls.paidCtrl,
          totalAmount: netTotal,
          formatter: formatter,
          onSelectPaymentMethod: onSelectPaymentMethod,
          onSelectQuickAmount: onSelectQuickAmount,
          onCustomPaidChanged: onCustomPaidChanged,
        ),
        const SizedBox(height: 12),
        VenteFormDateNotesAndSubmit(
          date: date,
          notesCtrl: ctrls.notesCtrl,
          onDateChanged: onDateChanged,
          saving: saving,
          isEditing: isEditing,
          netTotal: netTotal,
          formatter: formatter,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}
