import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../providers/settings_provider.dart';
import 'export_helper.dart';

class ClientPaymentPdfService {
  static Future<Uint8List> generateReceiptPdf({
    required Client client,
    required double amountPaid,
    required String paymentMethod,
    required double previousBalance,
    required StoreSettings storeSettings,
  }) {
    final now = DateTime.now();
    final newBalance = (previousBalance - amountPaid) < 0 ? 0.0 : (previousBalance - amountPaid);
    return ExportHelper.buildPaymentReceiptPdf(
      title: 'REÇU DE VERSEMENT',
      receiptNumber: 'REC-${DateFormat('yyyyMMdd-HHmmss').format(now)}',
      partyLabel: 'Client',
      partyName: client.name,
      partyPhone: client.phone,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      previousBalance: previousBalance,
      remainingBalance: newBalance,
      remainingLabel: 'Nouveau Solde Reste Dû :',
      footerText: 'Merci pour votre règlement !',
      storeSettings: storeSettings,
    );
  }

  static Future<void> sharePaymentReceipt(
    BuildContext context, {
    required Client client,
    required double amountPaid,
    required String paymentMethod,
    required double previousBalance,
    required StoreSettings storeSettings,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      client: client,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      previousBalance: previousBalance,
      storeSettings: storeSettings,
    );
    if (!context.mounted) return;
    final safeName = client.name.replaceAll(' ', '_');
    await ExportHelper.shareBytesAsFile(
      context,
      bytes: pdfBytes,
      fileName: 'recu_versement_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      shareText: 'Reçu de versement de ${client.name}',
      errorPrefix: 'Erreur lors du partage du reçu : ',
    );
  }

  static Future<void> downloadPaymentReceipt(
    BuildContext context, {
    required Client client,
    required double amountPaid,
    required String paymentMethod,
    required double previousBalance,
    required StoreSettings storeSettings,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      client: client,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      previousBalance: previousBalance,
      storeSettings: storeSettings,
    );
    if (!context.mounted) return;
    final safeName = client.name.replaceAll(' ', '_');
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    await ExportHelper.downloadBytes(
      context,
      bytes: pdfBytes,
      fileName: 'Recu_Versement_${safeName}_$stamp.pdf',
      successPrefix: 'Reçu téléchargé dans : ',
    );
  }
}
