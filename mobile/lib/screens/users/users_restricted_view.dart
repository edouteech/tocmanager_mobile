import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class UsersRestrictedView extends StatelessWidget {
  const UsersRestrictedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accès restreint')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad_rounded, color: AppColors.danger, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Accès Réservé à l\'Administrateur',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous devez disposer du rôle Administrateur pour gérer les comptes utilisateurs et les codes PIN.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMedium),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
