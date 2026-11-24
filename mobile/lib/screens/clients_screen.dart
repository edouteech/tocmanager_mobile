import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/vente_provider.dart';
import '../services/client_export_service.dart';
import '../theme/app_theme.dart';
import 'clients/client_card.dart';
import 'clients/client_detail_sheet.dart';
import 'clients/client_filters_and_stats.dart';
import 'clients/client_form_modal.dart';
import 'clients/client_import_service.dart';
import 'clients/client_payment_dialogs.dart';
import 'clients/client_refund_and_success_dialogs.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _search = '';
  String _filterCategory = 'all'; // 'all', 'debt', 'paid'
  String _sortBy = 'debt_desc'; // 'debt_desc', 'name_asc', 'recent'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
      context.read<VenteProvider>().load();
    });
  }

  String _getFilterLabel() {
    if (_filterCategory == 'debt') return 'Clients avec créance';
    if (_filterCategory == 'paid') return 'Clients à jour';
    return 'Tous les clients';
  }

  void _showClientForm(BuildContext context, {Client? client}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => ClientFormModal(client: client),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clients & Créances', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Exporter le registre',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.ios_share_outlined, color: AppColors.primary, size: 20),
            ),
            onSelected: (val) {
              final settings = context.read<SettingsProvider>().settings;
              final clients = context.read<ClientProvider>().clients;
              final filterLabel = _getFilterLabel();
              if (val == 'excel') {
                ClientExportService.exportClientsExcel(context, clients, filterLabel);
              } else if (val == 'pdf') {
                ClientExportService.exportClientsPdfReport(context, clients, filterLabel, settings);
              } else if (val == 'import') {
                importClientsFromExcel(context);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 18, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Exporter Excel (.xlsx)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Rapport PDF (A4)'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Importer des clients'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showClientForm(context),
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
            tooltip: 'Nouveau client',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<ClientProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final rawClients = provider.clients.where((c) {
            final matchName = c.name.toLowerCase().contains(_search.toLowerCase());
            final matchPhone = c.phone?.contains(_search) ?? false;
            return matchName || matchPhone;
          }).toList();

          final clients = rawClients.where((c) {
            if (_filterCategory == 'debt') return c.hasCreance;
            if (_filterCategory == 'avoir') return c.hasAvoir;
            if (_filterCategory == 'paid') return !c.hasCreance && !c.hasAvoir;
            return true;
          }).toList();

          if (_sortBy == 'debt_desc') {
            clients.sort((a, b) => b.balance.compareTo(a.balance));
          } else if (_sortBy == 'name_asc') {
            clients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } else if (_sortBy == 'recent') {
            clients.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
          }

          final debtCount = provider.clients.where((c) => c.hasCreance).length;
          final avoirCount = provider.clients.where((c) => c.hasAvoir).length;
          final paidCount = provider.clients.where((c) => !c.hasCreance && !c.hasAvoir).length;

          return Column(
            children: [
              ClientStatsBar(
                totalClients: provider.clients.length,
                totalCreances: provider.totalCreances,
                totalAvoirs: provider.totalAvoirs,
                formatter: formatter,
              ),
              ClientSearchAndSortBar(
                onSearchChanged: (v) => setState(() => _search = v),
                onSortSelected: (val) => setState(() => _sortBy = val),
              ),
              ClientFilterChipsRow(
                filterCategory: _filterCategory,
                totalCount: provider.clients.length,
                debtCount: debtCount,
                avoirCount: avoirCount,
                paidCount: paidCount,
                onFilterChanged: (category) => setState(() => _filterCategory = category),
              ),
              Expanded(
                child: clients.isEmpty
                    ? const ClientEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: clients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = clients[i];
                          return ClientCard(
                            client: c,
                            formatter: formatter,
                            onTap: () => showClientDetailSheet(
                              context,
                              c,
                              formatter,
                              onPayGlobal: (debtSales) =>
                                  showClientGlobalPaymentDialog(context, c, provider, debtSales),
                              onRefundAvoir: () => showClientAvoirRefundDialog(context, c, provider),
                              onPayTicket: (v) => showClientTicketPaymentDialog(context, c, v, provider),
                              onEdit: () => _showClientForm(context, client: c),
                              onDelete: () => confirmDeleteClientDialog(context, c, provider),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau Client'),
      ),
    );
  }
}
