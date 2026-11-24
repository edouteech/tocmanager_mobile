import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'product_form_category_field.dart';
import 'product_form_pricing_fields.dart';
import 'product_form_save_helper.dart';
import 'product_image_processor_sheet.dart';

class ProductFormModal extends StatefulWidget {
  final Product? product;
  final String? initialName;
  final double? initialPrice;
  final Future<void> Function(Product) onSave;

  const ProductFormModal({
    super.key,
    this.product,
    this.initialName,
    this.initialPrice,
    required this.onSave,
  });

  @override
  State<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<ProductFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.product?.name ?? widget.initialName ?? '');
  late final _descCtrl = TextEditingController(text: widget.product?.description ?? '');
  late final _priceCtrl = initProductNumericCtrl(widget.product?.price ?? widget.initialPrice);
  late final _priceSemiWholesaleCtrl = initProductNumericCtrl(widget.product?.priceSemiWholesale);
  late final _minQtySemiWholesaleCtrl = initProductNumericCtrl(widget.product?.minQtySemiWholesale);
  late final _priceWholesaleCtrl = initProductNumericCtrl(widget.product?.priceWholesale);
  late final _minQtyWholesaleCtrl = initProductNumericCtrl(widget.product?.minQtyWholesale);
  late final _costCtrl = initProductNumericCtrl(widget.product?.costPrice, zeroAsEmpty: false);
  late final _qtyCtrl = initProductNumericCtrl(widget.product?.quantity, zeroAsEmpty: false);
  late final _alertCtrl = initProductNumericCtrl(widget.product?.alertQuantity, zeroAsEmpty: false, fallback: '5');
  late final TextEditingController _categoryCtrl;
  final _categoryFocusNode = FocusNode();
  late int? _categoryId = widget.product?.categoryId;
  late int? _supplierId = widget.product?.supplierId;
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.product?.imagePath;
    String initCatName = '';
    if (widget.product?.categoryId != null) {
      final cat =
          context.read<CategoryProvider>().categories.where((c) => c.id == widget.product!.categoryId).firstOrNull;
      if (cat != null) initCatName = cat.name;
    }
    _categoryCtrl = TextEditingController(text: initCatName);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SupplierProvider>().loadSuppliers());
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _categoryCtrl,
      _priceCtrl,
      _priceSemiWholesaleCtrl,
      _minQtySemiWholesaleCtrl,
      _priceWholesaleCtrl,
      _minQtyWholesaleCtrl,
      _costCtrl,
      _qtyCtrl,
      _alertCtrl,
    ]) {
      c.dispose();
    }
    _categoryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    final xFile = await ImagePicker().pickImage(source: source, maxWidth: 1200, maxHeight: 1200);
    if (xFile == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ProductImageProcessorSheet(
        sourcePath: xFile.path,
        onConfirm: (bytes) => setState(() => _imageBytes = bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Modifier le produit' : 'Nouveau produit',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textMedium)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductFormImageTile(
                    imageBytes: _imageBytes,
                    imagePath: _imagePath,
                    onTap: () => showProductImageSourceSheet(
                      context,
                      hasImage: _imageBytes != null || _imagePath != null,
                      onPick: _pickAndProcess,
                      onClear: () => setState(() { _imageBytes = null; _imagePath = null; }),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom du produit *', hintText: 'Ex: Smartphone X12'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Nom du produit obligatoire';
                        if (val.trim().length < 2) return 'Au moins 2 caractères';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Description optionnelle'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ProductCategoryAutocomplete(
                categoryCtrl: _categoryCtrl,
                focusNode: _categoryFocusNode,
                onSelectCategory: (id, _) => setState(() => _categoryId = id),
                onAddCategoryTap: () => showQuickAddCategoryDialog(
                  context,
                  (id, name) => setState(() { _categoryId = id; _categoryCtrl.text = name; }),
                ),
              ),
              const SizedBox(height: 12),
              ProductFormPricingFields(
                supplierId: _supplierId,
                onSupplierChanged: (v) => setState(() => _supplierId = v),
                priceCtrl: _priceCtrl,
                costCtrl: _costCtrl,
                priceSemiWholesaleCtrl: _priceSemiWholesaleCtrl,
                minQtySemiWholesaleCtrl: _minQtySemiWholesaleCtrl,
                priceWholesaleCtrl: _priceWholesaleCtrl,
                minQtyWholesaleCtrl: _minQtyWholesaleCtrl,
                qtyCtrl: _qtyCtrl,
                alertCtrl: _alertCtrl,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Modifier' : 'Créer le produit'),
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
      AppToast.showError(context, 'Veuillez corriger les champs invalides du produit.');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await executeSaveProductForm(
        context,
        existingProduct: widget.product,
        name: name,
        description: _descCtrl.text,
        categoryText: _categoryCtrl.text,
        supplierId: _supplierId ?? (_categoryId == null ? null : _supplierId),
        price: double.tryParse(_priceCtrl.text) ?? 0,
        priceSemiWholesale: double.tryParse(_priceSemiWholesaleCtrl.text) ?? 0,
        priceWholesale: double.tryParse(_priceWholesaleCtrl.text) ?? 0,
        minQtySemiWholesale: double.tryParse(_minQtySemiWholesaleCtrl.text) ?? 0,
        minQtyWholesale: double.tryParse(_minQtyWholesaleCtrl.text) ?? 0,
        costPrice: double.tryParse(_costCtrl.text) ?? 0,
        quantity: double.tryParse(_qtyCtrl.text) ?? 0,
        alertQuantity: double.tryParse(_alertCtrl.text) ?? 5,
        imageBytes: _imageBytes,
        imagePath: _imagePath,
        onSave: widget.onSave,
      );
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'Une erreur est survenue. Veuillez réessayer.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
