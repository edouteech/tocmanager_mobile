import '../widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/approvisionnement.dart';
import '../providers/approvisionnement_provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/settings_provider.dart';
import '../services/approvisionnement_export_service.dart';
import '../theme/app_theme.dart';

class ApprovisionScreen extends StatefulWidget {
  const ApprovisionScreen({super.key});

  @override
  State<ApprovisionScreen> createState() => _ApprovisionScreenState();
}

class _ApprovisionScreenState extends State<ApprovisionScreen> {
  String _search = '';
  int? _filterProductId;
  String _filterPeriod = 'all'; // 'all', 'today', 'yesterday', 'month', 'credit'
  String _sortBy = 'recent'; // 'recent', 'total_desc'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovisionnementProvider>().load();
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  List<Approvisionnement> _getFilteredItems(List<Approvisionnement> allItems) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final filtered = allItems.where((a) {
      if (_filterProductId != null && a.productId != _filterProductId) return false;

      final aDate = DateTime(a.date.year, a.date.month, a.date.day);

      if (_filterPeriod == 'today') {
        if (!aDate.isAtSameMomentAs(today)) return false;
      } else if (_filterPeriod == 'yesterday') {
        if (!aDate.isAtSameMomentAs(yesterday)) return false;
      } else if (_filterPeriod == 'month') {
        if (a.date.year != now.year || a.date.month != now.month) return false;
      } else if (_filterPeriod == 'credit') {
        if (!a.isCredit) return false;
      }

      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matchSupp = (a.supplier ?? '').toLowerCase().contains(q);
        final matchNotes = (a.notes ?? '').toLowerCase().contains(q);
        if (!matchSupp && !matchNotes) return false;
      }

      return true;
    }).toList();

    if (_sortBy == 'total_desc') {
      filtered.sort((a, b) => b.total.compareTo(a.total));
    } else if (_sortBy == 'recent') {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    }

    return filtered;
  }

  String _getPeriodLabel() {
    if (_filterPeriod == 'today') return 'Aujourd\'hui';
    if (_filterPeriod == 'yesterday') return 'Hier';
    if (_filterPeriod == 'month') return 'Ce mois-ci';
    if (_filterPeriod == 'credit') return 'Approvisionnements à crédit';
    return 'Toutes les périodes';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );

    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Approvisionnements', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Exporter le registre',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.ios_share_outlined, color: AppColors.primary, size: 20),
            ),
            onSelected: (val) {
              final settings = context.read<SettingsProvider>().settings;
              final products = context.read<ProductProvider>().products;
              final items = _getFilteredItems(context.read<ApprovisionnementProvider>().items);
              final periodName = _getPeriodLabel();
              if (val == 'excel') {
                ApprovisionnementExportService.exportApprovisionnementsExcel(context, items, products, periodName);
              } else if (val == 'pdf') {
                ApprovisionnementExportService.exportApprovisionnementsPdfReport(context, items, products, periodName, settings);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 18, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Exporter Excel (.xlsx)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Rapport PDF (A4)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'Nouvel approvisionnement',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(formatter),
          _buildSearchAndSortBar(),
          _buildPeriodFilterRow(),
          _buildProductFilter(),
          Expanded(child: _buildAdaptiveBody(formatter, isLargeScreen: isLargeScreen)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nouvel réapprovisionnement'),
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher (fournisseur, note)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sort_outlined, color: AppColors.primary, size: 20),
            ),
            tooltip: 'Trier les approvisionnements',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.textMedium),
                    SizedBox(width: 8),
                    Text('Plus récents'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'total_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Total le plus élevé'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _periodChip('Toutes', 'all'),
            const SizedBox(width: 6),
            _periodChip('Aujourd\'hui', 'today'),
            const SizedBox(width: 6),
            _periodChip('Hier', 'yesterday'),
            const SizedBox(width: 6),
            _periodChip('Ce mois-ci', 'month'),
            const SizedBox(width: 6),
            _periodChip('À crédit', 'credit'),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label, String type) {
    final selected = _filterPeriod == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
      onSelected: (val) {
        if (val) setState(() => _filterPeriod = type);
      },
    );
  }

  Widget _buildSummary(NumberFormat formatter) {
    return Consumer<ApprovisionnementProvider>(
      builder: (context, provider, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              _summaryChip(
                label: 'Total entrées',
                value: '${provider.items.length}',
                icon: Icons.arrow_downward,
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _summaryChip(
                label: 'Montant total',
                value: formatter.format(provider.totalAmount),
                icon: Icons.show_chart,
                color: AppColors.primary,
                small: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool small = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: small ? 11 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductFilter() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(null, 'Tous', AppColors.primary),
              ...provider.products.map(
                (p) => _filterChip(p.id, p.name, AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(int? productId, String label, Color color) {
    final selected = _filterProductId == productId;
    return GestureDetector(
      onTap: () {
        setState(() => _filterProductId = productId);
        context.read<ApprovisionnementProvider>().load(productId: productId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMedium,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveBody(NumberFormat formatter, {required bool isLargeScreen}) {
    return Consumer2<ApprovisionnementProvider, ProductProvider>(
      builder: (context, approProvider, productProvider, _) {
        if (approProvider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final items = _getFilteredItems(approProvider.items);

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun approvisionnement',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enregistrez votre premier approvisionnement',
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }

        if (!isLargeScreen) {
          return _buildMobileListView(formatter, items, productProvider, approProvider);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDataTable(items, productProvider, approProvider, formatter),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileListView(
    NumberFormat formatter,
    List<Approvisionnement> items,
    ProductProvider productProvider,
    ApprovisionnementProvider approProvider,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final a = items[i];
        final prod = productProvider.products.where((p) => p.id == a.productId).firstOrNull;
        final prodName = prod?.name ?? 'Produit #${a.productId}';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.divider),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showApprovisionnementDetail(context, a, prodName, approProvider, formatter),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: a.isCredit ? AppColors.danger.withAlpha(20) : AppColors.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: a.isCredit ? AppColors.danger.withAlpha(50) : AppColors.success.withAlpha(50)),
                        ),
                        child: Text(
                          a.isCredit ? 'À crédit (Reste: ${formatter.format(a.remainingAmount)})' : 'Payé Cash',
                          style: TextStyle(
                            color: a.isCredit ? AppColors.danger : AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        dateFormat.format(a.date),
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prodName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 4),
                      Text(
                        'Qté : ${a.quantity} ${prod?.unit ?? 'unités'} × ${formatter.format(a.unitPrice)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                  if (a.supplier != null && a.supplier!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business_outlined, size: 14, color: AppColors.textMedium),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Fournisseur : ${a.supplier}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Achat :',
                        style: TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formatter.format(a.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showApprovisionnementDetail(
    BuildContext context,
    Approvisionnement a,
    String prodName,
    ApprovisionnementProvider approProvider,
    NumberFormat formatter,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.isCredit ? AppColors.danger.withAlpha(20) : AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.isCredit ? 'À Crédit' : 'Réglé Cash',
                    style: TextStyle(color: a.isCredit ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                Text(dateFormat.format(a.date), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 16),
            Text(prodName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantité :', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                      Text('${a.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prix d\'achat unitaire :', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                      Text(formatter.format(a.unitPrice), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Achats :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(formatter.format(a.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                  if (a.supplier != null && a.supplier!.isNotEmpty) ...[
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fournisseur :', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                        Text(a.supplier!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ],
                  if (a.isCredit) ...[
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant Réglé :', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                        Text(formatter.format(a.paidAmount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.success)),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reste Dû :', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.danger)),
                        Text(formatter.format(a.remainingAmount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.danger)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, a, approProvider, context.read<ProductProvider>());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showForm(context, approvisionnement: a);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
    List<Approvisionnement> items,
    ProductProvider productProvider,
    ApprovisionnementProvider approProvider,
    NumberFormat formatter,
  ) {
    const h = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    );
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return DataTable(
      headingRowHeight: 44,
      dataRowMinHeight: 58,
      dataRowMaxHeight: 58,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: [
        DataColumn(label: SizedBox(width: 80, child: Text('Date', style: h))),
        DataColumn(label: SizedBox(width: 130, child: Text('Produit', style: h))),
        DataColumn(
          label: SizedBox(width: 70, child: Center(child: Text('Qté', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('P. Unitaire', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Center(child: Text('Total', style: h))),
          numeric: true,
        ),
        DataColumn(label: SizedBox(width: 110, child: Text('Fournisseur', style: h))),
        const DataColumn(label: SizedBox(width: 70)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        final product = productProvider.products
            .where((p) => p.id == a.productId)
            .firstOrNull;

        return DataRow(
          color: WidgetStateProperty.all(
            i.isEven ? Colors.white : const Color(0xFFF8FBFF),
          ),
          cells: [
            DataCell(Text(
              dateFormat.format(a.date),
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
            )),
            DataCell(Text(
              product?.name ?? '—',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(Center(
              child: Text(
                a.quantity.toStringAsFixed(a.quantity.truncateToDouble() == a.quantity ? 0 : 1),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )),
            DataCell(Center(
              child: Text(
                formatter.format(a.unitPrice),
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              ),
            )),
            DataCell(Center(
              child: Text(
                formatter.format(a.total),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )),
            DataCell(Text(
              a.supplier ?? '—',
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showForm(context, approvisionnement: a),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () =>
                        _confirmDelete(context, a, approProvider, productProvider),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Approvisionnement appro,
    ApprovisionnementProvider approProvider,
    ProductProvider productProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Supprimer cet approvisionnement ? Le stock sera mis à jour.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final supplierProvider = context.read<SupplierProvider>();
              Navigator.pop(ctx);
              await approProvider.delete(appro);
              if (context.mounted) {
                await productProvider.load();
                await supplierProvider.loadSuppliers();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {Approvisionnement? approvisionnement}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ApprovisionForm(
        approvisionnement: approvisionnement,
        onSave: (newAppro) async {
          final approProvider = context.read<ApprovisionnementProvider>();
          final productProvider = context.read<ProductProvider>();
          final supplierProvider = context.read<SupplierProvider>();
          if (approvisionnement != null) {
            await approProvider.update(approvisionnement, newAppro);
          } else {
            await approProvider.add(newAppro);
          }
          await productProvider.load();
          await supplierProvider.loadSuppliers();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ApprovisionForm extends StatefulWidget {
  final Approvisionnement? approvisionnement;
  final Future<void> Function(Approvisionnement) onSave;

  const _ApprovisionForm({
    this.approvisionnement,
    required this.onSave,
  });

  @override
  State<_ApprovisionForm> createState() => _ApprovisionFormState();
}

class _ApprovisionFormState extends State<_ApprovisionForm> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int? _productId;
  int? _supplierId;
  DateTime _date = DateTime.now();
  bool _isFullPayment = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.approvisionnement;
    if (a != null) {
      _productId = a.productId;
      _supplierId = a.supplierId;
      _qtyCtrl.text = a.quantity % 1 == 0
          ? a.quantity.toInt().toString()
          : a.quantity.toString();
      _priceCtrl.text = a.unitPrice % 1 == 0
          ? a.unitPrice.toInt().toString()
          : a.unitPrice.toString();
      _supplierCtrl.text = a.supplier ?? '';
      _notesCtrl.text = a.notes ?? '';
      _date = a.date;
      _isFullPayment = a.paidAmount >= a.total;
      _paidCtrl.text = a.paidAmount % 1 == 0
          ? a.paidAmount.toInt().toString()
          : a.paidAmount.toString();
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _paidCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  double get _paidAmount {
    if (_isFullPayment) return _total;
    return double.tryParse(_paidCtrl.text.trim()) ?? 0;
  }

  double get _remaining => (_total - _paidAmount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

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
                      widget.approvisionnement != null
                          ? 'Modifier l\'approvisionnement'
                          : 'Nouvel approvisionnement',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<ProductProvider>(
                builder: (_, provider, _) {
                  final validProductId = provider.products.any((p) => p.id == _productId) ? _productId : null;
                  return DropdownButtonFormField<int?>(
                    initialValue: validProductId,
                    decoration: InputDecoration(
                      labelText: 'Produit *',
                      filled: true,
                      fillColor: AppColors.primarySurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: provider.products
                        .map((p) => DropdownMenuItem<int?>(
                              value: p.id,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _productId = v),
                    validator: (v) => v == null ? 'Veuillez choisir un produit' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Quantité *'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Quantité obligatoire';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Quantité invalide (> 0)';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Prix unitaire d\'achat',
                        suffixText: 'F',
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final num = double.tryParse(val.trim());
                          if (num == null || num < 0) return 'Prix unitaire invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_total > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Achat :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(formatter.format(_total), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Supplier Selector
              Consumer<SupplierProvider>(
                builder: (_, supplierProv, _) {
                  final suppliers = supplierProv.suppliers;
                  final validSupplierId = suppliers.any((s) => s.id == _supplierId) ? _supplierId : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int?>(
                        initialValue: validSupplierId,
                        decoration: InputDecoration(
                          labelText: 'Sélectionner un Fournisseur',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Aucun / Saisie libre')),
                          ...suppliers.map((s) => DropdownMenuItem<int?>(
                                value: s.id,
                                child: Text(s.name),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _supplierId = val;
                            if (val != null) {
                              final s = suppliers.firstWhere((item) => item.id == val);
                              _supplierCtrl.text = s.name;
                            }
                          });
                        },
                      ),
                      if (_supplierId == null) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _supplierCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom du Fournisseur (Saisie libre)',
                            hintText: 'Ex: Nestlé CI',
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Payment Status Toggle
              const Text('Règlement Fournisseur', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Payé Cash')),
                      selected: _isFullPayment,
                      selectedColor: AppColors.success,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(color: _isFullPayment ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700),
                      onSelected: (val) {
                        if (val) setState(() => _isFullPayment = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Règlement partiel / Crédit')),
                      selected: !_isFullPayment,
                      selectedColor: AppColors.danger,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(color: !_isFullPayment ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700),
                      onSelected: (val) {
                        if (val) setState(() => _isFullPayment = false);
                      },
                    ),
                  ),
                ],
              ),
              if (!_isFullPayment) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _paidCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Montant Acompte Versé (FCFA)',
                    suffixText: 'F',
                  ),
                ),
                if (_remaining > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reliquat restant dû (Crédit Fournisseur) : ${formatter.format(_remaining)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                  ),
                ],
              ],
              const SizedBox(height: 14),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd/MM/yyyy', 'fr_FR').format(_date),
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Remarques optionnelles',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.approvisionnement != null
                              ? 'Enregistrer les modifications'
                              : 'Enregistrer l\'approvisionnement',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
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
    if (_productId == null) {
      AppToast.showError(context, 'Veuillez sélectionner un produit à approvisionner.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez vérifier vos saisies.');
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0 || _productId == null) return;
    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceCtrl.text) ?? 0;
      final total = qty * price;
      final paid = _isFullPayment ? total : (double.tryParse(_paidCtrl.text.trim()) ?? 0);

      final appro = Approvisionnement(
        id: widget.approvisionnement?.id,
        productId: _productId!,
        quantity: qty,
        unitPrice: price,
        total: total,
        supplierId: _supplierId,
        supplier: _supplierCtrl.text.trim().isEmpty
            ? null
            : _supplierCtrl.text.trim(),
        paidAmount: paid,
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await widget.onSave(appro);
      if (!mounted) return;
      await context.read<SupplierProvider>().loadSuppliers();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'Une erreur est survenue. Veuillez réessayer.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
