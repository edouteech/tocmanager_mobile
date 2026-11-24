import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/vente.dart';
import '../providers/settings_provider.dart';
import 'export_helper.dart';

class TicketPdfService {
  static pw.Widget _kvRow(String label, String value, {bool bold = false, double fontSize = 8}) {
    final style = pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }

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
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(storeSettings.name.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  if (storeSettings.address.isNotEmpty) pw.Text(storeSettings.address, style: const pw.TextStyle(fontSize: 8)),
                  if (storeSettings.phone.isNotEmpty) pw.Text('Tél : ${storeSettings.phone}', style: const pw.TextStyle(fontSize: 8)),
                  if (storeSettings.email.isNotEmpty) pw.Text(storeSettings.email, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            _kvRow('Ticket : ${vente.ticketNumber}', dateFormat.format(vente.date), bold: true),
            if (vente.clientName != null && vente.clientName!.isNotEmpty)
              pw.Text('Client : ${vente.clientName}', style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('Désignation', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 1, child: pw.Text('Qté', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 2, child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.2),
            pw.SizedBox(height: 4),
            ...vente.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 8))),
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
                        child: pw.Text(formatter.format(item.total), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                )),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            if (vente.discountAmount > 0) ...[
              _kvRow('Sous-total brut :', formatter.format(vente.subtotalAmount)),
              _kvRow('Remise / Réduction :', '- ${formatter.format(vente.discountAmount)}'),
            ],
            _kvRow('TOTAL NET', formatter.format(vente.totalAmount), bold: true, fontSize: 10),
            _kvRow('Mode de Paiement :', vente.paymentMethod),
            _kvRow('Montant Versé :', formatter.format(vente.paidAmount)),
            if (vente.paidAmount > vente.totalAmount)
              _kvRow('Monnaie Rendue :', formatter.format(vente.paidAmount - vente.totalAmount)),
            if (vente.isCredit)
              _kvRow('Reste à payer (Crédit) :', formatter.format(vente.remainingAmount), bold: true),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                storeSettings.receiptFooter,
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static Future<void> shareTicketPdf(
    BuildContext context,
    Vente vente,
    StoreSettings storeSettings,
  ) async {
    final bytes = await generateTicketBytes(vente, storeSettings);
    if (!context.mounted) return;
    final ticketName = vente.ticketNumber.isNotEmpty ? vente.ticketNumber : 'Ticket_${vente.id}';
    await ExportHelper.shareBytesAsFile(
      context,
      bytes: bytes,
      fileName: 'ticket_${ticketName.replaceAll('/', '_')}.pdf',
      shareText: 'Ticket de caisse ${vente.ticketNumber} — ${storeSettings.name}',
      errorPrefix: 'Erreur lors du partage du ticket : ',
    );
  }

  static Future<void> downloadTicketPdf(
    BuildContext context,
    Vente vente,
    StoreSettings storeSettings,
  ) async {
    final bytes = await generateTicketBytes(vente, storeSettings);
    if (!context.mounted) return;
    final ticketName = vente.ticketNumber.isNotEmpty ? vente.ticketNumber : 'Ticket_${vente.id}';
    await ExportHelper.downloadBytes(
      context,
      bytes: bytes,
      fileName: 'Ticket_${ticketName.replaceAll('/', '_')}.pdf',
      successPrefix: 'Ticket téléchargé dans : ',
      errorPrefix: 'Erreur lors du téléchargement du ticket : ',
    );
  }
}
