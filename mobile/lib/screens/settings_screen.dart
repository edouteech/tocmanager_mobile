import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/approvisionnement_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/client_provider.dart';
import '../providers/decaissement_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/vente_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'settings/settings_backup_danger_section.dart';
import 'settings/settings_section_card.dart';
import 'settings/settings_store_forms.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _currencyCtrl;

  bool _initialized = false;
  bool _saving = false;
  bool _backingUp = false;
  bool _restoring = false;
  bool _clearingData = false;
  bool _enableAverageCostPrice = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _footerCtrl = TextEditingController();
    _currencyCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = context.read<SettingsProvider>().settings;
      _nameCtrl.text = settings.name;
      _phoneCtrl.text = settings.phone;
      _emailCtrl.text = settings.email;
      _addressCtrl.text = settings.address;
      _footerCtrl.text = settings.receiptFooter;
      _currencyCtrl.text = settings.currency;
      _enableAverageCostPrice = settings.enableAverageCostPrice;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _footerCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadAllProviders() async {
    final prodProv = context.read<ProductProvider>();
    final clientProv = context.read<ClientProvider>();
    final suppProv = context.read<SupplierProvider>();
    final venteProv = context.read<VenteProvider>();
    final decProv = context.read<DecaissementProvider>();
    final catProv = context.read<CategoryProvider>();
    final appProv = context.read<ApprovisionnementProvider>();

    await prodProv.load();
    await clientProv.loadClients();
    await suppProv.loadSuppliers();
    await venteProv.load();
    await decProv.load();
    await catProv.load();
    await appProv.load();
  }

  Future<void> _saveSettings(SettingsProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez remplir les champs obligatoires.');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = StoreSettings(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        receiptFooter: _footerCtrl.text.trim(),
        currency: _currencyCtrl.text.trim(),
        enableAverageCostPrice: _enableAverageCostPrice,
      );
      await provider.updateSettings(updated);
      if (mounted) {
        AppToast.showSuccess(context, 'Paramètres du magasin enregistrés avec succès !');
      }
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'Erreur lors de l\'enregistrement des paramètres.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _backupDb(SettingsProvider provider) async {
    setState(() => _backingUp = true);
    try {
      final path = await provider.exportDatabaseBackup();
      if (path != null && mounted) {
        AppToast.showSuccess(context, 'Sauvegarde de la base de données exportée !');
      } else if (mounted) {
        AppToast.showError(context, 'Impossible d\'exporter la sauvegarde.');
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _restoreDb(SettingsProvider provider) async {
    final confirm = await showRestoreConfirmDialog(context);
    if (confirm != true) return;

    setState(() => _restoring = true);
    try {
      final success = await provider.restoreDatabaseBackup();
      if (success && mounted) {
        await _reloadAllProviders();
        if (mounted) AppToast.showSuccess(context, 'Base de données restaurée avec succès !');
      } else if (mounted) {
        AppToast.showError(context, 'Restauration annulée ou fichier invalide.');
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _confirmAndClearData(SettingsProvider provider) async {
    final confirm = await showClearDataConfirmDialog(context);
    if (confirm != true) return;

    setState(() => _clearingData = true);
    try {
      final backupPath = await provider.createSafetyBackup();
      await provider.clearBusinessData();
      if (mounted) await _reloadAllProviders();
      if (mounted) await showClearDataSuccessDialog(context, backupPath);
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Erreur lors du vidage des données: $e');
    } finally {
      if (mounted) setState(() => _clearingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres du Magasin', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsStoreProfileSection(
                    nameCtrl: _nameCtrl,
                    phoneCtrl: _phoneCtrl,
                    currencyCtrl: _currencyCtrl,
                    emailCtrl: _emailCtrl,
                    addressCtrl: _addressCtrl,
                    footerCtrl: _footerCtrl,
                    saving: _saving,
                    onSave: () => _saveSettings(provider),
                  ),
                  const SizedBox(height: 20),
                  SettingsPricingSection(
                    enableAverageCostPrice: _enableAverageCostPrice,
                    onToggleAverageCost: (val) => setState(() => _enableAverageCostPrice = val),
                    saving: _saving,
                    onSave: () => _saveSettings(provider),
                  ),
                  const SizedBox(height: 20),
                  SettingsBackupCard(
                    backingUp: _backingUp,
                    restoring: _restoring,
                    onBackup: () => _backupDb(provider),
                    onRestore: () => _restoreDb(provider),
                  ),
                  const SizedBox(height: 20),
                  const SettingsCloudSyncCard(),
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    const SettingsUsersAdminCard(),
                  ],
                  const SizedBox(height: 20),
                  SettingsDangerZoneCard(
                    disabled: _clearingData || _saving || _backingUp || _restoring,
                    clearingData: _clearingData,
                    onClearData: () => _confirmAndClearData(provider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
