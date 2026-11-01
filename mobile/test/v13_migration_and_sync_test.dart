import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tocmanager/database/database_helper.dart';
import 'package:tocmanager/models/vente.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Migration SQLite v13/v14 & Traçabilité des Utilisateurs', () {
    test('La migration crée sync_queue, audit_logs et ajoute user_id sans altérer l\'existant', () async {
      final db = await DatabaseHelper.instance.database;

      // 1. Vérifier la présence des tables sync_queue et audit_logs
      final queueTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_queue'",
      );
      expect(queueTable, isNotEmpty);

      final auditTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='audit_logs'",
      );
      expect(auditTable, isNotEmpty);

      // 2. Vérifier les colonnes de traçabilité sur la table des ventes
      final cols = await db.rawQuery('PRAGMA table_info(ventes)');
      final colNames = cols.map((c) => c['name']).toList();
      expect(colNames.contains('sync_id'), isTrue);
      expect(colNames.contains('sync_status'), isTrue);
      expect(colNames.contains('user_id'), isTrue);
      expect(colNames.contains('user_name'), isTrue);
    });

    test('L\'insertion d\'une vente alimente la table locale et sync_queue en tâche de fond', () async {
      final now = DateTime.now();
      final testVente = Vente(
        ticketNumber: 'VNT-TEST-PROD-001',
        clientName: 'Client Production Test',
        totalAmount: 12500,
        paidAmount: 12500,
        paymentMethod: 'Espèces',
        date: now,
      );

      final venteId = await DatabaseHelper.instance.insertVente(testVente);
      expect(venteId, isPositive);

      final db = await DatabaseHelper.instance.database;
      final insertedRows = await db.query('ventes', where: 'id = ?', whereArgs: [venteId]);
      expect(insertedRows, isNotEmpty);

      final syncId = insertedRows.first['sync_id'] as String?;
      expect(syncId, isNotNull);
      expect(syncId!.length, greaterThan(10));
      expect(insertedRows.first['sync_status'], equals('pending_insert'));

      // Vérifier que la vente est bien dans sync_queue
      final queueRows = await db.query(
        'sync_queue',
        where: 'entity_uuid = ?',
        whereArgs: [syncId],
      );
      expect(queueRows, isNotEmpty);
      expect(queueRows.first['entity_type'], equals('vente'));
    });
  });
}
