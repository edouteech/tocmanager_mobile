import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/tenant_provider.dart';
import '../services/user_service.dart';
import '../widgets/app_toast.dart';
import 'users/user_form_credentials.dart';
import 'users/user_form_fields.dart';
import 'users/user_form_header.dart';
import 'users/user_form_role_section.dart';

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
  late Set<String> _selectedMagasinIds;
  late bool _isActive;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get isEditing => widget.user != null;

  static String _normalizeRole(String? raw) {
    final lower = (raw ?? 'cashier').toLowerCase();
    if (lower == 'admin' || lower == 'owner' || lower == 'merchant') {
      return 'store_admin';
    }
    if (const {'cashier', 'manager', 'store_admin'}.contains(lower)) {
      return lower;
    }
    return 'cashier';
  }

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usernameController = TextEditingController(text: u?.username ?? '');
    _fullNameController = TextEditingController(text: u?.fullName ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _passwordController = TextEditingController();
    _pinController = TextEditingController();

    _selectedRole = _normalizeRole(u?.role);
    _selectedMagasinIds = Set<String>.from(u?.assignedMagasinIds ?? const <String>[]);
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

    final assignedIds = _selectedRole == 'store_admin'
        ? const <String>[]
        : _selectedMagasinIds.toList();

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
          assignedMagasinIds: assignedIds,
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
          assignedMagasinIds: assignedIds,
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
    final allMagasins = context.watch<TenantProvider>().allBoutiqueMagasins;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomInset + 20),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserFormHeader(
            isEditing: isEditing,
            username: widget.user?.username,
            onClose: () => Navigator.of(context).pop(),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditing) ...[
                      buildUserFieldLabel('Nom d\'utilisateur *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameController,
                        decoration: buildUserFormInputDecoration(
                          hintText: 'Ex: caissier2',
                          prefixIcon: Icons.alternate_email_rounded,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Veuillez saisir un nom d\'utilisateur.';
                          }
                          if (val.trim().length < 3) return 'Minimum 3 caractères.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    buildUserFieldLabel('Nom complet'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: buildUserFormInputDecoration(
                        hintText: 'Ex: Awa Diallo',
                        prefixIcon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    buildUserFieldLabel('Adresse e-mail'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: buildUserFormInputDecoration(
                        hintText: 'Ex: caisse@tocmanager.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    UserFormRoleAndMagasinsSection(
                      selectedRole: _selectedRole,
                      allMagasins: allMagasins,
                      selectedMagasinIds: _selectedMagasinIds,
                      onRoleChanged: (val) => setState(() => _selectedRole = val),
                      onToggleMagasin: (id, checked) {
                        setState(() {
                          if (checked) {
                            _selectedMagasinIds.add(id);
                          } else {
                            _selectedMagasinIds.remove(id);
                          }
                        });
                      },
                    ),
                    UserFormCredentialsSection(
                      isEditing: isEditing,
                      hasExistingPin: widget.user?.hasPin ?? false,
                      passwordController: _passwordController,
                      pinController: _pinController,
                      obscurePassword: _obscurePassword,
                      onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      isActive: _isActive,
                      onActiveChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          UserSubmitButton(isLoading: _isLoading, isEditing: isEditing, onPressed: _handleSubmit),
        ],
      ),
    );
  }
}
