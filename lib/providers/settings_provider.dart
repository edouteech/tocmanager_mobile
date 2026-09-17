import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'dart:typed_data';
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
  final bool enableAverageCostPrice;

  const StoreSettings({
    this.name = 'TOC Manager',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.receiptFooter = 'Merci de votre confiance !',
    this.currency = 'FCFA',
    this.enableAverageCostPrice = false,
  });

  StoreSettings copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? receiptFooter,
    String? currency,
    bool? enableAverageCostPrice,
  }) {
    return StoreSettings(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currency: currency ?? this.currency,
      enableAverageCostPrice: enableAverageCostPrice ?? this.enableAverageCostPrice,
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
        enableAverageCostPrice: map['enable_average_cost_price'] == '1',
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
        'enable_average_cost_price': newSettings.enableAverageCostPrice ? '1' : '0',
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

  /// Crée une sauvegarde automatique de secours avant toute opération critique
  /// (ex: vidage des données) dans le répertoire 'backups' et retourne son chemin absolu.
  Future<String?> createSafetyBackup() async {
    try {
      await DatabaseHelper.instance.checkpoint();

      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'tocmanager.db');
      final file = File(path);

      if (!await file.exists()) return null;

      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(appDocDir.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final now = DateTime.now();
      final dateStr =
          '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final backupPath = p.join(backupDir.path, 'tocmanager_auto_backup_$dateStr.db');

      await file.copy(backupPath);
      return backupPath;
    } catch (e) {
      return null;
    }
  }

  /// Vide l'ensemble des données d'activité tout en préservant les paramètres
  Future<void> clearBusinessData() async {
    await DatabaseHelper.instance.clearAllBusinessData();
  }

  Future<String?> exportDatabaseBackup() async {
    try {
      await DatabaseHelper.instance.checkpoint();

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
        withData: true,
      );

      if (result == null || result.files.isEmpty) return false;

      final picked = result.files.single;
      Uint8List? fileBytes = picked.bytes;
      if (fileBytes == null && picked.path != null) {
        final f = File(picked.path!);
        if (await f.exists()) {
          fileBytes = await f.readAsBytes();
        }
      }

      if (fileBytes == null || fileBytes.length < 16) return false;

      // Validation de l'en-tête SQLite standard : "SQLite format 3\000"
      const sqliteHeader = [
        0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66,
        0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00
      ];
      for (var i = 0; i < 16; i++) {
        if (fileBytes[i] != sqliteHeader[i]) {
          return false;
        }
      }

      final dbPath = await getDatabasesPath();
      final targetPath = p.join(dbPath, 'tocmanager.db');

      // 1. Fermeture propre de la base active et libération de l'instance
      await DatabaseHelper.instance.closeDatabase();

      // 2. Nettoyage des journaux WAL et SHM pour éviter toute corruption
      final walFile = File('$targetPath-wal');
      if (await walFile.exists()) {
        try {
          await walFile.delete();
        } catch (_) {}
      }
      final shmFile = File('$targetPath-shm');
      if (await shmFile.exists()) {
        try {
          await shmFile.delete();
        } catch (_) {}
      }

      // 3. Écriture du nouveau fichier SQLite
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(fileBytes);

      // 4. Réouverture de la connexion avec migration automatique si nécessaire
      await DatabaseHelper.instance.database;

      // 5. Rechargement des paramètres
      await loadSettings();
      return true;
    } catch (e) {
      return false;
    }
  }
}
