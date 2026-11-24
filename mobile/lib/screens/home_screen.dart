import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import 'home/home_header_widgets.dart';
import 'home/home_stats_grid.dart';
import 'home/home_stock_and_recent_cards.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int, {String? statusFilter})? onNav;
  final VoidCallback? onOpenDrawer;
  const HomeScreen({super.key, this.onNav, this.onOpenDrawer});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _stockByCategory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final productProvider = context.read<ProductProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    await productProvider.load();
    await categoryProvider.load();
    final stats = await DatabaseHelper.instance.getStats();
    final stockByCategory = await DatabaseHelper.instance.getStockByCategory();
    if (mounted) {
      setState(() {
        _stats = stats;
        _stockByCategory = stockByCategory;
        _loading = false;
      });
    }
  }

  /// External reload trigger invoked on navigation tab changes.
  void reload() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  HomeSliverAppBar(onOpenDrawer: widget.onOpenDrawer),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        HomeGreetingCard(stats: _stats, onReloadData: _loadData),
                        const SizedBox(height: 20),
                        HomeStatsGrid(stats: _stats, formatter: formatter, onNav: widget.onNav),
                        if ((_stats['lowStockCount'] ?? 0) > 0) ...[
                          const SizedBox(height: 16),
                          HomeAlertCard(
                            count: _stats['lowStockCount'] as int,
                            onTap: () => widget.onNav?.call(1, statusFilter: 'lowStock'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (_stockByCategory.isNotEmpty) ...[
                          HomeStockByCategoryCard(stockByCategory: _stockByCategory, formatter: formatter),
                          const SizedBox(height: 20),
                        ],
                        HomeRecentProductsCard(
                          formatter: formatter,
                          onNav: widget.onNav,
                          onReloadData: _loadData,
                        ),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
