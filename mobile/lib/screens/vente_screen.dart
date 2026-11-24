import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/date_filter_period.dart';
import '../models/vente.dart';
import '../providers/client_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tenant_provider.dart';
import '../providers/vente_provider.dart';
import '../services/ticket_pdf_service.dart';
import '../services/vente_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/select_operational_magasin_modal.dart';
import 'ventes/vente_data_table.dart';
import 'ventes/vente_details_footer.dart';
import 'ventes/vente_details_modal.dart';
import 'ventes/vente_filter_helpers.dart';
import 'ventes/vente_filters_bar.dart';
import 'ventes/vente_form_modal.dart';
import 'ventes/vente_header_and_summary.dart';
import 'ventes/vente_mobile_list.dart';

export 'ventes/vente_details_modal.dart';

class VenteScreen extends StatefulWidget {
  const VenteScreen({super.key});

  @override
  State<VenteScreen> createState() => _VenteScreenState();
}

class _VenteScreenState extends State<VenteScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateFilterPeriod _dateFilter = DateFilterPeriod.all();
  bool _onlyCredit = false;
  String _sortBy = 'recent';

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

  Future<void> _showForm(BuildContext context, {Vente? initialVente}) async {
    if (initialVente == null) {
      final tenant = context.read<TenantProvider>();
      if (tenant.needsOperationalMagasin(isSale: true)) {
        final chosen = await SelectOperationalMagasinModal.show(context, isSale: true);
        if (chosen == null || !context.mounted) return;
        await tenant.selectMagasin(chosen);
        if (!context.mounted) return;
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => VenteFormModal(
        initialVente: initialVente,
        onSave: (vente) async {
          final venteProvider = context.read<VenteProvider>();
          final productProvider = context.read<ProductProvider>();
          final clientProvider = context.read<ClientProvider>();
          if (initialVente != null) {
            await venteProvider.update(vente);
          } else {
            await venteProvider.add(vente);
          }
          await productProvider.load();
          await clientProvider.loadClients();
        },
      ),
    );
  }

  void _handleExport(BuildContext context, String format, List<Vente> ventes) {
    final settings = context.read<SettingsProvider>().settings;
    final periodName = ventePeriodLabel(onlyCredit: _onlyCredit, dateFilter: _dateFilter);
    if (format == 'excel') {
      VenteExportService.exportVentesExcel(context, ventes, periodName);
    } else if (format == 'pdf') {
      VenteExportService.exportVentesPdfReport(context, ventes, periodName, settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: settings.currency, decimalDigits: 0);
    final isWide = MediaQuery.of(context).size.width >= 760;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'vente_fab',
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nouvelle vente', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Consumer<VenteProvider>(
          builder: (_, provider, __) {
            final filtered = filterAndSortVentes(
              provider.items,
              onlyCredit: _onlyCredit,
              dateFilter: _dateFilter,
              searchQuery: _searchQuery,
              sortBy: _sortBy,
            );
            final isFiltered = _onlyCredit || _dateFilter.preset != PeriodPreset.all || _searchQuery.trim().isNotEmpty;
            final filteredTotal = filtered.fold(0.0, (sum, v) => sum + v.totalAmount);

            return Column(
              children: [
                VenteScreenHeader(
                  onBack: () => Navigator.maybePop(context),
                  onExportSelected: (fmt) => _handleExport(context, fmt, filtered),
                  onNewVente: () => _showForm(context),
                ),
                VenteSummaryCards(
                  filteredCount: filtered.length,
                  totalFilteredAmount: filteredTotal,
                  todaySalesAmount: provider.todaySalesAmount,
                  totalSalesAmount: provider.totalSalesAmount,
                  isFiltered: isFiltered,
                  formatter: formatter,
                ),
                VenteSearchAndSortBar(
                  searchCtrl: _searchCtrl,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  onClearSearch: () => setState(() {
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }),
                  onSortSelected: (val) => setState(() => _sortBy = val),
                ),
                VenteFilterChipsRow(
                  dateFilter: _dateFilter,
                  onlyCredit: _onlyCredit,
                  onSelectAll: () => setState(() {
                    _onlyCredit = false;
                    _dateFilter = DateFilterPeriod.all();
                  }),
                  onSelectToday: () => setState(() => _dateFilter = DateFilterPeriod.today()),
                  onSelectWeek: () => setState(() => _dateFilter = DateFilterPeriod.thisWeek()),
                  onSelectMonth: () => setState(() => _dateFilter = DateFilterPeriod.thisMonth()),
                  onToggleCredit: () => setState(() => _onlyCredit = !_onlyCredit),
                  onCustomPeriod: (picked) => setState(() => _dateFilter = picked),
                ),
                Expanded(
                  child: provider.loading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? const VenteEmptyState()
                          : isWide
                              ? VenteDataTable(
                                  items: filtered,
                                  formatter: formatter,
                                  onTapVente: (v) => showVenteDetailsModal(context, v),
                                  onEdit: (v) => _showForm(context, initialVente: v),
                                  onPrint: (v) => TicketPdfService.downloadTicketPdf(context, v, settings),
                                  onDelete: (v) => showConfirmDeleteVenteModal(
                                    context,
                                    v,
                                    provider,
                                    context.read<ProductProvider>(),
                                    clientProvider: context.read<ClientProvider>(),
                                  ),
                                )
                              : VenteMobileCardList(
                                  items: filtered,
                                  formatter: formatter,
                                  onTapVente: (v) => showVenteDetailsModal(context, v),
                                ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
