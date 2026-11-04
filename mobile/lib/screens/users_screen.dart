import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'user_form_modal.dart';

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
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
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
        if (mounted) {
          AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
        }
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
      await UserService.instance.updateUser(
        target.id,
        isActive: !target.isActive,
      );
      if (mounted) {
        AppToast.showSuccess(
          context,
          target.isActive ? 'Compte désactivé.' : 'Compte réactivé.',
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;

    // Protection d'accès stricte : seul l'administrateur peut voir cet écran
    if (currentUser == null || !currentUser.isAdmin) {
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

    final filteredUsers = _users.where((u) {
      final q = _searchQuery.toLowerCase();
      final matchName = u.fullName?.toLowerCase().contains(q) ?? false;
      final matchUsername = u.username.toLowerCase().contains(q);
      final matchRole = u.role.toLowerCase().contains(q);
      return matchName || matchUsername || matchRole;
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
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_users.length}',
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
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await UserFormModal.show(context);
          if (created != null) {
            _loadUsers();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Nouvel utilisateur', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search Bar
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

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded, color: AppColors.textLight, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                              ),
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
                      )
                    : filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun utilisateur trouvé.',
                              style: TextStyle(color: AppColors.textMedium, fontSize: 14),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final u = filteredUsers[index];
                              final isSelf = u.id == currentUser.id;

                              Color roleColor;
                              String roleLabel;
                              if (u.isAdmin) {
                                roleColor = AppColors.purple;
                                roleLabel = 'Administrateur';
                              } else if (u.isManager) {
                                roleColor = AppColors.primary;
                                roleLabel = 'Gérant';
                              } else {
                                roleColor = AppColors.success;
                                roleLabel = 'Caissier';
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: roleColor.withAlpha(30),
                                      child: Text(
                                        (u.fullName?.isNotEmpty == true
                                                ? u.fullName![0]
                                                : u.username[0])
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: roleColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // User details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  u.fullName ?? u.username,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppColors.textDark,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelf) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primarySurface,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Vous',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '@${u.username}${u.email != null ? ' • ${u.email}' : ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMedium,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Badges row
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              // Role Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: roleColor.withAlpha(25),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: roleColor.withAlpha(60)),
                                                ),
                                                child: Text(
                                                  roleLabel,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: roleColor,
                                                  ),
                                                ),
                                              ),

                                              // PIN Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: u.hasPin
                                                      ? AppColors.successLight
                                                      : AppColors.background,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      u.hasPin ? Icons.lock_rounded : Icons.lock_open_rounded,
                                                      size: 12,
                                                      color: u.hasPin ? AppColors.success : AppColors.textLight,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      u.hasPin ? 'PIN Actif' : 'Sans PIN',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: u.hasPin ? AppColors.success : AppColors.textLight,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Active status
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: u.isActive
                                                      ? AppColors.successLight
                                                      : AppColors.dangerLight,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  u.isActive ? 'Actif' : 'Inactif',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: u.isActive ? AppColors.success : AppColors.danger,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Popup Menu Actions
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: AppColors.textMedium),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      onSelected: (action) async {
                                        if (action == 'edit') {
                                          final updated = await UserFormModal.show(context, user: u);
                                          if (updated != null) _loadUsers();
                                        } else if (action == 'toggle_status') {
                                          _toggleStatus(u);
                                        } else if (action == 'delete') {
                                          _handleDelete(u);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                              SizedBox(width: 8),
                                              Text('Modifier le compte', style: TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'toggle_status',
                                          child: Row(
                                            children: [
                                              Icon(
                                                u.isActive ? Icons.block_flipped : Icons.check_circle_outline,
                                                size: 18,
                                                color: u.isActive ? AppColors.warning : AppColors.success,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                u.isActive ? 'Désactiver' : 'Réactiver',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isSelf)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                                SizedBox(width: 8),
                                                Text('Supprimer', style: TextStyle(fontSize: 13, color: AppColors.danger)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
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
