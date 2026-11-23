from io import BytesIO
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

from app.models import Boutique, SaasInvoice


def generate_saas_invoice_pdf(invoice: SaasInvoice, boutique: Boutique) -> bytes:
    """Render an official PDF receipt for a paid SaaS subscription invoice."""
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4

    pdf.setTitle(f"Facture {invoice.invoice_number}")
    pdf.setFont("Helvetica-Bold", 18)
    pdf.drawString(50, height - 60, "TocManager SaaS - Facture Abonnement")

    pdf.setFont("Helvetica", 11)
    pdf.drawString(50, height - 95, f"Numero de facture : {invoice.invoice_number}")
    issued = invoice.issued_at.strftime("%Y-%m-%d %H:%M UTC") if invoice.issued_at else "-"
    pdf.drawString(50, height - 115, f"Date d'emission : {issued}")

    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(50, height - 155, "Client / Boutique")
    pdf.setFont("Helvetica", 11)
    pdf.drawString(50, height - 175, f"Boutique : {boutique.name}")
    if boutique.company_name:
        pdf.drawString(50, height - 193, f"Raison sociale : {boutique.company_name}")
    if boutique.email:
        pdf.drawString(50, height - 211, f"Email : {boutique.email}")

    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(50, height - 250, "Details de la souscription")
    pdf.setFont("Helvetica", 11)
    cycle_label = "Annuel" if invoice.billing_cycle == "yearly" else "Mensuel"
    p_start = invoice.period_start.strftime("%Y-%m-%d") if invoice.period_start else "-"
    p_end = invoice.period_end.strftime("%Y-%m-%d") if invoice.period_end else "-"
    pdf.drawString(50, height - 272, f"Forfait : {invoice.plan_name} ({cycle_label})")
    pdf.drawString(50, height - 290, f"Periode couverte : du {p_start} au {p_end}")

    pdf.setFont("Helvetica-Bold", 13)
    pdf.drawString(50, height - 330, f"Montant paye : {invoice.amount:,.0f} {invoice.currency}")

    pdf.setFont("Helvetica", 9)
    pdf.drawString(50, 50, "Document genere automatiquement par TocManager Billing.")
    pdf.showPage()
    pdf.save()
    return buffer.getvalue()
