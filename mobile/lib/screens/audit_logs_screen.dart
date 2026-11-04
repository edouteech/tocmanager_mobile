import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/audit_service.dart';
import '../theme/app_theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<AuditLogItem> _logs = [];
  bool _isLoading = true;
  String _selectedAction = 'ALL';
  String _searchQuery = '';

  final List<Map<String, String>> _actionFilters = [
    {'key': 'ALL', 'label': 'Tous'},
    {'key': 'SALE_CREATE', 'label': 'Ventes'},
    {'key': 'APPROVISIONNEMENT_CREATE', 'label': 'Approvisionnements'},
    {'key': 'DECAISSEMENT_CREATE', 'label': 'Décaissements'},
    {'key': 'USER_CREATE', 'label': 'Création Utilisateur'},
    {'key': 'USER_UPDATE', 'label': 'Modif Utilisateur'},
    {'key': 'USER_DELETE', 'label': 'Suppr Utilisateur'},
    {'key': 'LOGIN', 'label': 'Connexions'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLogs());
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final items = await AuditService.getAuditLogs(
      limit: 100,
      action: _selectedAction,
    );
    if (mounted) {
      setState(() {
        _logs = items;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getActionMeta(String action) {
    switch (action) {
      case 'SALE_CREATE':
        return {
          'label': 'Nouvelle Vente',
          'icon': Icons.shopping_bag_rounded,
          'color': AppColors.success,
          'bgColor': AppColors.successLight,
        };
      case 'APPROVISIONNEMENT_CREATE':
        return {
          'label': 'Entrée Stock',
          'icon': Icons.arrow_downward_rounded,
          'color': AppColors.primary,
          'bgColor': AppColors.primarySurface,
        };
      case 'DECAISSEMENT_CREATE':
        return {
          'label': 'Décaissement',
          'icon': Icons.account_balance_wallet_rounded,
          'color': AppColors.warning,
          'bgColor': AppColors.warningLight,
        };
      case 'USER_CREATE':
        return {
          'label': 'Création Compte',
          'icon': Icons.person_add_alt_1_rounded,
          'color': AppColors.purple,
          'bgColor': AppColors.purpleLight,
        };
      case 'USER_UPDATE':
        return {
          'label': 'Modification Compte',
          'icon': Icons.manage_accounts_rounded,
          'color': AppColors.purple,
          'bgColor': AppColors.purpleLight,
        };
      case 'USER_DELETE':
        return {
          'label': 'Suppression Compte',
          'icon': Icons.person_remove_rounded,
          'color': AppColors.danger,
          'bgColor': AppColors.dangerLight,
        };
      case 'LOGIN':
        return {
          'label': 'Connexion Session',
          'icon': Icons.login_rounded,
          'color': const Color(0xFF3498DB),
          'bgColor': const Color(0xFFEBF5FB),
        };
      case 'PIN_VERIFY':
        return {
          'label': 'Déverrouillage PIN',
          'icon': Icons.lock_open_rounded,
          'color': AppColors.success,
          'bgColor': AppColors.successLight,
        };
      default:
        return {
          'label': action,
          'icon': Icons.info_outline_rounded,
          'color': AppColors.textMedium,
          'bgColor': AppColors.background,
        };
    }
  }

  void _showDetailModal(AuditLogItem item) {
    final meta = _getActionMeta(item.action);
    final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(item.createdAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        child: Column(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: meta['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meta['icon'] as IconData,
                    color: meta['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta['label'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 16),

            // Info rows
            _buildDetailRow('Auteur', item.userName ?? item.userId ?? 'Système'),
            if (item.entityType != null)
              _buildDetailRow('Entité concernée', '${item.entityType} (${item.entityId ?? '-'})'),
            _buildDetailRow('Identifiant d\'audit', item.id),

            const SizedBox(height: 12),
            const Text(
              'Détails techniques :',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    item.details != null
                        ? const JsonEncoder.withIndent('  ').convert(item.details)
                        : 'Aucun détail supplémentaire.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    // RBAC: Seuls l'administrateur et le gérant peuvent voir le journal d'audit
    final isAllowed = user != null && (user.isAdmin || user.isManager);
    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès restreint')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.danger, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Accès Réservé aux Responsables',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La consultation du journal d\'audit nécessite des privilèges d\'administration ou de gestion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredLogs = _logs.where((l) {
      final q = _searchQuery.toLowerCase();
      final matchUser = l.userName?.toLowerCase().contains(q) ?? false;
      final matchAction = l.action.toLowerCase().contains(q);
      final matchEntity = l.entityId?.toLowerCase().contains(q) ?? false;
      return matchUser || matchAction || matchEntity;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Journal d\'Audit'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${filteredLogs.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Rechercher par utilisateur, ticket ou ID...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMedium, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),

          // Action Filters (horizontal chips)
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _actionFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final filter = _actionFilters[idx];
                final isSelected = _selectedAction == filter['key'];
                return ChoiceChip(
                  label: Text(
                    filter['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedAction = filter['key']!);
                      _loadLogs();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_toggle_off_rounded, color: AppColors.textLight, size: 48),
                            const SizedBox(height: 8),
                            const Text(
                              'Aucun événement d\'audit trouvé.',
                              style: TextStyle(color: AppColors.textMedium, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final item = filteredLogs[index];
                          final meta = _getActionMeta(item.action);
                          final timeStr = DateFormat('dd/MM HH:mm').format(item.createdAt);

                          return InkWell(
                            onTap: () => _showDetailModal(item),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: meta['bgColor'] as Color,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      meta['icon'] as IconData,
                                      color: meta['color'] as Color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              meta['label'] as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            Text(
                                              timeStr,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Par : ${item.userName ?? item.userId ?? 'Système'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
