import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/supplier.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/app_toast.dart';

class SupplierFormModal extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormModal({super.key, this.supplier});

  @override
  State<SupplierFormModal> createState() => _SupplierFormModalState();
}

class _SupplierFormModalState extends State<SupplierFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.supplier?.name ?? '');
  late final _contactCtrl = TextEditingController(text: widget.supplier?.contactPerson ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.supplier?.phone ?? '');
  late final _emailCtrl = TextEditingController(text: widget.supplier?.email ?? '');
  late final _addressCtrl = TextEditingController(text: widget.supplier?.address ?? '');
  late final _balanceCtrl =
      TextEditingController(text: widget.supplier != null ? widget.supplier!.balance.toStringAsFixed(0) : '0');
  late final _notesCtrl = TextEditingController(text: widget.supplier?.notes ?? '');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _balanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Modifier Fournisseur' : 'Nouveau Fournisseur',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom de la société / Nom *'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Le nom du fournisseur est obligatoire';
                  if (val.trim().length < 2) return 'Le nom doit contenir au moins 2 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Personne de contact')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty && val.trim().length < 8) {
                    return 'Numéro de téléphone invalide (min. 8 chiffres)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                    return 'Adresse email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Adresse')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Solde impayé / Dette fournisseur (FCFA)'),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final num = double.tryParse(val.trim());
                    if (num == null || num < 0) return 'Saisissez un montant valide (>= 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _save(isEdit),
                  child: Text(isEdit ? 'Modifier' : 'Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(bool isEdit) async {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez corriger le nom ou le contact du fournisseur.');
      return;
    }
    final name = _nameCtrl.text.trim();
    final nav = Navigator.of(context);
    final provider = context.read<SupplierProvider>();
    final s = Supplier(
      id: widget.supplier?.id,
      name: name,
      contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      balance: double.tryParse(_balanceCtrl.text) ?? 0,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.supplier?.createdAt ?? DateTime.now(),
    );
    if (isEdit) {
      await provider.updateSupplier(s);
    } else {
      await provider.addSupplier(s);
    }
    if (mounted) nav.pop();
  }
}
