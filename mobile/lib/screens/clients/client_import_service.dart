import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../widgets/app_toast.dart';
import 'client_import_preview_sheet.dart';

Future<void> importClientsFromExcel(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true,
  );
  if (result == null || result.files.single.bytes == null) return;

  try {
    final excel = xl.Excel.decodeBytes(result.files.single.bytes!);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    if (sheet.rows.length < 2) {
      if (context.mounted) AppToast.showError(context, 'Fichier vide ou sans données.');
      return;
    }

    double parseNum(List<xl.Data?> row, int col) {
      if (col < 0 || row.length <= col) return 0;
      final v = row[col]?.value;
      if (v is xl.IntCellValue) return v.value.toDouble();
      if (v is xl.DoubleCellValue) return v.value;
      final s = v?.toString().replaceAll(' ', '').replaceAll(',', '.') ?? '';
      return double.tryParse(s) ?? 0;
    }

    int colName = 0;
    int colPhone = 1;
    int colEmail = -1;
    int colAddress = -1;
    int colBalance = -1;
    int colType = -1;

    if (sheet.rows.isNotEmpty) {
      final header = sheet.rows[0];
      for (var c = 0; c < header.length; c++) {
        final title = header[c]?.value?.toString().toLowerCase().trim() ?? '';
        if (title.contains('nom') || title.contains('client')) {
          colName = c;
        } else if (title.contains('tél') || title.contains('tel') || title.contains('phone') || title.contains('contact')) {
          colPhone = c;
        } else if (title.contains('email') || title.contains('mail')) {
          colEmail = c;
        } else if (title.contains('adresse') || title.contains('ville') || title.contains('lieu')) {
          colAddress = c;
        } else if (title.contains('solde') ||
            title.contains('dette') ||
            title.contains('créance') ||
            title.contains('creance') ||
            title.contains('balance')) {
          colBalance = c;
        } else if (title.contains('type') || title.contains('catégorie')) {
          colType = c;
        }
      }
    }

    final toImport = <Map<String, dynamic>>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final name = (row.length > colName ? row[colName]?.value?.toString() : null)?.trim() ?? '';
      if (name.isEmpty) continue;

      final phone = (colPhone >= 0 && row.length > colPhone) ? row[colPhone]?.value?.toString().trim() : null;
      final email = (colEmail >= 0 && row.length > colEmail) ? row[colEmail]?.value?.toString().trim() : null;
      final address = (colAddress >= 0 && row.length > colAddress) ? row[colAddress]?.value?.toString().trim() : null;
      final balance = colBalance >= 0 ? parseNum(row, colBalance) : 0.0;
      final typeStr = (colType >= 0 && row.length > colType)
          ? (row[colType]?.value?.toString().toLowerCase().trim() ?? 'detail')
          : 'detail';

      String clientType = 'detail';
      if (typeStr.contains('gros') && !typeStr.contains('demi')) {
        clientType = 'gros';
      } else if (typeStr.contains('demi')) {
        clientType = 'demi_gros';
      }

      toImport.add({
        'name': name,
        'phone': phone?.isNotEmpty == true ? phone : null,
        'email': email?.isNotEmpty == true ? email : null,
        'address': address?.isNotEmpty == true ? address : null,
        'balance': balance,
        'clientType': clientType,
      });
    }

    if (toImport.isEmpty) {
      if (context.mounted) AppToast.showError(context, 'Aucun client valide trouvé dans le fichier.');
      return;
    }

    if (!context.mounted) return;
    showClientImportPreviewSheet(context, toImport, _confirmClientsImport);
  } catch (e) {
    if (context.mounted) AppToast.showError(context, 'Erreur de lecture du fichier Excel: $e');
  }
}

Future<void> _confirmClientsImport(BuildContext context, List<Map<String, dynamic>> rows) async {
  final clientProvider = context.read<ClientProvider>();
  final existingNames = {
    for (final c in clientProvider.clients) c.name.toLowerCase().trim()
  };

  int createdCount = 0;
  for (final r in rows) {
    final key = (r['name'] as String).toLowerCase().trim();
    if (existingNames.contains(key)) continue;

    final newClient = Client(
      name: (r['name'] as String).trim(),
      phone: r['phone'] as String?,
      email: r['email'] as String?,
      address: r['address'] as String?,
      balance: (r['balance'] as double?) ?? 0.0,
      clientType: (r['clientType'] as String?) ?? 'detail',
    );

    await clientProvider.addClient(newClient);
    existingNames.add(key);
    createdCount++;
  }

  if (context.mounted) {
    AppToast.showSuccess(
      context,
      createdCount > 0
          ? '$createdCount client${createdCount > 1 ? 's' : ''} importé${createdCount > 1 ? 's' : ''} avec succès.'
          : 'Aucun nouveau client à importer (tous déjà existants).',
    );
  }
}
