import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'categories/category_detail_products.dart';
import 'categories/category_detail_widgets.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final color = Color(category.color);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          final products = productProvider.products.where((p) => p.categoryId == category.id).toList();
          final featureEnabled = context.watch<SettingsProvider>().settings.enableAverageCostPrice;
          final stockSaleValue = products.fold(0.0, (sum, p) => sum + p.stockSaleValue);
          final stockCost = products.fold(0.0, (sum, p) => sum + p.stockCostWithFeature(featureEnabled));
          final lowStockCount = products.where((p) => p.isLowStock).length;

          return CustomScrollView(
            slivers: [
              CategoryDetailAppBar(category: category, color: color),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    CategoryDetailInfoCard(
                      color: color,
                      formatter: formatter,
                      stockCost: stockCost,
                      stockSaleValue: stockSaleValue,
                      productCount: products.length,
                      lowStockCount: lowStockCount,
                    ),
                    const SizedBox(height: 20),
                    CategoryDetailProductsSection(
                      products: products,
                      formatter: formatter,
                      catColor: color,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
