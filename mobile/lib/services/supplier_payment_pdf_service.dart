import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../providers/settings_provider.dart';
import 'export_helper.dart';

class SupplierPaymentPdfService {
  static Future<Uint8List> generateReceiptBytes({
    required Supplier supplier,
    required double amountPaid,
    required String paymentMethod,
    required double remainingDebt,
    required StoreSettings settings,
  }) {
    final epochStr = DateTime.now().millisecondsSinceEpoch.toString();
    final regNum = epochStr.length > 6 ? epochStr.substring(6) : epochStr;
    return ExportHelper.buildPaymentReceiptPdf(
      title: 'REÇU DE RÈGLEMENT FOURNISSEUR',
      receiptNumber: 'REG-$regNum',
      partyLabel: 'FOURNISSEUR',
      partyName: supplier.name,
      partyPhone: supplier.phone,
      partyContact: supplier.contactPerson,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      remainingBalance: remainingDebt,
      remainingLabel: 'Solde restant dû :',
      footerText: 'Merci pour votre collaboration !',
      storeSettings: settings,
    );
  }

  static Future<void> shareReceipt({
    required BuildContext context,
    required Supplier supplier,
    required double amountPaid,
    required String paymentMethod,
    required double remainingDebt,
    required StoreSettings settings,
  }) async {
    final pdfBytes = await generateReceiptBytes(
      supplier: supplier,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      remainingDebt: remainingDebt,
      settings: settings,
    );
    if (!context.mounted) return;
    await ExportHelper.shareBytesAsFile(
      context,
      bytes: pdfBytes,
      fileName: 'Reglement_Fournisseur_${supplier.id}.pdf',
      shareText: 'Reçu de règlement fournisseur - ${supplier.name}',
    );
  }

  static Future<void> downloadReceipt({
    required BuildContext context,
    required Supplier supplier,
    required double amountPaid,
    required String paymentMethod,
    required double remainingDebt,
    required StoreSettings settings,
  }) async {
    final pdfBytes = await generateReceiptBytes(
      supplier: supplier,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      remainingDebt: remainingDebt,
      settings: settings,
    );
    if (!context.mounted) return;
    final safeName = supplier.name.replaceAll(' ', '_');
    await ExportHelper.downloadBytes(
      context,
      bytes: pdfBytes,
      fileName: 'Reglement_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      successPrefix: 'Reçu téléchargé : ',
      showBasenameOnly: true,
    );
  }
}
