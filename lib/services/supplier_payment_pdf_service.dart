import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/supplier.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class SupplierPaymentPdfService {
  static Future<Uint8List> generateReceiptBytes({
    required Supplier supplier,
    required double amountPaid,
    required String paymentMethod,
    required double remainingDebt,
    required StoreSettings settings,
  }) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final now = DateTime.now();

    final rollFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Store Header
              pw.Text(
                settings.name.toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),
              if (settings.phone.isNotEmpty)
                pw.Text('Tél: ${settings.phone}', style: const pw.TextStyle(fontSize: 9)),
              if (settings.address.isNotEmpty)
                pw.Text(settings.address, style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),

              pw.Divider(thickness: 0.5),
              pw.Text(
                'REÇU DE RÈGLEMENT FOURNISSEUR',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'N° REG-${now.millisecondsSinceEpoch.toString().substring(6)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text('Date : ${dateFormat.format(now)}', style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(thickness: 0.5),

              pw.SizedBox(height: 4),
              // Supplier Info
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FOURNISSEUR : ${supplier.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    if (supplier.phone != null && supplier.phone!.isNotEmpty)
                      pw.Text('Tél : ${supplier.phone}', style: const pw.TextStyle(fontSize: 8)),
                    if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty)
                      pw.Text('Contact : ${supplier.contactPerson}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Payment details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Mode de paiement :', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(paymentMethod, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MONTANT RÉGLÉ :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(formatter.format(amountPaid), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Solde restant dû :', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(formatter.format(remainingDebt), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5),
              pw.Text('Merci pour votre collaboration !', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8)),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf.save();
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

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Reglement_Fournisseur_${supplier.id}.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Reçu de règlement fournisseur - ${supplier.name}',
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

    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        downloadsDir = await getExternalStorageDirectory();
      }
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${downloadsDir!.path}/Reglement_${supplier.name.replaceAll(' ', '_')}_$timestamp.pdf');
    await file.writeAsBytes(pdfBytes);

    if (context.mounted) {
      AppToast.showSuccess(context, 'Reçu téléchargé : ${file.path.split('/').last}');
    }
  }
}
