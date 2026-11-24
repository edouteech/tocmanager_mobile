import '../../models/date_filter_period.dart';
import '../../models/vente.dart';

String ventePeriodLabel({
  required bool onlyCredit,
  required DateFilterPeriod dateFilter,
}) {
  if (onlyCredit) {
    return dateFilter.preset == PeriodPreset.all
        ? 'Ventes à crédit'
        : 'Ventes à crédit - ${dateFilter.label}';
  }
  return dateFilter.label;
}

List<Vente> filterAndSortVentes(
  List<Vente> allVentes, {
  required bool onlyCredit,
  required DateFilterPeriod dateFilter,
  required String searchQuery,
  required String sortBy,
}) {
  final q = searchQuery.trim().toLowerCase();
  final filtered = allVentes.where((v) {
    if (onlyCredit && !v.isCredit) return false;
    if (!dateFilter.matches(v.date)) return false;
    if (q.isNotEmpty) {
      final ticketMatch = v.ticketNumber.toLowerCase().contains(q);
      final clientMatch = (v.clientName ?? '').toLowerCase().contains(q);
      final itemMatch = v.items.any((it) => it.productName.toLowerCase().contains(q));
      if (!ticketMatch && !clientMatch && !itemMatch) return false;
    }
    return true;
  }).toList();

  filtered.sort((a, b) {
    if (sortBy == 'amount_desc') return b.totalAmount.compareTo(a.totalAmount);
    if (sortBy == 'client_asc') {
      final na = (a.clientName ?? 'Occasionnel').toLowerCase();
      final nb = (b.clientName ?? 'Occasionnel').toLowerCase();
      return na.compareTo(nb);
    }
    return b.date.compareTo(a.date);
  });
  return filtered;
}

String formatVenteQty(double qty) => qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
