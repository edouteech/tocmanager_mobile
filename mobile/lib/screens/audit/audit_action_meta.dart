import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const List<Map<String, String>> kAuditActionFilters = [
  {'key': 'ALL', 'label': 'Tous'},
  {'key': 'SALE_CREATE', 'label': 'Ventes'},
  {'key': 'SALE_REFUND', 'label': 'Remboursements'},
  {'key': 'STOCK_SUPPLY', 'label': 'Approvisionnements'},
  {'key': 'EXPENSE_CREATE', 'label': 'Décaissements'},
  {'key': 'DEBT_PAYMENT', 'label': 'Règlements'},
  {'key': 'USER_CREATE', 'label': 'Création Utilisateur'},
  {'key': 'USER_UPDATE', 'label': 'Modif Utilisateur'},
  {'key': 'USER_DELETE', 'label': 'Suppr Utilisateur'},
  {'key': 'LOGIN', 'label': 'Connexions'},
  {'key': 'PIN_UNLOCK', 'label': 'Code PIN'},
];

Map<String, dynamic> getAuditActionMeta(String action) {
  switch (action) {
    case 'SALE_CREATE':
      return {
        'label': 'Nouvelle Vente',
        'icon': Icons.shopping_bag_rounded,
        'color': AppColors.success,
        'bgColor': AppColors.successLight,
      };
    case 'SALE_REFUND':
      return {
        'label': 'Remboursement',
        'icon': Icons.assignment_return_rounded,
        'color': AppColors.danger,
        'bgColor': AppColors.dangerLight,
      };
    case 'STOCK_SUPPLY':
    case 'APPROVISIONNEMENT_CREATE':
      return {
        'label': 'Entrée Stock',
        'icon': Icons.arrow_downward_rounded,
        'color': AppColors.primary,
        'bgColor': AppColors.primarySurface,
      };
    case 'EXPENSE_CREATE':
    case 'DECAISSEMENT_CREATE':
      return {
        'label': 'Décaissement',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.warning,
        'bgColor': AppColors.warningLight,
      };
    case 'DEBT_PAYMENT':
      return {
        'label': 'Règlement Dette',
        'icon': Icons.payments_rounded,
        'color': AppColors.success,
        'bgColor': AppColors.successLight,
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
    case 'PIN_UNLOCK':
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
