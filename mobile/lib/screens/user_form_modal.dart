import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class UserFormModal extends StatefulWidget {
  final AppUser? user;

  const UserFormModal({super.key, this.user});

  static Future<AppUser?> show(BuildContext context, {AppUser? user}) {
    return showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserFormModal(user: user),
    );
  }

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _pinController;

  late String _selectedRole;
  late bool _isActive;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usernameController = TextEditingController(text: u?.username ?? '');
    _fullNameController = TextEditingController(text: u?.fullName ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _passwordController = TextEditingController();
    _pinController = TextEditingController();

    _selectedRole = u?.role ?? 'cashier';
    _isActive = u?.isActive ?? true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final pinText = _pinController.text.trim();
    if (pinText.isNotEmpty && pinText.length != 4 && pinText.length != 6) {
      AppToast.showError(context, 'Le code PIN doit comporter 4 ou 6 chiffres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        final updatedUser = await UserService.instance.updateUser(
          widget.user!.id,
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
          password: _passwordController.text.trim().isNotEmpty
              ? _passwordController.text.trim()
              : null,
          pin: pinText.isNotEmpty ? pinText : null,
          isActive: _isActive,
        );
        if (mounted) {
          AppToast.showSuccess(context, 'Utilisateur modifié avec succès.');
          Navigator.of(context).pop(updatedUser);
        }
      } else {
        final newUser = await UserService.instance.createUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
          pin: pinText.isNotEmpty ? pinText : null,
        );
        if (mounted) {
          AppToast.showSuccess(context, 'Utilisateur créé avec succès.');
          Navigator.of(context).pop(newUser);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEditing ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      isEditing
                          ? '@${widget.user!.username}'
                          : 'Attribuez des identifiants et un rôle système',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),

          // Form fields
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    if (!isEditing) ...[
                      const Text(
                        'Nom d\'utilisateur *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Ex: caissier2',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Veuillez saisir un nom d\'utilisateur.';
                          }
                          if (val.trim().length < 3) {
                            return 'Minimum 3 caractères.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Full Name
                    const Text(
                      'Nom complet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Awa Diallo',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Email
                    const Text(
                      'Adresse e-mail',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Ex: caisse@tocmanager.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Role Selector
                    const Text(
                      'Rôle Système *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'cashier',
                              child: Row(
                                children: [
                                  Icon(Icons.point_of_sale_rounded, color: AppColors.success, size: 20),
                                  SizedBox(width: 8),
                                  Text('Caissier (Ventes & encaissements)', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'manager',
                              child: Row(
                                children: [
                                  Icon(Icons.supervised_user_circle_rounded, color: AppColors.primary, size: 20),
                                  SizedBox(width: 8),
                                  Text('Gérant (Stocks, rapports & caisse)', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Row(
                                children: [
                                  Icon(Icons.shield_rounded, color: AppColors.purple, size: 20),
                                  SizedBox(width: 8),
                                  Text('Administrateur (Accès total & gestion)', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRole = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    Text(
                      isEditing ? 'Nouveau mot de passe (laisser vide pour ne pas changer)' : 'Mot de passe *',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: isEditing ? '••••••••' : 'Minimum 6 caractères',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textLight,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
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

                    // PIN Code
                    const Text(
                      'Code PIN Caisse (4 ou 6 chiffres)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        hintText: isEditing && widget.user!.hasPin
                            ? 'Code PIN déjà configuré (saisir pour remplacer)'
                            : 'Ex: 1234',
                        prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Active Switch (editing only)
                    if (isEditing) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Statut du compte',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  _isActive ? 'Compte actif et autorisé' : 'Compte suspendu / inactif',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isActive ? AppColors.success : AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isActive,
                              activeColor: AppColors.success,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? 'Enregistrer les modifications' : 'Créer l\'utilisateur',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
