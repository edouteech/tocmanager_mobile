import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'user_form_fields.dart';

class UserFormCredentialsSection extends StatelessWidget {
  final bool isEditing;
  final bool hasExistingPin;
  final TextEditingController passwordController;
  final TextEditingController pinController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  const UserFormCredentialsSection({
    super.key,
    required this.isEditing,
    required this.hasExistingPin,
    required this.passwordController,
    required this.pinController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.isActive,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildUserFieldLabel(
          isEditing ? 'Nouveau mot de passe (laisser vide pour ne pas changer)' : 'Mot de passe *',
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: buildUserFormInputDecoration(
            hintText: isEditing ? '••••••••' : 'Minimum 6 caractères',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textLight,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          validator: (val) {
            if (!isEditing && (val == null || val.trim().isEmpty)) {
              return 'Veuillez saisir un mot de passe.';
            }
            if (val != null && val.trim().isNotEmpty && val.trim().length < 6) {
              return 'Le mot de passe doit comporter au moins 6 caractères.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        buildUserFieldLabel('Code PIN Caisse (4 ou 6 chiffres)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: pinController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: buildUserFormInputDecoration(
            hintText: isEditing && hasExistingPin
                ? 'Code PIN déjà configuré (saisir pour remplacer)'
                : 'Ex: 1234',
            prefixIcon: Icons.pin_outlined,
          ),
        ),
        const SizedBox(height: 14),
        if (isEditing) ...[
          UserStatusSwitchTile(
            isActive: isActive,
            onChanged: onActiveChanged,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
