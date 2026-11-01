import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/client.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class ClientPaymentPdfService {
  static Future<Uint8List> generateReceiptPdf({
    required Client client,
    required double amountPaid,
    required String paymentMethod,
    required double previousBalance,
    required StoreSettings storeSettings,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: storeSettings.currency, decimalDigits: 0);
    final receiptNumber = 'REC-${DateFormat('yyyyMMdd-HHmmss').format(now)}';
    final newBalance = (previousBalance - amountPaid) < 0 ? 0.0 : (previousBalance - amountPaid);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      storeSettings.name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (storeSettings.address.isNotEmpty)
                      pw.Text(
                        storeSettings.address,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    if (storeSettings.phone.isNotEmpty)
                      pw.Text(
                        'Tél : ${storeSettings.phone}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    if (storeSettings.email.isNotEmpty)
                      pw.Text(
                        storeSettings.email,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              // Title
              pw.Center(
                child: pw.Text(
                  'REÇU DE VERSEMENT',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 6),

              // Receipt Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('N° : $receiptNumber', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateFormat.format(now), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text('Client : ${client.name}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              if (client.phone != null && client.phone!.isNotEmpty)
                pw.Text('Tél client : ${client.phone}', style: const pw.TextStyle(fontSize: 8)),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 6),

              // Payment details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Montant Versé :', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatter.format(amountPaid), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Mode de Règlement :', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(paymentMethod, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ancienne Dette :', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(formatter.format(previousBalance), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nouveau Solde Reste Dû :', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatter.format(newBalance), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 6),

              pw.Center(
                child: pw.Text(
                  'Merci pour votre règlement !',
                  style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> sharePaymentReceipt(
    BuildContext context, {
    required Client client,
    required double amountPaid,
    required String paymentMethod,
    required double previousBalance,
    required StoreSettings storeSettings,
  }) async {
    try {
      final pdfBytes = await generateReceiptPdf(
        client: client,
        amountPaid: amountPaid,
        paymentMethod: paymentMethod,
        previousBalance: previousBalance,
        storeSettings: storeSettings,
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = 'recu_versement_${client.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reçu de versement de ${client.name}',
      );
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur lors du partage du reçu : $e');
      }
    }
  }

  static Future<void> downloadPaymentReceipt(
    BuildContext context, {
    required Client client,
    required double amountPaid,
    required String paymentMethod,
    required double previousBalance,
    required StoreSettings storeSettings,
  }) async {
    try {
      final pdfBytes = await generateReceiptPdf(
        client: client,
        amountPaid: amountPaid,
        paymentMethod: paymentMethod,
        previousBalance: previousBalance,
        storeSettings: storeSettings,
      );

      Directory targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          targetDir = await getApplicationDocumentsDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final fileName = 'Recu_Versement_${client.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = p.join(targetDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Reçu téléchargé dans : ${file.path}');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur lors du téléchargement : $e');
      }
    }
  }
}
