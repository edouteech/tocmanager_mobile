import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/vente.dart';
import '../services/sync_service.dart';

class ClientProvider extends ChangeNotifier {
  List<Client> _clients = [];
  bool _loading = false;

  List<Client> get clients => _clients;
  bool get loading => _loading;

  double get totalCreances => _clients.fold(0, (sum, c) => sum + (c.balance > 0 ? c.balance : 0));
  double get totalAvoirs => _clients.fold(0, (sum, c) => sum + (c.balance < 0 ? c.balance.abs() : 0));

  Future<void> loadClients() async {
    _loading = true;
    notifyListeners();
    _clients = await DatabaseHelper.instance.getClients();
    _loading = false;
    notifyListeners();
  }

  Future<int> addClient(Client client) async {
    final id = await DatabaseHelper.instance.insertClient(client);
    _clients.insert(0, client.copyWith(id: id));
    notifyListeners();
    SyncService.instance.notifyLocalMutation();
    return id;
  }

  Future<void> updateClient(Client client) async {
    await DatabaseHelper.instance.updateClient(client);
    final idx = _clients.indexWhere((c) => c.id == client.id);
    if (idx != -1) {
      _clients[idx] = client;
      notifyListeners();
    }
    SyncService.instance.notifyLocalMutation();
  }

  Future<void> deleteClient(int id) async {
    await DatabaseHelper.instance.deleteClient(id);
    _clients.removeWhere((c) => c.id == id);
    notifyListeners();
    SyncService.instance.notifyLocalMutation();
  }

  Future<void> recordPayment(int clientId, double paymentAmount) async {
    await DatabaseHelper.instance.recordClientPayment(clientId, paymentAmount);
    await loadClients();
    SyncService.instance.notifyLocalMutation();
  }

  Future<void> recordPaymentForVente({
    required Client client,
    required Vente vente,
    required double paymentAmount,
  }) async {
    await DatabaseHelper.instance.recordClientPayment(
      client.id!,
      paymentAmount,
      specificVenteId: vente.id,
    );
    await loadClients();
    SyncService.instance.notifyLocalMutation();
  }

  Future<void> recordGlobalPaymentAllocated({
    required Client client,
    required double paymentAmount,
    required List<Vente> debtSales,
  }) async {
    await DatabaseHelper.instance.recordClientPayment(client.id!, paymentAmount);
    await loadClients();
    SyncService.instance.notifyLocalMutation();
  }

  Future<void> recordAvoirRefund({
    required Client client,
    required double refundAmount,
  }) async {
    final newBalance = client.balance + refundAmount;
    final updated = client.copyWith(balance: newBalance);
    await updateClient(updated);
  }
}
