import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'user_form_modal.dart';
import 'users/user_card.dart';
import 'users/users_restricted_view.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsers());
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await UserService.instance.getUsers();
      if (mounted) setState(() { _users = list; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDelete(AppUser target) async {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    if (target.id == currentUserId) {
      AppToast.showError(context, 'Vous ne pouvez pas supprimer votre propre compte.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous vraiment supprimer définitivement l\'utilisateur @${target.username} (${target.fullName ?? target.username}) ? Cette action est irréversible.',
          style: const TextStyle(fontSize: 14, color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.instance.deleteUser(target.id);
        if (mounted) {
          AppToast.showSuccess(context, 'Utilisateur supprimé avec succès.');
          _loadUsers();
        }
      } catch (e) {
        if (mounted) AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _toggleStatus(AppUser target) async {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    if (target.id == currentUserId && target.isActive) {
      AppToast.showError(context, 'Vous ne pouvez pas désactiver votre propre compte.');
      return;
    }
    try {
      await UserService.instance.updateUser(target.id, isActive: !target.isActive);
      if (mounted) {
        AppToast.showSuccess(context, target.isActive ? 'Compte désactivé.' : 'Compte réactivé.');
        _loadUsers();
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    if (currentUser == null || !currentUser.isAdmin) {
      return const UsersRestrictedView();
    }

    final filteredUsers = _users.where((u) {
      final q = _searchQuery.toLowerCase();
      return (u.fullName?.toLowerCase().contains(q) ?? false) ||
          u.username.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Utilisateurs & Rôles'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
              child: Text('${_users.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: 'Actualiser', onPressed: _loadUsers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await UserFormModal.show(context);
          if (created != null) _loadUsers();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Nouvel utilisateur', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur, nom ou rôle...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMedium, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.divider)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? _errorState()
                    : filteredUsers.isEmpty
                        ? const Center(child: Text('Aucun utilisateur trouvé.', style: TextStyle(color: AppColors.textMedium, fontSize: 14)))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, idx) {
                              final u = filteredUsers[idx];
                              return UserCard(
                                user: u,
                                isSelf: u.id == currentUser.id,
                                onEdit: () async {
                                  final updated = await UserFormModal.show(context, user: u);
                                  if (updated != null) _loadUsers();
                                },
                                onToggleStatus: () => _toggleStatus(u),
                                onDelete: () => _handleDelete(u),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.textLight, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
