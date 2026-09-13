import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import '../widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import '../providers/approvisionnement_provider.dart';
import '../providers/settings_provider.dart';
import '../services/supplier_payment_pdf_service.dart';
import '../services/supplier_export_service.dart';
import '../theme/app_theme.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _search = '';
  String _filterCategory = 'all'; // 'all', 'debt', 'paid'
  String _sortBy = 'debt_desc'; // 'debt_desc', 'name_asc', 'recent'

  String _getFilterLabel() {
    if (_filterCategory == 'debt') return 'Fournisseurs avec dette';
    if (_filterCategory == 'paid') return 'Fournisseurs à jour';
    return 'Tous les fournisseurs';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fournisseurs & Dettes', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Retour',
        ),
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
              final suppliers = context.read<SupplierProvider>().suppliers;
              final filterLabel = _getFilterLabel();
              if (val == 'excel') {
                SupplierExportService.exportSuppliersExcel(context, suppliers, filterLabel);
              } else if (val == 'pdf') {
                SupplierExportService.exportSuppliersPdfReport(context, suppliers, filterLabel, settings);
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
                    Text('Importer des fournisseurs'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showSupplierForm(context),
            icon: const Icon(Icons.group_add_outlined, color: AppColors.primary),
            tooltip: 'Nouveau fournisseur',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<SupplierProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final rawSuppliers = provider.suppliers.where((s) {
            final matchName = s.name.toLowerCase().contains(_search.toLowerCase());
            final matchContact = s.contactPerson?.toLowerCase().contains(_search.toLowerCase()) ?? false;
            final matchPhone = s.phone?.contains(_search) ?? false;
            return matchName || matchContact || matchPhone;
          }).toList();

          final suppliers = rawSuppliers.where((s) {
            if (_filterCategory == 'debt') return s.balance > 0;
            if (_filterCategory == 'paid') return s.balance <= 0;
            return true;
          }).toList();

          if (_sortBy == 'debt_desc') {
            suppliers.sort((a, b) => b.balance.compareTo(a.balance));
          } else if (_sortBy == 'name_asc') {
            suppliers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } else if (_sortBy == 'recent') {
            suppliers.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
          }

          return Column(
            children: [
              _buildStatsBar(provider, formatter),
              _buildSearchBar(),
              _buildFilterChipsRow(provider),
              Expanded(
                child: suppliers.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: suppliers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final s = suppliers[i];
                          return _buildSupplierCard(context, s, provider, formatter);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business),
        label: const Text('Nouveau Fournisseur'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un fournisseur (société, contact)...',
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
            tooltip: 'Trier les fournisseurs',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'debt_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Dette la plus élevée'),
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

  Widget _buildFilterChipsRow(SupplierProvider provider) {
    final debtCount = provider.suppliers.where((s) => s.balance > 0).length;
    final paidCount = provider.suppliers.where((s) => s.balance <= 0).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Tous (${provider.suppliers.length})', 'all'),
            const SizedBox(width: 6),
            _filterChip('Avec dette ($debtCount)', 'debt', isDanger: true),
            const SizedBox(width: 6),
            _filterChip('À jour ($paidCount)', 'paid', isSuccess: true),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String category, {bool isDanger = false, bool isSuccess = false}) {
    final selected = _filterCategory == category;
    final activeColor = isDanger
        ? AppColors.danger
        : isSuccess
            ? AppColors.success
            : AppColors.primary;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      selected: selected,
      selectedColor: activeColor,
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: selected ? activeColor : AppColors.divider,
      ),
      onSelected: (val) {
        if (val) setState(() => _filterCategory = category);
      },
    );
  }

  Widget _buildStatsBar(SupplierProvider provider, NumberFormat formatter) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Fournisseurs', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text('${provider.suppliers.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dettes Impayées', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                  const SizedBox(height: 2),
                  Text(formatter.format(provider.totalDettes), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.danger)),
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
          Icon(Icons.business_outlined, size: 64, color: AppColors.textLight.withAlpha(100)),
          const SizedBox(height: 12),
          const Text('Aucun fournisseur trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          const Text('Ajoutez vos fournisseurs pour le suivi de vos commandes', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(BuildContext context, Supplier supplier, SupplierProvider provider, NumberFormat formatter) {
    final hasDebt = supplier.balance > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showSupplierDetailSheet(context, supplier, provider, formatter),
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
                backgroundColor: AppColors.primarySurface,
                child: const Icon(Icons.business, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                    if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Contact: ${supplier.contactPerson}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ],
                    if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMedium),
                          const SizedBox(width: 4),
                          Text(supplier.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
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
                      color: hasDebt ? AppColors.danger.withAlpha(30) : AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasDebt ? 'Impayé: ${formatter.format(supplier.balance)}' : 'Solde nul',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasDebt ? AppColors.danger : AppColors.success,
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

  void _showSupplierDetailSheet(BuildContext context, Supplier supplier, SupplierProvider provider, NumberFormat formatter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(Icons.business, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(supplier.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        Text(supplier.contactPerson ?? 'Fournisseur', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                _infoRow(Icons.phone_outlined, 'Téléphone', supplier.phone!),
                const SizedBox(height: 10),
              ],
              if (supplier.email != null && supplier.email!.isNotEmpty) ...[
                _infoRow(Icons.email_outlined, 'Email', supplier.email!),
                const SizedBox(height: 10),
              ],
              if (supplier.address != null && supplier.address!.isNotEmpty) ...[
                _infoRow(Icons.location_on_outlined, 'Adresse', supplier.address!),
                const SizedBox(height: 10),
              ],
              _infoRow(Icons.account_balance_wallet_outlined, 'Factures Impayées', formatter.format(supplier.balance), color: supplier.balance > 0 ? AppColors.danger : AppColors.success),
              const SizedBox(height: 20),
              if (supplier.balance > 0) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSupplierPaymentDialog(context, supplier, formatter);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Enregistrer un règlement', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showSupplierForm(context, supplier: supplier);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteSupplier(context, supplier, provider);
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupplierPaymentDialog(BuildContext context, Supplier supplier, NumberFormat formatter) {
    final amountCtrl = TextEditingController(text: supplier.balance.toStringAsFixed(0));
    String paymentMethod = 'Espèces';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: AppColors.success, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Règlement Fournisseur : ${supplier.name}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dette actuelle :', style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
                        Text(formatter.format(supplier.balance), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.danger)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Mode de règlement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Espèces', 'Mobile Money', 'Virement', 'Chèque'].map((mode) {
                      final selected = paymentMethod == mode;
                      return ChoiceChip(
                        label: Text(mode, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Colors.white : AppColors.textDark)),
                        selected: selected,
                        selectedColor: AppColors.success,
                        backgroundColor: AppColors.background,
                        side: BorderSide(color: selected ? AppColors.success : AppColors.divider),
                        onSelected: (val) {
                          if (val) setSheetState(() => paymentMethod = mode);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Montant versé',
                      suffixText: 'F',
                      filled: true,
                      fillColor: AppColors.primarySurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final paid = double.tryParse(amountCtrl.text.trim()) ?? 0;
                        if (paid <= 0) {
                          AppToast.showError(context, 'Saisissez un montant valide');
                          return;
                        }

                        await context.read<SupplierProvider>().recordSupplierPayment(supplier.id!, paid);
                        if (!context.mounted) return;
                        await context.read<ApprovisionnementProvider>().load();

                        if (!context.mounted) return;
                        final updatedSupplier = context.read<SupplierProvider>().suppliers.where((s) => s.id == supplier.id).firstOrNull ?? supplier;
                        final remaining = updatedSupplier.balance;

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showPaymentSuccessDialog(context, updatedSupplier, paid, paymentMethod, remaining);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Valider le versement', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentSuccessDialog(BuildContext context, Supplier supplier, double amountPaid, String paymentMethod, double remainingDebt) {
    final settings = context.read<SettingsProvider>().settings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Text('Règlement enregistré', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Un versement de ${NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(amountPaid)} a été imputé au fournisseur "${supplier.name}".'),
            const SizedBox(height: 12),
            Text('Nouveau solde dû : ${NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(remainingDebt)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              SupplierPaymentPdfService.shareReceipt(
                context: context,
                supplier: supplier,
                amountPaid: amountPaid,
                paymentMethod: paymentMethod,
                remainingDebt: remainingDebt,
                settings: settings,
              );
            },
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('Partager'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              SupplierPaymentPdfService.downloadReceipt(
                context: context,
                supplier: supplier,
                amountPaid: amountPaid,
                paymentMethod: paymentMethod,
                remainingDebt: remainingDebt,
                settings: settings,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Télécharger Reçu'),
          ),
        ],
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

  void _confirmDeleteSupplier(BuildContext context, Supplier supplier, SupplierProvider provider) {
    if (supplier.balance > 0) {
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
            'Le fournisseur "${supplier.name}" a un reste dû de ${formatter.format(supplier.balance)}.\n\nVeuillez d\'abord solder ce règlement avant de supprimer ce fournisseur.',
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
        title: const Text('Supprimer fournisseur', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Supprimer "${supplier.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteSupplier(supplier.id!);
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
      int colContact = -1;
      int colPhone = 1;
      int colEmail = -1;
      int colAddress = -1;
      int colBalance = -1;

      // Détection automatique des colonnes par les en-têtes
      if (sheet.rows.isNotEmpty) {
        final header = sheet.rows[0];
        for (var c = 0; c < header.length; c++) {
          final title = header[c]?.value?.toString().toLowerCase().trim() ?? '';
          if (title.contains('société') || title.contains('societe') || title.contains('fournisseur') || title.contains('nom')) {
            colName = c;
          } else if (title.contains('contact') || title.contains('interlocuteur') || title.contains('responsable')) {
            colContact = c;
          } else if (title.contains('tél') || title.contains('tel') || title.contains('phone')) {
            colPhone = c;
          } else if (title.contains('email') || title.contains('mail')) {
            colEmail = c;
          } else if (title.contains('adresse') || title.contains('ville') || title.contains('lieu')) {
            colAddress = c;
          } else if (title.contains('solde') || title.contains('dette') || title.contains('balance')) {
            colBalance = c;
          }
        }
      }

      final toImport = <Map<String, dynamic>>[];
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final name = (row.length > colName ? row[colName]?.value?.toString() : null)?.trim() ?? '';
        if (name.isEmpty) continue;

        final contact = (colContact >= 0 && row.length > colContact)
            ? row[colContact]?.value?.toString().trim()
            : null;
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

        toImport.add({
          'name': name,
          'contactPerson': contact?.isNotEmpty == true ? contact : null,
          'phone': phone?.isNotEmpty == true ? phone : null,
          'email': email?.isNotEmpty == true ? email : null,
          'address': address?.isNotEmpty == true ? address : null,
          'balance': balance,
        });
      }

      if (toImport.isEmpty) {
        if (context.mounted) {
          AppToast.showError(context, 'Aucun fournisseur valide trouvé dans le fichier.');
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
    final supplierProvider = context.read<SupplierProvider>();
    final existingNames = {
      for (final s in supplierProvider.suppliers) s.name.toLowerCase().trim()
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
                    'Importer ${rows.length} fournisseur${rows.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  '$newCount nouveau${newCount > 1 ? 'x' : ''} fournisseur${newCount > 1 ? 's' : ''} à créer'
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
    final supplierProvider = context.read<SupplierProvider>();
    final existingNames = {
      for (final s in supplierProvider.suppliers) s.name.toLowerCase().trim()
    };

    int createdCount = 0;
    for (final r in rows) {
      final key = (r['name'] as String).toLowerCase().trim();
      if (existingNames.contains(key)) continue;

      final newSupplier = Supplier(
        name: (r['name'] as String).trim(),
        contactPerson: r['contactPerson'] as String?,
        phone: r['phone'] as String?,
        email: r['email'] as String?,
        address: r['address'] as String?,
        balance: (r['balance'] as double?) ?? 0.0,
      );

      await supplierProvider.addSupplier(newSupplier);
      existingNames.add(key);
      createdCount++;
    }

    if (context.mounted) {
      AppToast.showSuccess(
        context,
        createdCount > 0
            ? '$createdCount fournisseur${createdCount > 1 ? 's' : ''} importé${createdCount > 1 ? 's' : ''} avec succès.'
            : 'Aucun nouveau fournisseur à importer (tous déjà existants).',
      );
    }
  }

  void _showSupplierForm(BuildContext context, {Supplier? supplier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SupplierForm(supplier: supplier),
    );
  }
}

class _SupplierForm extends StatefulWidget {
  final Supplier? supplier;

  const _SupplierForm({this.supplier});

  @override
  State<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<_SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.supplier?.name ?? '');
  late final _contactCtrl = TextEditingController(text: widget.supplier?.contactPerson ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.supplier?.phone ?? '');
  late final _emailCtrl = TextEditingController(text: widget.supplier?.email ?? '');
  late final _addressCtrl = TextEditingController(text: widget.supplier?.address ?? '');
  late final _balanceCtrl = TextEditingController(text: widget.supplier != null ? widget.supplier!.balance.toStringAsFixed(0) : '0');
  late final _notesCtrl = TextEditingController(text: widget.supplier?.notes ?? '');

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(isEdit ? 'Modifier Fournisseur' : 'Nouveau Fournisseur', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom de la société / Nom *'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Le nom du fournisseur est obligatoire';
                if (val.trim().length < 2) return 'Le nom doit contenir au moins 2 caractères';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Personne de contact')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty && val.trim().length < 8) {
                  return 'Numéro de téléphone invalide (min. 8 chiffres)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                  return 'Adresse email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Adresse')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Solde impayé / Dette fournisseur (FCFA)'),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final num = double.tryParse(val.trim());
                  if (num == null || num < 0) return 'Saisissez un montant valide (>= 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    AppToast.showError(context, 'Veuillez corriger le nom ou le contact du fournisseur.');
                    return;
                  }
                  final name = _nameCtrl.text.trim();
                  final nav = Navigator.of(context);
                  final provider = context.read<SupplierProvider>();
                  final s = Supplier(
                    id: widget.supplier?.id,
                    name: name,
                    contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                    email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                    address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
                    balance: double.tryParse(_balanceCtrl.text) ?? 0,
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                    createdAt: widget.supplier?.createdAt ?? DateTime.now(),
                  );
                  if (isEdit) {
                    await provider.updateSupplier(s);
                  } else {
                    await provider.addSupplier(s);
                  }
                  if (mounted) nav.pop();
                },
                child: Text(isEdit ? 'Modifier' : 'Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
