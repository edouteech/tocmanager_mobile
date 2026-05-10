import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildGreetingCard(),
                        const SizedBox(height: 20),
                        _buildStatsGrid(formatter),
                        if ((_stats['lowStockCount'] ?? 0) > 0) ...[
                          const SizedBox(height: 16),
                          _buildAlertCard(),
                        ],
                        const SizedBox(height: 20),
                        if (_stockByCategory.isNotEmpty) ...[
                          _buildStockByCategory(formatter),
                          const SizedBox(height: 20),
                        ],
                        _buildRecentProducts(formatter),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    final lowStock = (_stats['lowStockCount'] ?? 0) > 0;
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.divider,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset('assets/icon.png'),
      ),
      title: Image.asset('assets/logo.png', height: 26),
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textMedium),
              onPressed: () {},
            ),
            if (lowStock)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildGreetingCard() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    final dateStr = DateFormat("EEEE d MMMM yyyy", 'fr_FR').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(70),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting ! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_stats['productCount'] ?? 0} produits  •  ${_stats['categoryCount'] ?? 0} catégories',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(NumberFormat formatter) {
    final stockValue = (_stats['stockValue'] ?? 0.0) as double;
    final items = [
      _StatData(
        label: 'Produits',
        value: '${_stats['productCount'] ?? 0}',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
        bgColor: AppColors.primaryLight,
      ),
      _StatData(
        label: 'Catégories',
        value: '${_stats['categoryCount'] ?? 0}',
        icon: Icons.category_outlined,
        color: AppColors.success,
        bgColor: AppColors.successLight,
      ),
      _StatData(
        label: 'Valeur stock',
        value: formatter.format(stockValue),
        icon: Icons.show_chart,
        color: AppColors.purple,
        bgColor: AppColors.purpleLight,
        smallText: true,
      ),
      _StatData(
        label: 'Alertes stock',
        value: '${_stats['lowStockCount'] ?? 0}',
        icon: Icons.warning_amber_outlined,
        color: AppColors.danger,
        bgColor: AppColors.dangerLight,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: items.map(_buildStatCard).toList(),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: data.smallText ? 12 : 22,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                data.label,
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard() {
    final count = _stats['lowStockCount'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alerte stock',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$count produit${count > 1 ? 's' : ''} en stock faible ou rupture',
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _buildStockByCategory(NumberFormat formatter) {
    final maxValue = _stockByCategory
        .map((e) => (e['value'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock par catégorie',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: _stockByCategory.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final value = (cat['value'] as num).toDouble();
              final color = Color(cat['color'] as int);
              final ratio = maxValue > 0 ? value / maxValue : 0.0;
              final count = cat['count'] as int;

              return Column(
                children: [
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$count produit${count > 1 ? 's' : ''}',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatter.format(value),
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 7,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProducts(NumberFormat formatter) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final products = provider.products.take(5).toList();
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Produits récents',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Voir tout', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: products.asMap().entries.map((entry) {
                  final i = entry.key;
                  final product = entry.value;
                  return Column(
                    children: [
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.divider, indent: 60),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: product.isLowStock
                                ? AppColors.dangerLight
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: product.isLowStock
                                ? AppColors.danger
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Stock : ${product.quantity} ${product.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                        trailing: Text(
                          formatter.format(product.price),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool smallText;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.smallText = false,
  });
}
