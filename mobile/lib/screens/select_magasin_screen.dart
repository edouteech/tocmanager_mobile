import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'reports_screen.dart';

class SelectMagasinScreen extends StatefulWidget {
  final AppUser user;

  const SelectMagasinScreen({super.key, required this.user});

  @override
  State<SelectMagasinScreen> createState() => _SelectMagasinScreenState();
}

class _SelectMagasinScreenState extends State<SelectMagasinScreen> {
  // Liste des magasins simulés ou synchronisés localement
  List<Map<String, dynamic>> _magasins = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMagasins();
  }

  void _loadMagasins() {
    setState(() {
      _isLoading = true;
    });

    // Exemple de magasins de la boutique
    _magasins = [
      {
        'id': 'mag-01',
        'name': 'Magasin Principal / Caisse Centrale',
        'address': 'Plateau, Centre-Ville',
        'is_warehouse': false,
      },
      {
        'id': 'mag-02',
        'name': 'Succursale Almadies',
        'address': 'Route des Almadies',
        'is_warehouse': false,
      },
      {
        'id': 'mag-03',
        'name': 'Entrepôt Central Réserve',
        'address': 'Zone Industrielle',
        'is_warehouse': true,
      },
    ];

    // Si l'utilisateur n'est pas propriétaire et a des magasins assignés, filtrer
    if (!widget.user.isOwner && widget.user.assignedMagasinIds.isNotEmpty) {
      _magasins = _magasins
          .where((m) => widget.user.assignedMagasinIds.contains(m['id']))
          .toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onSelectMagasin(Map<String, dynamic> magasin) {
    // Naviguer vers la caisse principale avec ce magasin
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  void _onSkipToConsolidatedFinancial() {
    // Bouton "Passer" exclusif pour le propriétaire -> accès direct aux états financiers
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ReportsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.user.isOwner;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Choix du Point de Vente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Le bouton "Passer" pour le propriétaire
          if (isOwner)
            TextButton.icon(
              onPressed: _onSkipToConsolidatedFinancial,
              icon: const Icon(Icons.skip_next_rounded, color: AppColors.primary),
              label: const Text(
                'Passer',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOwner ? 'Vue Propriétaire' : 'Session Collaborateur',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            isOwner
                              ? 'Sélectionnez une caisse ou cliquez sur « Passer » pour voir les finances consolidées.'
                              : 'Veuillez sélectionner le point de vente actif pour ce terminal.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'MAGASINS DISPONIBLES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),

              // Magasins List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: _magasins.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final m = _magasins[idx];
                          final isWarehouse = m['is_warehouse'] == true;

                          return InkWell(
                            onTap: () => _onSelectMagasin(m),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isWarehouse ? Colors.purple.shade50 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isWarehouse ? Icons.warehouse_rounded : Icons.point_of_sale_rounded,
                                      color: isWarehouse ? Colors.purple : Colors.blue,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          m['address'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Action Passer en bas si propriétaire
              if (isOwner)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _onSkipToConsolidatedFinancial,
                    icon: const Icon(Icons.trending_up_rounded, color: AppColors.primary),
                    label: const Text(
                      'Passer à la Vue Financière Consolidée',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
