import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/approvisionnement.dart';
import '../models/product.dart';
import '../providers/approvisionnement_provider.dart';
import '../providers/category_provider.dart';
import '../providers/client_provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/vente_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'product_detail/product_detail_appro_form.dart';
import 'product_detail/product_detail_appro_history.dart';
import 'product_detail/product_detail_header.dart';
import 'product_detail/product_detail_info_cards.dart';
import 'product_detail/product_detail_price_card.dart';
import 'product_detail/product_detail_vente_form.dart';
import 'product_detail/product_detail_vente_history.dart';
import 'products_screen.dart' show ProductFormModal;

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovisionnementProvider>().load(productId: _product.id);
      context.read<VenteProvider>().load(productId: _product.id);
      context.read<ClientProvider>().loadClients();
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  Future<void> _refreshProduct() async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.load();
    final updated = productProvider.products.where((p) => p.id == _product.id).firstOrNull;
    if (updated != null && mounted) setState(() => _product = updated);
  }

  Future<void> _editProduct() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ProductFormModal(
        product: _product,
        onSave: (p) async {
          await context.read<ProductProvider>().update(p);
          await _refreshProduct();
          if (mounted) AppToast.showSuccess(context, 'Produit mis à jour avec succès');
        },
      ),
    );
  }

  Future<void> _confirmDeleteProduct() async {
    final confirm = await showDeleteProductConfirmDialog(context, _product);
    if (confirm == true) {
      if (!mounted) return;
      await context.read<ProductProvider>().delete(_product.id!);
      if (!mounted) return;
      AppToast.showSuccess(context, 'Produit supprimé avec succès');
      Navigator.pop(context);
    }
  }

  void _showApproForm(BuildContext context, {Approvisionnement? approvisionnement}) {
    final approProvider = context.read<ApprovisionnementProvider>();
    final supplierProvider = context.read<SupplierProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => ProductApproInlineForm(
        product: _product,
        approvisionnement: approvisionnement,
        onSave: (appro) async {
          if (approvisionnement != null) {
            await approProvider.update(approvisionnement, appro);
          } else {
            await approProvider.add(appro);
          }
          await _refreshProduct();
          await supplierProvider.loadSuppliers();
        },
      ),
    );
  }

  void _showVenteForm(BuildContext context) {
    final venteProvider = context.read<VenteProvider>();
    final clientProvider = context.read<ClientProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => ProductVenteInlineForm(
        product: _product,
        onSave: (vente) async {
          await venteProvider.add(vente);
          await _refreshProduct();
          await clientProvider.loadClients();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final cat = catProvider.categories.where((c) => c.id == _product.categoryId).firstOrNull;
        final catColor = cat != null ? Color(cat.color) : AppColors.primary;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              ProductDetailSliverAppBar(
                product: _product,
                catColor: catColor,
                category: cat,
                onEdit: _editProduct,
                onDelete: _confirmDeleteProduct,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ProductStockCard(product: _product, formatter: formatter),
                    const SizedBox(height: 16),
                    ProductPriceCard(product: _product, formatter: formatter),
                    ProductSupplierCard(supplierId: _product.supplierId),
                    const SizedBox(height: 20),
                    Consumer<ApprovisionnementProvider>(
                      builder: (context, provider, _) => ProductHistorySection(
                        title: 'Approvisionnements',
                        icon: Icons.arrow_downward,
                        color: AppColors.primary,
                        loading: provider.loading,
                        empty: 'Aucun approvisionnement enregistré',
                        child: provider.items.isEmpty
                            ? null
                            : ProductApproHistoryTable(
                                items: provider.items,
                                formatter: formatter,
                                onEdit: (a) => _showApproForm(context, approvisionnement: a),
                                onDelete: (a) => showConfirmDeleteProductApproDialog(
                                    context, a, provider, _refreshProduct),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Consumer<VenteProvider>(
                      builder: (context, provider, _) => ProductHistorySection(
                        title: 'Ventes',
                        icon: Icons.shopping_cart_outlined,
                        color: AppColors.success,
                        loading: provider.loading,
                        empty: 'Aucune vente enregistrée',
                        child: provider.items.isEmpty
                            ? null
                            : ProductVenteHistoryTable(
                                productId: widget.product.id,
                                items: provider.items,
                                formatter: formatter,
                                onDelete: (v) => showConfirmDeleteProductVenteDialog(
                                    context, v, provider, _refreshProduct),
                              ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: ProductDetailBottomActions(
            onAppro: () => _showApproForm(context),
            onSell: () => _showVenteForm(context),
          ),
        );
      },
    );
  }
}
