import '../services/ticket_pdf_service.dart';
import '../services/vente_export_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vente.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../providers/vente_provider.dart';
import '../providers/product_provider.dart';
import '../providers/client_provider.dart';
import '../theme/app_theme.dart';
import 'products_screen.dart';

class VenteScreen extends StatefulWidget {
  const VenteScreen({super.key});

  @override
  State<VenteScreen> createState() => _VenteScreenState();
}

class _VenteScreenState extends State<VenteScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'today', 'yesterday', 'month', 'credit'
  String _sortBy = 'recent'; // 'recent', 'amount_desc', 'client_asc'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VenteProvider>().load();
      context.read<ClientProvider>().loadClients();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Vente> _getFilteredVentes(List<Vente> allVentes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final filtered = allVentes.where((v) {
      final vDate = DateTime(v.date.year, v.date.month, v.date.day);

      if (_filterType == 'today') {
        if (!vDate.isAtSameMomentAs(today)) return false;
      } else if (_filterType == 'yesterday') {
        if (!vDate.isAtSameMomentAs(yesterday)) return false;
      } else if (_filterType == 'month') {
        if (v.date.year != now.year || v.date.month != now.month) return false;
      } else if (_filterType == 'credit') {
        if (!v.isCredit) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTicket = v.ticketNumber.toLowerCase().contains(q);
        final matchClient = (v.clientName ?? '').toLowerCase().contains(q);
        final matchItem = v.items.any((it) => it.productName.toLowerCase().contains(q));
        if (!matchTicket && !matchClient && !matchItem) return false;
      }

      return true;
    }).toList();

    if (_sortBy == 'amount_desc') {
      filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    } else if (_sortBy == 'client_asc') {
      filtered.sort((a, b) => (a.clientName ?? '').compareTo(b.clientName ?? ''));
    } else if (_sortBy == 'recent') {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    }

    return filtered;
  }

  String _getPeriodLabel() {
    if (_filterType == 'today') return 'Aujourd\'hui';
    if (_filterType == 'yesterday') return 'Hier';
    if (_filterType == 'month') return 'Ce mois-ci';
    if (_filterType == 'credit') return 'Ventes à crédit';
    return 'Toutes les périodes';
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildSummaryCards(formatter),
          _buildSearchAndSortBar(),
          _buildFilterChipsRow(),
          Expanded(child: _buildVenteList(formatter, isLargeScreen: isLargeScreen)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'vente_fab',
        onPressed: () => _showForm(context),
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle vente',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Retour',
              ),
              const Text(
                'Ventes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: const Icon(Icons.ios_share_outlined, color: AppColors.primary, size: 20),
                ),
                tooltip: 'Exporter le registre des ventes',
                onSelected: (val) {
                  final settings = context.read<SettingsProvider>().settings;
                  final ventes = _getFilteredVentes(context.read<VenteProvider>().items);
                  final periodName = _getPeriodLabel();
                  if (val == 'excel') {
                    VenteExportService.exportVentesExcel(context, ventes, periodName);
                  } else if (val == 'pdf') {
                    VenteExportService.exportVentesPdfReport(context, ventes, periodName, settings);
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
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Nouvelle vente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(NumberFormat formatter) {
    return Consumer<VenteProvider>(
      builder: (context, provider, _) {
        final totalVentes = provider.items.length;
        final totalAmount = provider.totalSalesAmount;
        final todayAmount = provider.todaySalesAmount;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              _summaryChip('Total ventes', '$totalVentes', AppColors.primary),
              const SizedBox(width: 8),
              _summaryChip(
                  'Aujourd\'hui', formatter.format(todayAmount), AppColors.success),
              const SizedBox(width: 8),
              _summaryChip(
                  'Chiffre d\'aff.', formatter.format(totalAmount), AppColors.purple),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
            child: TextFormField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher ticket, client, produit...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMedium),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
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
            tooltip: 'Trier les ventes',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.textMedium),
                    SizedBox(width: 8),
                    Text('Plus récentes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'amount_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Montant le plus élevé'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'client_asc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Nom Client (A - Z)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Toutes', 'all'),
            const SizedBox(width: 6),
            _filterChip('Aujourd\'hui', 'today'),
            const SizedBox(width: 6),
            _filterChip('Hier', 'yesterday'),
            const SizedBox(width: 6),
            _filterChip('Ce mois-ci', 'month'),
            const SizedBox(width: 6),
            _filterChip('À crédit', 'credit'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String type) {
    final selected = _filterType == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _filterType = type;
          });
        }
      },
    );
  }

  Widget _buildVenteList(NumberFormat formatter, {required bool isLargeScreen}) {
    return Consumer2<VenteProvider, ProductProvider>(
      builder: (context, venteProvider, productProvider, _) {
        if (venteProvider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final items = _getFilteredVentes(venteProvider.items);

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucune vente',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enregistrez votre première vente',
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }

        if (!isLargeScreen) {
          return _buildMobileCardList(items, formatter);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          child: Container(
            width: double.infinity,
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
                child: _buildDataTable(
                  items,
                  productProvider,
                  venteProvider,
                  formatter,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCardList(List<Vente> items, NumberFormat formatter) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final v = items[i];
        final isCredit = v.isCredit;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showVenteDetails(v),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCredit ? AppColors.warning.withAlpha(80) : AppColors.divider,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        v.ticketNumber.isNotEmpty ? v.ticketNumber : 'VNT-${v.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        dateFormat.format(v.date),
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isCredit ? AppColors.warning.withAlpha(25) : AppColors.primarySurface,
                        child: Icon(
                          Icons.person_outline,
                          size: 18,
                          color: isCredit ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.clientName ?? 'Occasionnel',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${v.items.length} article(s)',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatter.format(v.totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isCredit ? AppColors.warning : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCredit ? AppColors.warningLight : AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isCredit
                              ? 'Crédit - Reste: ${formatter.format(v.remainingAmount)}'
                              : '${v.paymentMethod} - Payé',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCredit ? AppColors.warning : AppColors.success,
                          ),
                        ),
                      ),
                      const Row(
                        children: [
                          Text(
                            'Détails',
                            style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                        ],
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

  Widget _buildDataTable(
    List<Vente> items,
    ProductProvider productProvider,
    VenteProvider venteProvider,
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
        DataColumn(label: SizedBox(width: 140, child: Text('Produits', style: h))),
        DataColumn(
          label: SizedBox(width: 70, child: Center(child: Text('Qté total', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Center(child: Text('Total', style: h))),
          numeric: true,
        ),
        DataColumn(label: SizedBox(width: 110, child: Text('Client', style: h))),
        const DataColumn(label: SizedBox(width: 70)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final v = entry.value;
        final firstItem = v.items.firstOrNull;
        final productName = v.items.length > 1
            ? '${v.items.first.productName} (+${v.items.length - 1})'
            : (firstItem?.productName ?? '—');
        final totalQty = v.items.fold(0.0, (sum, it) => sum + it.quantity);
        final total = v.totalAmount;

        return DataRow(
          color: WidgetStateProperty.all(
            i.isEven ? Colors.white : const Color(0xFFF8FBFF),
          ),
          onSelectChanged: (_) => _showVenteDetails(v),
          cells: [
            DataCell(
              Text(
                dateFormat.format(v.date),
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              ),
              onTap: () => _showVenteDetails(v),
            ),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (v.items.length > 1)
                    Text(
                      '${v.items.length} articles',
                      style: const TextStyle(fontSize: 10, color: AppColors.primary),
                    ),
                ],
              ),
              onTap: () => _showVenteDetails(v),
            ),
            DataCell(
              Center(
                child: Text(
                  totalQty.toStringAsFixed(
                      totalQty.truncateToDouble() == totalQty ? 0 : 1),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () => _showVenteDetails(v),
            ),
            DataCell(
              Center(
                child: Text(
                  formatter.format(total),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () => _showVenteDetails(v),
            ),
            DataCell(
              Text(
                v.clientName ?? 'Non précisé',
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _showVenteDetails(v),
            ),
            DataCell(
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      final settings = context.read<SettingsProvider>().settings;
                      TicketPdfService.shareTicketPdf(context, v, settings);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.print_outlined,
                          color: AppColors.primary, size: 14),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _confirmDelete(
                        context, v, venteProvider, productProvider),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: AppColors.danger, size: 14),
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

  void _showVenteDetails(Vente vente) {
    showVenteDetailsModal(context, vente);
  }

  void _confirmDelete(
    BuildContext context,
    Vente vente,
    VenteProvider venteProvider,
    ProductProvider productProvider,
  ) {
    _confirmDeleteVenteModal(context, vente, venteProvider, productProvider);
  }

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _VenteForm(
        onSave: (vente) async {
          final venteProvider = context.read<VenteProvider>();
          final productProvider = context.read<ProductProvider>();
          final clientProvider = context.read<ClientProvider>();
          await venteProvider.add(vente);
          await productProvider.load();
          await clientProvider.loadClients();
        },
      ),
    );
  }
}

void showVenteDetailsModal(BuildContext context, Vente vente) {
  final formatter =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vente.ticketNumber.isNotEmpty ? vente.ticketNumber : 'Détails de la vente',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(vente.date),
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: AppColors.textMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Client : ${vente.clientName ?? 'Occasionnel'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vente.isCredit ? AppColors.warningLight : AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vente.paymentMethod,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: vente.isCredit ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Articles achetés (${vente.items.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vente.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, idx) {
                final item = vente.items[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} x ${formatter.format(item.unitPrice)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatter.format(item.total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider),
          if (vente.discountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sous-total brut', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                Text(
                  formatter.format(vente.subtotalAmount),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remise / Réduction', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                Text(
                  '- ${formatter.format(vente.discountAmount)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL NET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                formatter.format(vente.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Montant Versé', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
              Text(
                formatter.format(vente.paidAmount),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ],
          ),
          if (vente.isCredit) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reste à payer (Crédit)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning)),
                Text(
                  formatter.format(vente.remainingAmount),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
              ],
            ),
          ],
          if (vente.notes != null && vente.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes : ${vente.notes}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMedium),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final settings = context.read<SettingsProvider>().settings;
                    TicketPdfService.shareTicketPdf(context, vente, settings);
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Partager'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final settings = context.read<SettingsProvider>().settings;
                    TicketPdfService.downloadTicketPdf(context, vente, settings);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Télécharger'),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {
                  _confirmDeleteVenteModal(
                    context,
                    vente,
                    context.read<VenteProvider>(),
                    context.read<ProductProvider>(),
                    parentContext: ctx,
                  );
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                tooltip: 'Annuler la vente',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void _confirmDeleteVenteModal(
  BuildContext context,
  Vente vente,
  VenteProvider venteProvider,
  ProductProvider productProvider, {
  BuildContext? parentContext,
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Annuler la vente',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content:
          const Text('Annuler cette vente ? Le stock sera restitué.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Non'),
        ),
        ElevatedButton(
          onPressed: () async {
            final clientProvider = context.read<ClientProvider>();
            Navigator.pop(dialogCtx);
            if (parentContext != null && parentContext.mounted) {
              Navigator.pop(parentContext);
            }
            await venteProvider.delete(vente);
            if (context.mounted) {
              await productProvider.load();
              await clientProvider.loadClients();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Annuler la vente'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------

class _VenteForm extends StatefulWidget {
  final Future<void> Function(Vente) onSave;

  const _VenteForm({required this.onSave});

  @override
  State<_VenteForm> createState() => _VenteFormState();
}

class _VenteFormState extends State<_VenteForm> {
  final List<VenteItem> _saleItems = [];

  // Product selection controls
  Product? _selectedProduct;
  final _productCtrl = TextEditingController();
  final _productFocusNode = FocusNode();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  String? _itemError;

  // Discount controls
  final _discountCtrl = TextEditingController();
  String _discountType = 'amount'; // 'amount' (FCFA) or 'percent' (%)

  // Client controls
  final _clientCtrl = TextEditingController();
  final _clientFocusNode = FocusNode();

  // Payment controls
  String _paymentMethod = 'Espèces';
  final _paidCtrl = TextEditingController();
  bool _isCustomPaid = false;

  // Date and notes controls
  DateTime _date = DateTime.now();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _paidCtrl.text = '0';
  }

  @override
  void dispose() {
    _productCtrl.dispose();
    _productFocusNode.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _clientCtrl.dispose();
    _clientFocusNode.dispose();
    _paidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotalAmount {
    return _saleItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double get _computedDiscountAmount {
    final raw = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    if (raw <= 0 || _subtotalAmount <= 0) return 0.0;
    if (_discountType == 'percent') {
      final pct = raw.clamp(0.0, 100.0);
      return (_subtotalAmount * pct / 100.0).roundToDouble();
    } else {
      return raw.clamp(0.0, _subtotalAmount);
    }
  }

  double get _totalAmount {
    final net = _subtotalAmount - _computedDiscountAmount;
    return net > 0 ? net : 0.0;
  }

  double _resolveUnitPrice(Product product, {double? quantityOverride, Client? clientOverride}) {
    final qty = quantityOverride ?? (double.tryParse(_qtyCtrl.text.trim()) ?? 1.0);
    final clientName = _clientCtrl.text.trim();
    Client? selectedClient = clientOverride;
    if (selectedClient == null && clientName.isNotEmpty) {
      final clientProvider = context.read<ClientProvider>();
      selectedClient = clientProvider.clients
          .where((c) => c.name.toLowerCase() == clientName.toLowerCase())
          .firstOrNull;
    }

    final clientType = selectedClient?.clientType ?? 'detail';

    if (clientType == 'gros' && product.priceWholesale > 0) {
      return product.priceWholesale;
    }
    if (clientType == 'demi_gros' && product.priceSemiWholesale > 0) {
      return product.priceSemiWholesale;
    }
    if (product.minQtyWholesale > 0 && qty >= product.minQtyWholesale && product.priceWholesale > 0) {
      return product.priceWholesale;
    }
    if (product.minQtySemiWholesale > 0 && qty >= product.minQtySemiWholesale && product.priceSemiWholesale > 0) {
      return product.priceSemiWholesale;
    }
    return product.price;
  }

  void _updatePriceForSelectedProduct() {
    if (_selectedProduct != null) {
      final resolved = _resolveUnitPrice(_selectedProduct!);
      _priceCtrl.text = resolved.toStringAsFixed(0);
    }
  }

  Widget _priceTierChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  void _syncPaidAmount() {
    if (!_isCustomPaid) {
      if (_paymentMethod == 'Crédit') {
        _paidCtrl.text = '0';
      } else {
        _paidCtrl.text = _totalAmount.toStringAsFixed(0);
      }
    }
  }

  Future<void> _handleNewProductCreation(String typedName, ProductProvider productProvider) async {
    final createConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Produit non enregistré', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Le produit "$typedName" n\'existe pas dans votre catalogue. Voulez-vous l\'ajouter à la base de données ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Créer le produit'),
          ),
        ],
      ),
    );

    if (createConfirmed == true && mounted) {
      final Product? createdProduct = await showModalBottomSheet<Product>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => ProductFormModal(
          initialName: typedName,
          initialPrice: double.tryParse(_priceCtrl.text.trim()),
          onSave: (p) async {
            await productProvider.add(p);
          },
        ),
      );

      if (createdProduct != null && mounted) {
        setState(() {
          _selectedProduct = createdProduct;
          _productCtrl.text = createdProduct.name;
          _priceCtrl.text = _resolveUnitPrice(createdProduct).toStringAsFixed(0);
          _itemError = null;
        });
        await _addItem(productProvider);
      }
    }
  }

  Future<void> _addItem(ProductProvider productProvider) async {
    setState(() => _itemError = null);

    final typedName = _productCtrl.text.trim();
    if (typedName.isEmpty) {
      setState(() => _itemError = 'Veuillez saisir ou sélectionner un produit.');
      return;
    }

    Product? product = _selectedProduct;
    product ??= productProvider.products.where(
      (p) => p.name.trim().toLowerCase() == typedName.toLowerCase(),
    ).firstOrNull;

    if (product == null) {
      await _handleNewProductCreation(typedName, productProvider);
      return;
    }

    final qty = double.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _itemError = 'Quantité invalide (> 0)');
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price < 0) {
      setState(() => _itemError = 'Prix unitaire invalide (>= 0)');
      return;
    }

    // Check available stock considering items already added in sale draft
    final existingQtyInDraft = _saleItems
        .where((it) => it.productId == product!.id)
        .fold(0.0, (sum, it) => sum + it.quantity);

    final availableStock = product.quantity - existingQtyInDraft;
    if (qty > availableStock) {
      final stockStr = availableStock.toStringAsFixed(
          availableStock.truncateToDouble() == availableStock ? 0 : 1);
      setState(() => _itemError = 'Stock insuffisant ($stockStr dispo)');
      return;
    }

    // Add or aggregate item
    final existingIdx = _saleItems.indexWhere(
        (it) => it.productId == product!.id && it.unitPrice == price);
    if (existingIdx >= 0) {
      final existing = _saleItems[existingIdx];
      final newQty = existing.quantity + qty;
      _saleItems[existingIdx] = existing.copyWith(
        quantity: newQty,
        total: newQty * price,
      );
    } else {
      final featureEnabled =
          context.read<SettingsProvider>().settings.enableAverageCostPrice;
      _saleItems.add(VenteItem(
        productId: product.id!,
        productName: product.name,
        quantity: qty,
        unitPrice: price,
        total: qty * price,
        costPrice: product.effectiveCostPrice(featureEnabled),
      ));
    }

    // Reset product selection inputs
    setState(() {
      _selectedProduct = null;
      _productCtrl.clear();
      _qtyCtrl.text = '1';
      _priceCtrl.clear();
      _itemError = null;
      _syncPaidAmount();
    });
  }

  void _incrementItem(int index, ProductProvider productProvider) {
    final item = _saleItems[index];
    final product = productProvider.products
        .where((p) => p.id == item.productId)
        .firstOrNull;
    if (product == null) return;

    final otherDraftQty = _saleItems
        .asMap()
        .entries
        .where((entry) => entry.key != index && entry.value.productId == item.productId)
        .fold(0.0, (sum, entry) => sum + entry.value.quantity);

    final available = product.quantity - otherDraftQty;
    final newQty = item.quantity + 1;

    if (newQty > available) {
      AppToast.showError(context, 'Stock insuffisant (${available.toStringAsFixed(0)} ${product.unit} dispo).');
      return;
    }

    setState(() {
      _saleItems[index] = item.copyWith(
        quantity: newQty,
        total: newQty * item.unitPrice,
      );
      _syncPaidAmount();
    });
  }

  void _decrementItem(int index) {
    final item = _saleItems[index];
    final newQty = item.quantity - 1;

    if (newQty <= 0) {
      _removeItem(index);
    } else {
      setState(() {
        _saleItems[index] = item.copyWith(
          quantity: newQty,
          total: newQty * item.unitPrice,
        );
        _syncPaidAmount();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
      _syncPaidAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header ---
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nouvelle vente',
                      style: TextStyle(
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

              // --- Product selection section ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajouter un produit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Consumer<ProductProvider>(
                      builder: (context, provider, child) {
                        return RawAutocomplete<Product>(
                          textEditingController: _productCtrl,
                          focusNode: _productFocusNode,
                          displayStringForOption: (Product option) => option.name,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final query = textEditingValue.text.trim().toLowerCase();
                            if (query.isEmpty) {
                              return provider.products;
                            }
                            return provider.products.where((Product p) {
                              return p.name.toLowerCase().contains(query);
                            });
                          },
                          onSelected: (Product selection) {
                            setState(() {
                              _selectedProduct = selection;
                              _priceCtrl.text = _resolveUnitPrice(selection).toStringAsFixed(0);
                              _itemError = null;
                            });
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Saisir ou rechercher un produit...',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primary),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          controller.clear();
                                          setState(() {
                                            _selectedProduct = null;
                                            _itemError = null;
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (_selectedProduct != null && _selectedProduct!.name != val) {
                                    _selectedProduct = null;
                                  }
                                  _itemError = null;
                                });
                              },
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 76,
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                                    itemBuilder: (context, index) {
                                      final Product option = options.elementAt(index);
                                      final inDraft = _saleItems
                                          .where((it) => it.productId == option.id)
                                          .fold(0.0, (sum, it) => sum + it.quantity);
                                      final remStock = option.quantity - inDraft;
                                      final outOfStock = remStock <= 0;

                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          option.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: outOfStock ? AppColors.textLight : AppColors.textDark,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Prix: ${option.price.toStringAsFixed(0)} FCFA',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: outOfStock ? AppColors.dangerLight : AppColors.successLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            outOfStock
                                                ? 'Rupture'
                                                : 'Dispo: ${remStock.toStringAsFixed(remStock.truncateToDouble() == remStock ? 0 : 1)}',
                                            style: TextStyle(
                                              color: outOfStock ? AppColors.danger : AppColors.success,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Quantity input with - / + buttons
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16, color: AppColors.textMedium),
                                constraints: const BoxConstraints(minWidth: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final val = double.tryParse(_qtyCtrl.text.trim()) ?? 1;
                                  if (val > 1) {
                                    final newQty = val - 1;
                                    _qtyCtrl.text = newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 1);
                                    setState(() => _itemError = null);
                                  }
                                },
                              ),
                              SizedBox(
                                width: 40,
                                child: TextFormField(
                                  controller: _qtyCtrl,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() => _itemError = null),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16, color: AppColors.textMedium),
                                constraints: const BoxConstraints(minWidth: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final val = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
                                  final newQty = val + 1;
                                  _qtyCtrl.text = newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 1);
                                  setState(() => _itemError = null);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Prix unitaire',
                              suffixText: 'F',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.divider),
                              ),
                            ),
                            onChanged: (_) => setState(() => _itemError = null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Consumer<ProductProvider>(
                          builder: (context, productProvider, child) => ElevatedButton(
                            onPressed: () => _addItem(productProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 18),
                                SizedBox(width: 2),
                                Text('Ajouter'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_itemError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _itemError!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- List of added products ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Panier (${_saleItems.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (_saleItems.isNotEmpty)
                    Text(
                      formatter.format(_totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_saleItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(
                    child: Text(
                      'Aucun produit ajouté à la vente',
                      style: TextStyle(color: AppColors.textLight, fontSize: 13),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _saleItems.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final item = _saleItems[index];
                      return Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          final prod = productProvider.products
                              .where((p) => p.id == item.productId)
                              .firstOrNull;
                          final hasMultiTariff = prod != null &&
                              (prod.priceSemiWholesale > 0 || prod.priceWholesale > 0);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              _showEditUnitPriceModal(context, index, item, prod, productProvider);
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${formatter.format(item.unitPrice)} / unité',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quantity controls (- / +) for draft items
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.primary),
                                          constraints: const BoxConstraints(minWidth: 28),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _decrementItem(index),
                                        ),
                                        Text(
                                          item.quantity.toStringAsFixed(
                                              item.quantity.truncateToDouble() == item.quantity ? 0 : 1),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                                          constraints: const BoxConstraints(minWidth: 28),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _incrementItem(index, productProvider),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 65,
                                      child: Text(
                                        formatter.format(item.total),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                                      constraints: const BoxConstraints(minWidth: 28),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _removeItem(index),
                                    ),
                                  ],
                                ),
                                if (hasMultiTariff) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      _priceTierChip(
                                        label: 'Détail (${formatter.format(prod.price)})',
                                        isSelected: item.unitPrice == prod.price,
                                        onTap: () {
                                          setState(() {
                                            _saleItems[index] = item.copyWith(
                                              unitPrice: prod.price,
                                              total: item.quantity * prod.price,
                                            );
                                            _syncPaidAmount();
                                          });
                                        },
                                      ),
                                      if (prod.priceSemiWholesale > 0)
                                        _priceTierChip(
                                          label: 'Demi-Gros (${formatter.format(prod.priceSemiWholesale)})',
                                          isSelected: item.unitPrice == prod.priceSemiWholesale,
                                          onTap: () {
                                            setState(() {
                                              _saleItems[index] = item.copyWith(
                                                unitPrice: prod.priceSemiWholesale,
                                                total: item.quantity * prod.priceSemiWholesale,
                                              );
                                              _syncPaidAmount();
                                            });
                                          },
                                        ),
                                      if (prod.priceWholesale > 0)
                                        _priceTierChip(
                                          label: 'Gros (${formatter.format(prod.priceWholesale)})',
                                          isSelected: item.unitPrice == prod.priceWholesale,
                                          onTap: () {
                                            setState(() {
                                              _saleItems[index] = item.copyWith(
                                                unitPrice: prod.priceWholesale,
                                                total: item.quantity * prod.priceWholesale,
                                              );
                                              _syncPaidAmount();
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              if (_saleItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtotal line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sous-total brut',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMedium,
                            ),
                          ),
                          Text(
                            formatter.format(_subtotalAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Discount line & input
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.discount_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text(
                            'Réduction',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          // Toggle FCFA / %
                          Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_discountType != 'amount') {
                                      setState(() {
                                        _discountType = 'amount';
                                        _syncPaidAmount();
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _discountType == 'amount' ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      'F',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _discountType == 'amount' ? Colors.white : AppColors.textMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (_discountType != 'percent') {
                                      setState(() {
                                        _discountType = 'percent';
                                        _syncPaidAmount();
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _discountType == 'percent' ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      '%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _discountType == 'percent' ? Colors.white : AppColors.textMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Discount input field
                          SizedBox(
                            width: 95,
                            height: 36,
                            child: TextFormField(
                              controller: _discountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: '0',
                                suffixText: _discountType == 'percent' ? '%' : 'F',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _syncPaidAmount();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_computedDiscountAmount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _discountType == 'percent'
                                  ? 'Remise : - ${_discountCtrl.text.trim()}% (- ${formatter.format(_computedDiscountAmount)})'
                                  : 'Remise : - ${formatter.format(_computedDiscountAmount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 8),
                      // Net total line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Net à payer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            formatter.format(_totalAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // --- Client section (Autocomplete) ---
              Consumer<ClientProvider>(
                builder: (context, clientProvider, child) {
                  final clientName = _clientCtrl.text.trim();
                  final selectedClient = clientProvider.clients
                      .where((c) => c.name.toLowerCase() == clientName.toLowerCase())
                      .firstOrNull;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RawAutocomplete<Client>(
                        textEditingController: _clientCtrl,
                        focusNode: _clientFocusNode,
                        displayStringForOption: (Client option) => option.name,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text.trim().toLowerCase();
                          if (query.isEmpty) {
                            return clientProvider.clients;
                          }
                          return clientProvider.clients.where((Client client) {
                            final nameMatch = client.name.toLowerCase().contains(query);
                            final phoneMatch = client.phone != null && client.phone!.contains(query);
                            return nameMatch || phoneMatch;
                          });
                        },
                        onSelected: (Client selection) {
                          _clientCtrl.text = selection.name;
                          _clientCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: selection.name.length),
                          );
                          _updatePriceForSelectedProduct();
                          setState(() {});
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Client',
                              hintText: 'Rechercher ou saisir un nom (vide = Occasionnel)',
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.primarySurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 48,
                                constraints: const BoxConstraints(maxHeight: 180),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                                  itemBuilder: (context, index) {
                                    final Client option = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      leading: const CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primarySurface,
                                        child: Icon(Icons.person, size: 14, color: AppColors.primary),
                                      ),
                                      title: Text(
                                        option.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      subtitle: option.phone != null && option.phone!.isNotEmpty
                                          ? Text(option.phone!, style: const TextStyle(fontSize: 11))
                                          : null,
                                      trailing: option.hasCreance
                                          ? Text('${option.balance.toStringAsFixed(0)} F', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11))
                                          : (option.hasAvoir
                                              ? Text('${option.avoirAmount.toStringAsFixed(0)} F (Avoir)', style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 11))
                                              : null),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (selectedClient != null && selectedClient.hasAvoir) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.purple.withAlpha(50)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.savings_outlined, color: AppColors.purple, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Avoir disponible : ${formatter.format(selectedClient.avoirAmount)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.purple),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  final avoir = selectedClient.avoirAmount;
                                  final newPaid = _totalAmount > avoir ? _totalAmount - avoir : 0.0;
                                  setState(() {
                                    _isCustomPaid = true;
                                    _paidCtrl.text = newPaid.toStringAsFixed(0);
                                  });
                                  AppToast.showSuccess(context, 'Avoir de ${formatter.format(avoir)} déduit de la vente !');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Utiliser l\'avoir', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              // --- Payment method section ---
              const Text(
                'Mode de paiement',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Espèces', 'Mobile Money', 'Carte', 'Crédit'].map((mode) {
                  final selected = _paymentMethod == mode;
                  return ChoiceChip(
                    label: Text(
                      mode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    selected: selected,
                    selectedColor: mode == 'Crédit' ? AppColors.warning : AppColors.success,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: selected
                          ? (mode == 'Crédit' ? AppColors.warning : AppColors.success)
                          : AppColors.divider,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _paymentMethod = mode;
                          _isCustomPaid = false;
                          if (mode == 'Crédit') {
                            _paidCtrl.text = '0';
                          } else {
                            _paidCtrl.text = _totalAmount.toStringAsFixed(0);
                          }
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              if (_paymentMethod == 'Espèces') ...[
                const SizedBox(height: 8),
                const Text(
                  'Billet / Monnaie reçue :',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMedium),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('Exact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        backgroundColor: AppColors.primarySurface,
                        onPressed: () {
                          setState(() {
                            _paidCtrl.text = _totalAmount.toStringAsFixed(0);
                            _isCustomPaid = true;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      ...[1000, 2000, 5000, 10000, 20000].map((amt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ActionChip(
                            label: Text(formatter.format(amt), style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.background,
                            onPressed: () {
                              setState(() {
                                _paidCtrl.text = amt.toString();
                                _isCustomPaid = true;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // --- Paid Amount input ---
              TextFormField(
                controller: _paidCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant encaissé / versé',
                  suffixText: 'F',
                  filled: true,
                  fillColor: AppColors.primarySurface,
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _isCustomPaid = true;
                  });
                },
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final paidVal = double.tryParse(_paidCtrl.text.trim()) ?? 0;
                  final total = _totalAmount;
                  if (paidVal > total && total > 0) {
                    final change = paidVal - total;
                    return Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Monnaie à rendre : ${formatter.format(change)}',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (paidVal < total && total > 0) {
                    final remaining = total - paidVal;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Reliquat à crédit client : ${formatter.format(remaining)}',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 12),

              // --- Date selection ---
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

              // --- Notes ---
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Remarques optionnelles',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 28),

              // --- Submit button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _saleItems.isNotEmpty
                              ? 'Valider la vente (${formatter.format(_totalAmount)})'
                              : 'Valider la vente',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
    if (_saleItems.isEmpty) {
      AppToast.showError(context, 'Veuillez ajouter au moins un produit à la vente.');
      return;
    }

    setState(() => _saving = true);
    try {
      final clientProvider = context.read<ClientProvider>();
      final rawClientInput = _clientCtrl.text.trim();

      int? clientId;
      String clientName;

      if (rawClientInput.isEmpty) {
        clientName = 'Occasionnel';
        final existingDefault = clientProvider.clients.where(
          (c) => c.name.trim().toLowerCase() == 'occasionnel',
        ).firstOrNull;

        if (existingDefault != null) {
          clientId = existingDefault.id;
        } else {
          clientId = await clientProvider.addClient(Client(
            name: 'Occasionnel',
            notes: 'Client par défaut',
          ));
        }
      } else {
        final existingClient = clientProvider.clients.where(
          (c) => c.name.trim().toLowerCase() == rawClientInput.toLowerCase(),
        ).firstOrNull;

        if (existingClient != null) {
          clientId = existingClient.id;
          clientName = existingClient.name;
        } else {
          clientName = rawClientInput;
          clientId = await clientProvider.addClient(Client(
            name: rawClientInput,
          ));
        }
      }

      final paidVal = double.tryParse(_paidCtrl.text.trim()) ?? _totalAmount;

      final vente = Vente(
        ticketNumber: '',
        clientId: clientId,
        clientName: clientName,
        totalAmount: _totalAmount,
        discountAmount: _computedDiscountAmount,
        paidAmount: paidVal,
        paymentMethod: _paymentMethod,
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        items: List.from(_saleItems),
      );

      await widget.onSave(vente);
      if (mounted) {
        if (paidVal > _totalAmount && clientId != null) {
          final surplus = paidVal - _totalAmount;
          final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
          AppToast.showSuccess(context, 'Vente validée ! Trop-perçu de ${fmt.format(surplus)} crédité en Avoir pour $clientName.');
        }
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'Une erreur est survenue lors de l\'enregistrement.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showEditUnitPriceModal(
    BuildContext context,
    int index,
    VenteItem item,
    Product? prod,
    ProductProvider productProvider,
  ) {
    final priceCtrl = TextEditingController(text: item.unitPrice.toStringAsFixed(0));
    String applyTarget = 'sale_only';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Modifier le Prix Unitaire', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Article : ${item.productName}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau Prix Unitaire (FCFA)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sell_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Portée de la modification :',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textMedium),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setDialogState(() => applyTarget = 'sale_only'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: applyTarget == 'sale_only' ? AppColors.primarySurface : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: applyTarget == 'sale_only' ? AppColors.primary : AppColors.divider,
                        width: applyTarget == 'sale_only' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          applyTarget == 'sale_only' ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: applyTarget == 'sale_only' ? AppColors.primary : AppColors.textLight,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Garder uniquement pour cette vente (Recommandé)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Le prix du produit dans le catalogue restera inchangé.',
                                style: TextStyle(fontSize: 10, color: AppColors.textMedium),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (prod != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setDialogState(() => applyTarget = 'global_catalog'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: applyTarget == 'global_catalog' ? AppColors.primarySurface : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: applyTarget == 'global_catalog' ? AppColors.primary : AppColors.divider,
                          width: applyTarget == 'global_catalog' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            applyTarget == 'global_catalog' ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: applyTarget == 'global_catalog' ? AppColors.primary : AppColors.textLight,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modifier le prix global dans le catalogue',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Le prix de base du produit sera mis à jour dans tout le magasin.',
                                  style: TextStyle(fontSize: 10, color: AppColors.textMedium),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(priceCtrl.text.trim());
                if (newPrice == null || newPrice < 0) {
                  AppToast.showError(context, 'Veuillez saisir un prix valide.');
                  return;
                }
                Navigator.pop(dialogCtx);

                setState(() {
                  _saleItems[index] = item.copyWith(
                    unitPrice: newPrice,
                    total: item.quantity * newPrice,
                  );
                  _syncPaidAmount();
                });

                if (applyTarget == 'global_catalog' && prod != null) {
                  final updatedProd = prod.copyWith(price: newPrice);
                  await productProvider.update(updatedProd);
                  if (context.mounted) {
                    AppToast.showSuccess(context, 'Prix unitaire et prix catalogue du produit mis à jour !');
                  }
                } else {
                  if (context.mounted) {
                    AppToast.showSuccess(context, 'Nouveau prix appliqué pour cette vente.');
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}
