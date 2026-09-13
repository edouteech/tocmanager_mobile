import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import '../widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/client.dart';
import '../models/vente.dart';
import '../providers/client_provider.dart';
import '../providers/vente_provider.dart';
import '../providers/settings_provider.dart';
import '../services/client_payment_pdf_service.dart';
import '../services/client_export_service.dart';
import '../theme/app_theme.dart';
import 'vente_screen.dart';

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
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
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
                _importExcel(context);
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
              const PopupMenuDivider(),
              const PopupMenuItem(
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

          return Column(
            children: [
              _buildStatsBar(provider, formatter),
              _buildSearchBar(provider),
              _buildFilterChipsRow(provider),
              Expanded(
                child: clients.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: clients.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = clients[i];
                          return _buildClientCard(context, c, provider, formatter);
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

  Widget _buildSearchBar(ClientProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un client (nom, téléphone)...',
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
            tooltip: 'Trier les clients',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'debt_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('Créance la plus élevée'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'name_asc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Nom (A - Z)'),
                  ],
                ),
              ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(ClientProvider provider) {
    final debtCount = provider.clients.where((c) => c.hasCreance).length;
    final avoirCount = provider.clients.where((c) => c.hasAvoir).length;
    final paidCount = provider.clients.where((c) => !c.hasCreance && !c.hasAvoir).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Tous (${provider.clients.length})', 'all'),
            const SizedBox(width: 6),
            _filterChip('Avec créance ($debtCount)', 'debt', isWarning: true),
            const SizedBox(width: 6),
            _filterChip('Avec avoir ($avoirCount)', 'avoir', customColor: AppColors.purple),
            const SizedBox(width: 6),
            _filterChip('À jour ($paidCount)', 'paid', isSuccess: true),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String category, {bool isWarning = false, bool isSuccess = false, Color? customColor}) {
    final isSelected = _filterCategory == category;
    Color activeColor = customColor ?? AppColors.primary;
    if (isWarning) activeColor = AppColors.warning;
    if (isSuccess) activeColor = AppColors.success;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterCategory = category),
      selectedColor: activeColor,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatsBar(ClientProvider provider, NumberFormat formatter) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Clients', style: TextStyle(fontSize: 10, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text('${provider.clients.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Créances (Dettes)', style: TextStyle(fontSize: 10, color: AppColors.warning)),
                  const SizedBox(height: 2),
                  Text(formatter.format(provider.totalCreances), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.warning)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.purple.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.purple.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Avoirs Clients', style: TextStyle(fontSize: 10, color: AppColors.purple)),
                  const SizedBox(height: 2),
                  Text(formatter.format(provider.totalAvoirs), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textLight.withAlpha(100)),
          const SizedBox(height: 12),
          const Text('Aucun client trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          const Text('Ajoutez vos clients pour suivre les créances', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, Client client, ClientProvider provider, NumberFormat formatter) {
    final hasDebt = client.balance > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showClientDetailSheet(context, client, provider, formatter),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: hasDebt ? AppColors.warning.withAlpha(30) : AppColors.primarySurface,
                child: Text(
                  client.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: hasDebt ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                    if (client.phone != null && client.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMedium),
                          const SizedBox(width: 4),
                          Text(client.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasDebt ? AppColors.warning.withAlpha(30) : AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasDebt ? 'Créance: ${formatter.format(client.balance)}' : 'À jour',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasDebt ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientDetailSheet(BuildContext context, Client client, ClientProvider provider, NumberFormat formatter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer<VenteProvider>(
        builder: (context, venteProvider, _) {
          final clientSales = venteProvider.items.where((v) {
            final matchId = client.id != null && v.clientId == client.id;
            final matchName = v.clientName?.trim().toLowerCase() == client.name.trim().toLowerCase();
            return matchId || matchName;
          }).toList();

          final debtSales = clientSales.where((v) => v.isCredit).toList();

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: client.balance > 0 ? AppColors.warning.withAlpha(30) : AppColors.primarySurface,
                        child: Text(
                          client.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: client.balance > 0 ? AppColors.warning : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                            Text(client.phone ?? 'Pas de numéro', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  if (client.email != null && client.email!.isNotEmpty) ...[
                    _infoRow(Icons.email_outlined, 'Email', client.email!),
                    const SizedBox(height: 8),
                  ],
                  if (client.address != null && client.address!.isNotEmpty) ...[
                    _infoRow(Icons.location_on_outlined, 'Adresse', client.address!),
                    const SizedBox(height: 8),
                  ],

                  // Debt summary banner
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: client.hasCreance
                          ? AppColors.warning.withAlpha(20)
                          : (client.hasAvoir ? AppColors.purple.withAlpha(20) : AppColors.success.withAlpha(20)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: client.hasCreance
                            ? AppColors.warning.withAlpha(60)
                            : (client.hasAvoir ? AppColors.purple.withAlpha(60) : AppColors.success.withAlpha(60)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              client.hasCreance
                                  ? Icons.account_balance_wallet_outlined
                                  : (client.hasAvoir ? Icons.savings_outlined : Icons.check_circle_outline),
                              color: client.hasCreance
                                  ? AppColors.warning
                                  : (client.hasAvoir ? AppColors.purple : AppColors.success),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.hasCreance
                                      ? 'Créance / Dette Totale'
                                      : (client.hasAvoir ? 'Avoir / Solde Créditeur' : 'Solde client'),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  client.hasAvoir ? '${formatter.format(client.avoirAmount)} (Avoir)' : formatter.format(client.balance),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: client.hasCreance
                                        ? AppColors.warning
                                        : (client.hasAvoir ? AppColors.purple : AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (client.hasCreance)
                          ElevatedButton.icon(
                            onPressed: () {
                              _showPaymentDialog(context, client, provider, debtSales);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.payments_outlined, size: 16),
                            label: const Text('Régler', style: TextStyle(fontSize: 12)),
                          ),
                        if (client.hasAvoir)
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAvoirRefundDialog(context, client, provider);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.savings_outlined, size: 16),
                            label: const Text('Solder l\'avoir', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),

                  // Quick Debt Reminder Section
                  if (client.balance > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withAlpha(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.mark_chat_unread_outlined, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Relance client',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final settings = context.read<SettingsProvider>().settings;
                              final storeName = settings.name.isNotEmpty ? settings.name : 'notre boutique';
                              final message = 'Bonjour ${client.name}, nous vous rappelons votre solde débiteur de ${formatter.format(client.balance)} auprès de $storeName. Merci pour votre confiance !';
                              Share.share(message);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.send_outlined, size: 14),
                            label: const Text('Envoyer rappel', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- Detailed List of Linked Debt Sales ---
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ventes liées / Créances (${clientSales.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                      ),
                      if (debtSales.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${debtSales.length} dette(s) en cours',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (clientSales.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Center(
                        child: Text(
                          'Aucune vente enregistrée pour ce client',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: clientSales.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final v = clientSales[idx];
                        return Material(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              showVenteDetailsModal(context, v);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: v.isCredit ? AppColors.warning.withAlpha(80) : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: v.isCredit ? AppColors.warningLight : AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: v.isCredit ? AppColors.warning : AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.ticketNumber.isNotEmpty ? v.ticketNumber : 'Vente #${v.id}',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(v.date)} • ${v.items.length} article(s)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatter.format(v.totalAmount),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                                      ),
                                      if (v.isCredit) ...[
                                        Text(
                                          'Reste: ${formatter.format(v.remainingAmount)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () {
                                            _showTicketPaymentDialog(context, client, v, provider);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withAlpha(20),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.success.withAlpha(60)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.payments_outlined, size: 12, color: AppColors.success),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Régler ticket',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ] else
                                        const Text(
                                          'Payé',
                                          style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // Bottom action buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showClientForm(context, client: client);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Modifier'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteClient(context, client, provider);
                        },
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMedium),
        const SizedBox(width: 8),
        Text('$label : ', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? AppColors.textDark)),
      ],
    );
  }

  void _showPaymentDialog(BuildContext context, Client client, ClientProvider provider, [List<Vente>? debtSales]) {
    final amountCtrl = TextEditingController(text: client.balance.toStringAsFixed(0));
    String paymentMethod = 'Espèces';
    final paymentMethods = ['Espèces', 'Mobile Money', 'Carte', 'Virement'];
    final previousBalance = client.balance;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Règlement Global de Créances', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solde débiteur : ${client.balance.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Le versement sera alloué en priorité aux tickets de vente les plus anciens.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant versé (FCFA)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Mode de règlement :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => paymentMethod = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(amountCtrl.text);
                if (val == null || val <= 0) {
                  AppToast.showError(context, 'Veuillez saisir un montant de versement valide (> 0 FCFA).');
                  return;
                }
                Navigator.pop(dialogCtx);
                final allDebtSales = debtSales ?? context.read<VenteProvider>().items.where((v) => v.clientId == client.id && v.isCredit).toList();
                await provider.recordGlobalPaymentAllocated(
                  client: client,
                  paymentAmount: val,
                  debtSales: allDebtSales,
                );
                if (context.mounted) {
                  await context.read<VenteProvider>().load();
                }
                if (context.mounted) {
                  _showPaymentSuccessOptions(
                    context,
                    client: client,
                    amountPaid: val,
                    paymentMethod: paymentMethod,
                    previousBalance: previousBalance,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Valider le versement'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketPaymentDialog(BuildContext context, Client client, Vente vente, ClientProvider provider) {
    final amountCtrl = TextEditingController(text: vente.remainingAmount.toStringAsFixed(0));
    String paymentMethod = 'Espèces';
    final paymentMethods = ['Espèces', 'Mobile Money', 'Carte', 'Virement'];
    final previousBalance = client.balance;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Règlement Ticket ${vente.ticketNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket : ${vente.ticketNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reste à payer sur ce ticket : ${vente.remainingAmount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.warning, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant du règlement (FCFA)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Mode de règlement :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => paymentMethod = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(amountCtrl.text);
                if (val == null || val <= 0) {
                  AppToast.showError(context, 'Veuillez saisir un montant valide (> 0 FCFA).');
                  return;
                }
                Navigator.pop(dialogCtx);
                await provider.recordPaymentForVente(
                  client: client,
                  vente: vente,
                  paymentAmount: val,
                );
                if (context.mounted) {
                  await context.read<VenteProvider>().load();
                }
                if (context.mounted) {
                  _showPaymentSuccessOptions(
                    context,
                    client: client,
                    amountPaid: val,
                    paymentMethod: paymentMethod,
                    previousBalance: previousBalance,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Valider le versement'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvoirRefundDialog(BuildContext context, Client client, ClientProvider provider) {
    final amountCtrl = TextEditingController(text: client.avoirAmount.toStringAsFixed(0));
    String paymentMethod = 'Espèces';
    final paymentMethods = ['Espèces', 'Mobile Money', 'Carte', 'Virement'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Solder / Rembourser l\'Avoir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.purple.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client : ${client.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avoir disponible : ${client.avoirAmount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.purple, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant à rembourser (FCFA)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Mode de versement :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => paymentMethod = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(amountCtrl.text);
                if (val == null || val <= 0) {
                  AppToast.showError(context, 'Veuillez saisir un montant de remboursement valide (> 0 FCFA).');
                  return;
                }
                Navigator.pop(dialogCtx);
                await provider.recordAvoirRefund(
                  client: client,
                  refundAmount: val,
                );
                if (context.mounted) {
                  AppToast.showSuccess(context, 'Avoir remboursé avec succès ! Solde mis à jour.');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
              child: const Text('Confirmer le remboursement'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSuccessOptions(
    BuildContext context, {
    required Client client,
    required double amountPaid,
    required String paymentMethod,
    required double previousBalance,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text('Versement Enregistré', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text('Le versement de ${amountPaid.toStringAsFixed(0)} FCFA ($paymentMethod) a été enregistré avec succès.'),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              final settings = context.read<SettingsProvider>().settings;
              ClientPaymentPdfService.sharePaymentReceipt(
                context,
                client: client,
                amountPaid: amountPaid,
                paymentMethod: paymentMethod,
                previousBalance: previousBalance,
                storeSettings: settings,
              );
            },
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Partager le reçu'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final settings = context.read<SettingsProvider>().settings;
              ClientPaymentPdfService.downloadPaymentReceipt(
                context,
                client: client,
                amountPaid: amountPaid,
                paymentMethod: paymentMethod,
                previousBalance: previousBalance,
                storeSettings: settings,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Télécharger le reçu (PDF)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClient(BuildContext context, Client client, ClientProvider provider) {
    if (client.balance > 0) {
      final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Text('Suppression impossible', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          content: Text(
            'Le client "${client.name}" a un solde débiteur actif de ${formatter.format(client.balance)}.\n\nVeuillez d\'abord solder la créance avant de supprimer ce client.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer client', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Supprimer "${client.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteClient(client.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _importExcel(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    try {
      final excel = xl.Excel.decodeBytes(result.files.single.bytes!);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.length < 2) {
        if (context.mounted) {
          AppToast.showError(context, 'Fichier vide ou sans données.');
        }
        return;
      }

      double parseNum(List<xl.Data?> row, int col) {
        if (col < 0 || row.length <= col) return 0;
        final v = row[col]?.value;
        if (v is xl.IntCellValue) return v.value.toDouble();
        if (v is xl.DoubleCellValue) return v.value;
        final s = v?.toString().replaceAll(' ', '').replaceAll(',', '.') ?? '';
        return double.tryParse(s) ?? 0;
      }

      int colName = 0;
      int colPhone = 1;
      int colEmail = -1;
      int colAddress = -1;
      int colBalance = -1;
      int colType = -1;

      // Détection automatique des colonnes par les en-têtes
      if (sheet.rows.isNotEmpty) {
        final header = sheet.rows[0];
        for (var c = 0; c < header.length; c++) {
          final title = header[c]?.value?.toString().toLowerCase().trim() ?? '';
          if (title.contains('nom') || title.contains('client')) {
            colName = c;
          } else if (title.contains('tél') || title.contains('tel') || title.contains('phone') || title.contains('contact')) {
            colPhone = c;
          } else if (title.contains('email') || title.contains('mail')) {
            colEmail = c;
          } else if (title.contains('adresse') || title.contains('ville') || title.contains('lieu')) {
            colAddress = c;
          } else if (title.contains('solde') || title.contains('dette') || title.contains('créance') || title.contains('creance') || title.contains('balance')) {
            colBalance = c;
          } else if (title.contains('type') || title.contains('catégorie')) {
            colType = c;
          }
        }
      }

      final toImport = <Map<String, dynamic>>[];
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final name = (row.length > colName ? row[colName]?.value?.toString() : null)?.trim() ?? '';
        if (name.isEmpty) continue;

        final phone = (colPhone >= 0 && row.length > colPhone)
            ? row[colPhone]?.value?.toString().trim()
            : null;
        final email = (colEmail >= 0 && row.length > colEmail)
            ? row[colEmail]?.value?.toString().trim()
            : null;
        final address = (colAddress >= 0 && row.length > colAddress)
            ? row[colAddress]?.value?.toString().trim()
            : null;
        final balance = colBalance >= 0 ? parseNum(row, colBalance) : 0.0;
        final typeStr = (colType >= 0 && row.length > colType)
            ? (row[colType]?.value?.toString().toLowerCase().trim() ?? 'detail')
            : 'detail';

        String clientType = 'detail';
        if (typeStr.contains('gros') && !typeStr.contains('demi')) {
          clientType = 'gros';
        } else if (typeStr.contains('demi')) {
          clientType = 'demi_gros';
        }

        toImport.add({
          'name': name,
          'phone': phone?.isNotEmpty == true ? phone : null,
          'email': email?.isNotEmpty == true ? email : null,
          'address': address?.isNotEmpty == true ? address : null,
          'balance': balance,
          'clientType': clientType,
        });
      }

      if (toImport.isEmpty) {
        if (context.mounted) {
          AppToast.showError(context, 'Aucun client valide trouvé dans le fichier.');
        }
        return;
      }

      if (!context.mounted) return;
      _showImportPreview(context, toImport);
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur de lecture du fichier Excel: $e');
      }
    }
  }

  void _showImportPreview(BuildContext context, List<Map<String, dynamic>> rows) {
    final clientProvider = context.read<ClientProvider>();
    final existingNames = {
      for (final c in clientProvider.clients) c.name.toLowerCase().trim()
    };

    final newCount = rows.where((r) => !existingNames.contains((r['name'] as String).toLowerCase().trim())).length;
    final alreadyExistCount = rows.length - newCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final preview = rows.take(4).toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.upload_file_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Importer ${rows.length} client${rows.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  '$newCount nouveau${newCount > 1 ? 'x' : ''} client${newCount > 1 ? 's' : ''} à créer'
                  '${alreadyExistCount > 0 ? ' ($alreadyExistCount déjà existant${alreadyExistCount > 1 ? 's' : ''} ignoré${alreadyExistCount > 1 ? 's' : ''})' : ''}.',
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                ...preview.map((r) {
                  final isDuplicate = existingNames.contains((r['name'] as String).toLowerCase().trim());
                  final phone = r['phone'] as String?;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Icon(
                        isDuplicate ? Icons.info_outline : Icons.check_circle_outline,
                        size: 18,
                        color: isDuplicate ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDuplicate ? AppColors.textMedium : AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (phone != null)
                              Text(
                                phone,
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                          ],
                        ),
                      ),
                      if (isDuplicate)
                        const Text(
                          'Déjà existant',
                          style: TextStyle(fontSize: 11, color: AppColors.warning),
                        ),
                    ]),
                  );
                }),
                if (rows.length > 4) ...[
                  Text(
                    '… et ${rows.length - 4} autre${rows.length - 4 > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                ],
                const Divider(height: 1),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _confirmImport(context, rows);
                    },
                    child: const Text("Confirmer l'importation"),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmImport(
    BuildContext context,
    List<Map<String, dynamic>> rows,
  ) async {
    final clientProvider = context.read<ClientProvider>();
    final existingNames = {
      for (final c in clientProvider.clients) c.name.toLowerCase().trim()
    };

    int createdCount = 0;
    for (final r in rows) {
      final key = (r['name'] as String).toLowerCase().trim();
      if (existingNames.contains(key)) continue;

      final newClient = Client(
        name: (r['name'] as String).trim(),
        phone: r['phone'] as String?,
        email: r['email'] as String?,
        address: r['address'] as String?,
        balance: (r['balance'] as double?) ?? 0.0,
        clientType: (r['clientType'] as String?) ?? 'detail',
      );

      await clientProvider.addClient(newClient);
      existingNames.add(key);
      createdCount++;
    }

    if (context.mounted) {
      AppToast.showSuccess(
        context,
        createdCount > 0
            ? '$createdCount client${createdCount > 1 ? 's' : ''} importé${createdCount > 1 ? 's' : ''} avec succès.'
            : 'Aucun nouveau client à importer (tous déjà existants).',
      );
    }
  }

  void _showClientForm(BuildContext context, {Client? client}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ClientForm(client: client),
    );
  }
}

class _ClientForm extends StatefulWidget {
  final Client? client;

  const _ClientForm({this.client});

  @override
  State<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<_ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _balanceController;
  late String _clientType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _addressController = TextEditingController(text: widget.client?.address ?? '');
    _balanceController = TextEditingController(text: widget.client?.balance.toString() ?? '0');
    _clientType = widget.client?.clientType ?? 'detail';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Modifier Client' : 'Nouveau Client',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom complet *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez entrer le nom' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _clientType,
                decoration: const InputDecoration(
                  labelText: 'Type de tarif attribué',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.style_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: 'detail', child: Text('Client Détail (Standard)')),
                  DropdownMenuItem(value: 'demi_gros', child: Text('Client Demi-Gros')),
                  DropdownMenuItem(value: 'gros', child: Text('Client Grossiste')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _clientType = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresse / Quartier', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Solde initial (Créance en FCFA)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveClient,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(isEditing ? 'Enregistrer les modifications' : 'Ajouter le client'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ClientProvider>();
    final newClient = Client(
      id: widget.client?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      balance: double.tryParse(_balanceController.text) ?? 0.0,
      clientType: _clientType,
      createdAt: widget.client?.createdAt ?? DateTime.now(),
    );

    if (widget.client != null) {
      await provider.updateClient(newClient);
    } else {
      await provider.addClient(newClient);
    }

    if (mounted) Navigator.pop(context);
  }
}
