import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/vente.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class TicketPdfService {
  static Future<Uint8List> generateTicketBytes(
    Vente vente,
    StoreSettings storeSettings,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: storeSettings.currency, decimalDigits: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      storeSettings.name.toUpperCase(),
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    if (storeSettings.address.isNotEmpty)
                      pw.Text(storeSettings.address, style: const pw.TextStyle(fontSize: 8)),
                    if (storeSettings.phone.isNotEmpty)
                      pw.Text('Tél : ${storeSettings.phone}', style: const pw.TextStyle(fontSize: 8)),
                    if (storeSettings.email.isNotEmpty)
                      pw.Text(storeSettings.email, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ticket : ${vente.ticketNumber}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateFormat.format(vente.date), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (vente.clientName != null && vente.clientName!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text('Client : ${vente.clientName}', style: const pw.TextStyle(fontSize: 8)),
              ],
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Désignation', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('Qté', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.2),
              pw.SizedBox(height: 4),

              ...vente.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          formatter.format(item.total),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              if (vente.discountAmount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sous-total brut :', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(formatter.format(vente.subtotalAmount), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Remise / Réduction :', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('- ${formatter.format(vente.discountAmount)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 2),
              ],

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL NET', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    formatter.format(vente.totalAmount),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Mode de Paiement :', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(vente.paymentMethod, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Montant Versé :', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(formatter.format(vente.paidAmount), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (vente.paidAmount > vente.totalAmount) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Monnaie Rendue :', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(formatter.format(vente.paidAmount - vente.totalAmount), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
              if (vente.isCredit) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Reste à payer (Crédit) :', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text(formatter.format(vente.remainingAmount), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  storeSettings.receiptFooter,
                  style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> shareTicketPdf(
    BuildContext context,
    Vente vente,
    StoreSettings storeSettings,
  ) async {
    try {
      final bytes = await generateTicketBytes(vente, storeSettings);
      final tempDir = await getTemporaryDirectory();
      final ticketName = vente.ticketNumber.isNotEmpty ? vente.ticketNumber : 'Ticket_${vente.id}';
      final file = File(p.join(tempDir.path, 'ticket_${ticketName.replaceAll('/', '_')}.pdf'));
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ticket de caisse ${vente.ticketNumber} — ${storeSettings.name}',
      );
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur lors du partage du ticket : $e');
      }
    }
  }

  static Future<void> downloadTicketPdf(
    BuildContext context,
    Vente vente,
    StoreSettings storeSettings,
  ) async {
    try {
      final bytes = await generateTicketBytes(vente, storeSettings);

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

      final ticketName = vente.ticketNumber.isNotEmpty ? vente.ticketNumber : 'Ticket_${vente.id}';
      final fileName = 'Ticket_${ticketName.replaceAll('/', '_')}.pdf';
      final filePath = p.join(targetDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Ticket téléchargé dans : ${file.path}');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur lors du téléchargement du ticket : $e');
      }
    }
  }
}
