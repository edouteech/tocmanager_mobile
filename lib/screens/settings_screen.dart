import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../providers/product_provider.dart';
import '../providers/client_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/vente_provider.dart';
import '../providers/decaissement_provider.dart';
import '../providers/category_provider.dart';
import '../providers/approvisionnement_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Paramètres du Magasin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
                  _buildSectionCard(
                    title: 'Profil du Magasin',
                    icon: Icons.store_outlined,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom du magasin *',
                          hintText: 'Ex: TOC Market',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Veuillez saisir le nom du magasin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                hintText: '+225 07000000',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _currencyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Devise *',
                                hintText: 'FCFA',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Devise obligatoire';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'contact@magasin.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Adresse physique',
                          hintText: 'Abidjan, Cocody Riviera',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _footerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Message bas de ticket de caisse',
                          hintText: 'Ex: Merci pour votre confiance !',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : () => _saveSettings(provider),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Enregistrer les modifications'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Gestion des Prix & Marges',
                    icon: Icons.calculate_outlined,
                    children: [
                      const Text(
                        'Activez cette option pour que le prix d\'achat d\'un produit soit automatiquement recalculé à chaque approvisionnement, en utilisant la méthode du Prix Unitaire Moyen Pondéré (PUMP).',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _enableAverageCostPrice,
                        onChanged: (val) => setState(() => _enableAverageCostPrice = val),
                        title: const Text(
                          'Calcul automatique du prix moyen d\'achat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: const Text(
                          'Mise à jour du coût à chaque ajout ou modification d\'approvisionnement',
                          style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                        ),
                        activeThumbColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : () => _saveSettings(provider),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Enregistrer les modifications'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Sauvegarde & Restauration',
                    icon: Icons.cloud_sync_outlined,
                    children: [
                      const Text(
                        'Sauvegardez régulièrement vos données (produits, ventes, créances, dépenses) pour éviter toute perte.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _backingUp ? null : () => _backupDb(provider),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: _backingUp
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Exporter Sauvegarde'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _restoring ? null : () => _restoreDb(provider),
                              icon: const Icon(Icons.upload_rounded, size: 18),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning),
                              ),
                              label: _restoring
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Restaurer Sauvegarde'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Zone de Danger',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.danger,
                    titleColor: AppColors.danger,
                    children: [
                      const Text(
                        'Cette action supprime l\'ensemble des produits, stocks, ventes, créances clients, fournisseurs et dépenses. Vos coordonnées et réglages du magasin restent préservés.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_clearingData || _saving || _backingUp || _restoring)
                              ? null
                              : () => _confirmAndClearData(provider),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          label: _clearingData
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.danger,
                                  ),
                                )
                              : const Text(
                                  'Vider les données',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color? iconColor,
    Color? titleColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Restaurer la base de données', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Attention : Cette action va remplacer vos données actuelles par celles du fichier de sauvegarde. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _restoring = true);
    try {
      final success = await provider.restoreDatabaseBackup();
      if (success && mounted) {
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

        if (mounted) {
          AppToast.showSuccess(context, 'Base de données restaurée avec succès !');
        }
      } else if (mounted) {
        AppToast.showError(context, 'Restauration annulée ou fichier invalide.');
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _confirmAndClearData(SettingsProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('Vider les données ?', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir supprimer toutes les données d\'activité ?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              '• Données supprimées : Produits, stocks, ventes, tickets, clients, fournisseurs, approvisionnements, dépenses.\n\n'
              '• Données conservées : Coordonnées, devise et réglages du magasin.\n\n'
              'Une sauvegarde automatique de secours sera créée avant la suppression afin de prévenir toute perte involontaire.',
              style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _clearingData = true);
    try {
      // 1. Sauvegarde automatique préalable de secours
      final backupPath = await provider.createSafetyBackup();

      // 2. Vidage effectif des données d'activité
      await provider.clearBusinessData();

      // 3. Rechargement immédiat de l'ensemble des providers
      if (mounted) {
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

      if (mounted) {
        // Dialogue d'information affichant l'emplacement exact de la sauvegarde
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                SizedBox(width: 8),
                Text('Données vidées', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toutes les données d\'activité ont été réinitialisées avec succès. Vos réglages de magasin ont été conservés.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                if (backupPath != null) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Une sauvegarde automatique de secours a été créée avant la suppression à l\'emplacement suivant :',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: SelectableText(
                      backupPath,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (backupPath != null)
                TextButton.icon(
                  onPressed: () {
                    Share.shareXFiles(
                      [XFile(backupPath)],
                      text: 'Sauvegarde de secours TOC Manager',
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Partager la sauvegarde'),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Erreur lors du vidage des données: $e');
      }
    } finally {
      if (mounted) setState(() => _clearingData = false);
    }
  }
}
