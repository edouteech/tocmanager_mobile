import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'settings_section_card.dart';

class SettingsStoreProfileSection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController currencyCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController footerCtrl;
  final bool saving;
  final VoidCallback onSave;

  const SettingsStoreProfileSection({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.currencyCtrl,
    required this.emailCtrl,
    required this.addressCtrl,
    required this.footerCtrl,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Profil du Magasin',
      icon: Icons.store_outlined,
      children: [
        TextFormField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Nom du magasin *', hintText: 'Ex: TOC Market'),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Veuillez saisir le nom du magasin';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone', hintText: '+225 07000000'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: currencyCtrl,
                decoration: const InputDecoration(labelText: 'Devise *', hintText: 'FCFA'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Devise obligatoire';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', hintText: 'contact@magasin.com'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: addressCtrl,
          decoration: const InputDecoration(labelText: 'Adresse physique', hintText: 'Abidjan, Cocody Riviera'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: footerCtrl,
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
            onPressed: saving ? null : onSave,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Enregistrer les modifications'),
          ),
        ),
      ],
    );
  }
}

class SettingsPricingSection extends StatelessWidget {
  final bool enableAverageCostPrice;
  final ValueChanged<bool> onToggleAverageCost;
  final bool saving;
  final VoidCallback onSave;

  const SettingsPricingSection({
    super.key,
    required this.enableAverageCostPrice,
    required this.onToggleAverageCost,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Gestion des Prix & Marges',
      icon: Icons.calculate_outlined,
      children: [
        const Text(
          'Activez cette option pour que le prix d\'achat d\'un produit soit automatiquement recalculé à chaque approvisionnement, en utilisant la méthode du Prix Unitaire Moyen Pondéré (PUMP).',
          style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: enableAverageCostPrice,
          onChanged: onToggleAverageCost,
          title: const Text(
            'Calcul automatique du prix moyen d\'achat',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
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
            onPressed: saving ? null : onSave,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Enregistrer les modifications'),
          ),
        ),
      ],
    );
  }
}
