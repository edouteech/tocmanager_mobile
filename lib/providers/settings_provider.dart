import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

class StoreSettings {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String receiptFooter;
  final String currency;

  const StoreSettings({
    this.name = 'TOC Manager',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.receiptFooter = 'Merci de votre confiance !',
    this.currency = 'FCFA',
  });

  StoreSettings copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? receiptFooter,
    String? currency,
  }) {
    return StoreSettings(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currency: currency ?? this.currency,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  StoreSettings _settings = const StoreSettings();
  bool _loading = false;

  StoreSettings get settings => _settings;
  bool get loading => _loading;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _loading = true;
    notifyListeners();
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');

      final rows = await db.query('settings');
      final map = <String, String>{};
      for (final r in rows) {
        map[r['key'] as String] = (r['value'] as String?) ?? '';
      }

      _settings = StoreSettings(
        name: map['store_name']?.isNotEmpty == true ? map['store_name']! : 'TOC Manager',
        phone: map['store_phone'] ?? '',
        email: map['store_email'] ?? '',
        address: map['store_address'] ?? '',
        receiptFooter: map['store_footer']?.isNotEmpty == true ? map['store_footer']! : 'Merci de votre confiance !',
        currency: map['store_currency']?.isNotEmpty == true ? map['store_currency']! : 'FCFA',
      );
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(StoreSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');

      final entries = {
        'store_name': newSettings.name,
        'store_phone': newSettings.phone,
        'store_email': newSettings.email,
        'store_address': newSettings.address,
        'store_footer': newSettings.receiptFooter,
        'store_currency': newSettings.currency,
      };

      for (final e in entries.entries) {
        await db.insert(
          'settings',
          {'key': e.key, 'value': e.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}
  }

  Future<String?> exportDatabaseBackup() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'tocmanager.db');
      final file = File(path);

      if (!await file.exists()) return null;

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final backupPath = p.join(tempDir.path, 'tocmanager_backup_$dateStr.db');

      await file.copy(backupPath);

      await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'Sauvegarde de la base de données TOC Manager ($dateStr)',
      );

      return backupPath;
    } catch (e) {
      return null;
    }
  }

  Future<bool> restoreDatabaseBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return false;

      final selectedPath = result.files.single.path!;
      final selectedFile = File(selectedPath);

      if (!await selectedFile.exists()) return false;

      final dbPath = await getDatabasesPath();
      final targetPath = p.join(dbPath, 'tocmanager.db');

      // Close current db connection if open
      final db = await DatabaseHelper.instance.database;
      if (db.isOpen) {
        await db.close();
      }

      await selectedFile.copy(targetPath);

      // Re-open fresh database connection
      await DatabaseHelper.instance.database;

      // Reload settings & notify
      await loadSettings();
      return true;
    } catch (e) {
      return false;
    }
  }
}
