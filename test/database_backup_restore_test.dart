import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tocmanager/providers/settings_provider.dart';

void main() {
  group('Tests Intégrité Sauvegarde & Restauration', () {
    test('Validation de l\'en-tête SQLite valide (SQLite format 3)', () {
      const sqliteHeader = [
        0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66,
        0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00
      ];
      final validBytes = Uint8List.fromList([...sqliteHeader, 0x01, 0x02, 0x03]);

      bool isValidSqlite(Uint8List bytes) {
        if (bytes.length < 16) return false;
        for (var i = 0; i < 16; i++) {
          if (bytes[i] != sqliteHeader[i]) return false;
        }
        return true;
      }

      expect(isValidSqlite(validBytes), isTrue);

      final invalidBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      expect(isValidSqlite(invalidBytes), isFalse);

      final corruptedBytes = Uint8List.fromList([
        0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x58, // mauvais octet
        0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00
      ]);
      expect(isValidSqlite(corruptedBytes), isFalse);
    });

    test('StoreSettings préserve ses valeurs et modifications', () {
      const initial = StoreSettings(
        name: 'Mon Magasin Test',
        currency: 'FCFA',
        phone: '+225 01020304',
        enableAverageCostPrice: true,
      );

      expect(initial.name, 'Mon Magasin Test');
      expect(initial.currency, 'FCFA');
      expect(initial.enableAverageCostPrice, isTrue);

      final updated = initial.copyWith(name: 'Nouveau Nom');
      expect(updated.name, 'Nouveau Nom');
      expect(updated.currency, 'FCFA');
      expect(updated.phone, '+225 01020304');
      expect(updated.enableAverageCostPrice, isTrue);
    });
  });
}
