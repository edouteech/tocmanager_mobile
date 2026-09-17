import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/category_icon_helper.dart';
import 'product_detail_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );
    final color = Color(category.color);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          final products = productProvider.products
              .where((p) => p.categoryId == category.id)
              .toList();
          final settings = context.watch<SettingsProvider>().settings;
          final featureEnabled = settings.enableAverageCostPrice;
          final stockSaleValue =
              products.fold(0.0, (sum, p) => sum + p.stockSaleValue);
          final stockCost =
              products.fold(0.0, (sum, p) => sum + p.stockCostWithFeature(featureEnabled));
          final lowStockCount = products.where((p) => p.isLowStock).length;

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, color),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoCard(color, formatter, stockCost, stockSaleValue, products.length, lowStockCount),
                    const SizedBox(height: 20),
                    _buildProductsSection(context, products, formatter, color),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color color) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: color,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withAlpha(220), color],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CategoryIconHelper.getIcon(category.icon),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      category.description!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    Color color,
    NumberFormat formatter,
    double stockCost,
    double stockSaleValue,
    int productCount,
    int lowStockCount,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _statItem(
            label: 'Produits',
            value: '$productCount',
            icon: Icons.inventory_2_outlined,
            color: color,
          ),
          _divider(),
          _statItem(
            label: 'Coût stock',
            value: formatter.format(stockCost),
            icon: Icons.shopping_bag_outlined,
            color: AppColors.primary,
            smallText: true,
          ),
          _divider(),
          _statItem(
            label: 'Valeur vente',
            value: formatter.format(stockSaleValue),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.success,
            smallText: true,
          ),
          _divider(),
          _statItem(
            label: 'Alertes',
            value: '$lowStockCount',
            icon: Icons.warning_amber_outlined,
            color: lowStockCount > 0 ? AppColors.danger : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool smallText = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: smallText ? 11 : 18,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 48, color: AppColors.divider);
  }

  Widget _buildProductsSection(
    BuildContext context,
    List<Product> products,
    NumberFormat formatter,
    Color catColor,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Produits',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${products.length} référence${products.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                'Aucun produit dans cette catégorie',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        else if (isMobile)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = products[index];
              final stockColor = p.isLowStock ? AppColors.danger : AppColors.success;
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: p),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: catColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.inventory_2_outlined, color: catColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatter.format(p.price),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1)} ${p.unit}',
                            style: TextStyle(color: stockColor, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildProductTable(context, products, formatter, catColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductTable(
    BuildContext context,
    List<Product> products,
    NumberFormat formatter,
    Color catColor,
  ) {
    const h = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    );

    return DataTable(
      showCheckboxColumn: false,
      headingRowHeight: 40,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 56,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: [
        DataColumn(label: SizedBox(width: 130, child: Text('Produit', style: h))),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('P. Vente', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('Stock', style: h))),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Center(child: Text('Valeur stock', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 70, child: Center(child: Text('Statut', style: h))),
        ),
      ],
      rows: products.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        final stockColor = p.isLowStock ? AppColors.danger : AppColors.success;

        return DataRow(
          onSelectChanged: (_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            );
          },
          color: WidgetStateProperty.all(
            i.isEven ? Colors.white : const Color(0xFFF8FBFF),
          ),
          cells: [
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.description != null)
                    SizedBox(
                      width: 130,
                      child: Text(
                        p.description!,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            DataCell(
              Center(
                child: Text(
                  formatter.format(p.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1)} ${p.unit}',
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              Center(
                child: Text(
                  formatter.format(p.stockValue),
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(
              Center(
                child: p.isLowStock
                    ? const Icon(Icons.warning_amber, color: AppColors.danger, size: 18)
                    : const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
