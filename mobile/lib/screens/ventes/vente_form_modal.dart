import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../providers/client_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import 'vente_form_body.dart';
import 'vente_form_edit_price_dialog.dart';
import 'vente_form_pricing_helper.dart';
import 'vente_form_submit_helper.dart';

class VenteFormModal extends StatefulWidget {
  final Vente? initialVente;
  final Future<void> Function(Vente) onSave;

  const VenteFormModal({super.key, this.initialVente, required this.onSave});

  @override
  State<VenteFormModal> createState() => _VenteFormModalState();
}

class _VenteFormModalState extends State<VenteFormModal> {
  final _ctrls = VenteFormControllers();
  late DateTime _date;
  late String _paymentMethod;
  String _discountType = 'amount';
  List<VenteItem> _saleItems = [];
  Product? _selectedProduct;
  bool _hasCustomPaid = false;
  bool _saving = false;
  String? _itemError;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVente;
    _date = v?.date ?? DateTime.now();
    _paymentMethod = v?.paymentMethod ?? 'Espèces';
    if (v != null) {
      _saleItems = v.items.map((e) => e.copyWith()).toList();
      _hasCustomPaid = true;
    }
    _ctrls.initFromVente(v);
  }

  @override
  void dispose() {
    _ctrls.dispose();
    super.dispose();
  }

  double get _subtotal => _saleItems.fold(0.0, (sum, item) => sum + item.total);

  double get _discount => computeVenteDiscountAmount(
        double.tryParse(_ctrls.discountCtrl.text.trim().replaceAll(',', '.')) ?? 0.0,
        _subtotal,
        _discountType,
      );

  double get _netTotal => (_subtotal - _discount).clamp(0.0, double.infinity);

  void _syncPaid() {
    if (_hasCustomPaid) return;
    _ctrls.paidCtrl.text = _paymentMethod == 'Crédit' ? '0' : _netTotal.toStringAsFixed(0);
  }

  void _onSelectProduct(Product prod) {
    final qty = double.tryParse(_ctrls.qtyCtrl.text.trim()) ?? 1.0;
    final price = resolveVenteUnitPrice(
      prod,
      context.read<ClientProvider>().clients,
      qty: qty,
      clientName: _ctrls.clientCtrl.text,
    );
    setState(() {
      _selectedProduct = prod;
      _ctrls.productCtrl.text = prod.name;
      _ctrls.priceCtrl.text = price.toStringAsFixed(0);
      _itemError = null;
    });
  }

  Future<void> _handleAddItem(ProductProvider productProvider) async {
    final res = await tryAddItemToVenteCart(
      context,
      productProvider: productProvider,
      selectedProduct: _selectedProduct,
      typedName: _ctrls.productCtrl.text.trim(),
      qtyText: _ctrls.qtyCtrl.text,
      priceText: _ctrls.priceCtrl.text,
      clientName: _ctrls.clientCtrl.text,
      currentItems: _saleItems,
      initialVente: widget.initialVente,
    );
    if (!mounted) return;
    setState(() {
      _saleItems = res.items;
      _itemError = res.error;
      if (res.added) {
        _selectedProduct = null;
        _ctrls.productCtrl.clear();
        _ctrls.qtyCtrl.text = '1';
        _ctrls.priceCtrl.clear();
        _syncPaid();
      }
    });
  }

  void _repriceForClient(Client? override) {
    setState(() {
      _saleItems = repriceCartItemsForClient(
        currentItems: _saleItems,
        products: context.read<ProductProvider>().products,
        clients: context.read<ClientProvider>().clients,
        clientName: _ctrls.clientCtrl.text,
        clientOverride: override,
      );
      _syncPaid();
    });
  }

  void _changeCartQty(int idx, int delta, List<Product> products) {
    final res = applyVenteCartQtyDelta(
      currentItems: _saleItems,
      index: idx,
      delta: delta,
      catalogProducts: products,
      initialVente: widget.initialVente,
    );
    setState(() {
      _saleItems = res.items;
      if (res.error != null) _itemError = res.error;
      _syncPaid();
    });
  }

  void _editUnitPrice(int idx, VenteItem item, Product? prod, ProductProvider prodProv) {
    showVenteEditUnitPriceModal(
      context,
      item: item,
      prod: prod,
      onConfirm: (newPrice, target) async {
        if (target == 'global_catalog' && prod != null) {
          await prodProv.update(prod.copyWith(price: newPrice, updatedAt: DateTime.now()));
        }
        setState(() {
          _saleItems[idx] = item.copyWith(unitPrice: newPrice, total: item.quantity * newPrice);
          _syncPaid();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsProvider>().settings.currency;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: currency, decimalDigits: 0);

    return VenteFormSheetFrame(
      isEditing: widget.initialVente != null,
      child: VenteFormSectionsBody(
        ctrls: _ctrls,
        saleItems: _saleItems,
        itemError: _itemError,
        discountType: _discountType,
        paymentMethod: _paymentMethod,
        date: _date,
        subtotal: _subtotal,
        computedDiscount: _discount,
        netTotal: _netTotal,
        saving: _saving,
        isEditing: widget.initialVente != null,
        formatter: formatter,
        onSelectProduct: _onSelectProduct,
        onProductTextChanged: (_) => setState(() { _selectedProduct = null; _itemError = null; }),
        onClearProduct: () => setState(() { _selectedProduct = null; _ctrls.productCtrl.clear(); _ctrls.priceCtrl.clear(); }),
        onInputChanged: () => setState(() => _itemError = null),
        onAddItem: _handleAddItem,
        onEditUnitPrice: _editUnitPrice,
        onDecrement: (idx) => _changeCartQty(idx, -1, const []),
        onIncrement: (idx, prov) => _changeCartQty(idx, 1, prov.products),
        onRemove: (idx) => setState(() { _saleItems.removeAt(idx); _syncPaid(); }),
        onSelectTierPrice: (idx, price) => setState(() {
          _saleItems[idx] = _saleItems[idx].copyWith(unitPrice: price, total: _saleItems[idx].quantity * price);
          _syncPaid();
        }),
        onToggleDiscountType: (t) => setState(() { _discountType = t; _syncPaid(); }),
        onDiscountChanged: () => setState(_syncPaid),
        onClientSelected: _repriceForClient,
        onClientChanged: () => _repriceForClient(null),
        onUseAvoir: (newPaid, _) => setState(() { _hasCustomPaid = true; _ctrls.paidCtrl.text = newPaid.toStringAsFixed(0); }),
        onSelectPaymentMethod: (mode) => setState(() { _paymentMethod = mode; _hasCustomPaid = false; _syncPaid(); }),
        onSelectQuickAmount: (val) => setState(() { _hasCustomPaid = true; _ctrls.paidCtrl.text = val; }),
        onCustomPaidChanged: () => setState(() => _hasCustomPaid = true),
        onDateChanged: (d) => setState(() => _date = d),
        onSubmit: _submitForm,
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() => _saving = true);
    try {
      await submitVenteForm(
        context,
        initialVente: widget.initialVente,
        saleItems: _saleItems,
        rawClientInput: _ctrls.clientCtrl.text,
        paidText: _ctrls.paidCtrl.text,
        totalAmount: _netTotal,
        discountAmount: _discount,
        paymentMethod: _paymentMethod,
        date: _date,
        notes: _ctrls.notesCtrl.text,
        onSave: widget.onSave,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
