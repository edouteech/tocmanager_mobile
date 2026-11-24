import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';

class ClientFormModal extends StatefulWidget {
  final Client? client;

  const ClientFormModal({super.key, this.client});

  @override
  State<ClientFormModal> createState() => _ClientFormModalState();
}

class _ClientFormModalState extends State<ClientFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _balanceController;
  late String _clientType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _addressController = TextEditingController(text: widget.client?.address ?? '');
    _balanceController = TextEditingController(text: widget.client?.balance.toString() ?? '0');
    _clientType = widget.client?.clientType ?? 'detail';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Modifier Client' : 'Nouveau Client',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom complet *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Veuillez entrer le nom' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _clientType,
                decoration: const InputDecoration(
                  labelText: 'Type de tarif attribué',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.style_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: 'detail', child: Text('Client Détail (Standard)')),
                  DropdownMenuItem(value: 'demi_gros', child: Text('Client Demi-Gros')),
                  DropdownMenuItem(value: 'gros', child: Text('Client Grossiste')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _clientType = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresse / Quartier', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Solde initial (Créance en FCFA)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveClient,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(isEditing ? 'Enregistrer les modifications' : 'Ajouter le client'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ClientProvider>();
    final newClient = Client(
      id: widget.client?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      balance: double.tryParse(_balanceController.text) ?? 0.0,
      clientType: _clientType,
      createdAt: widget.client?.createdAt ?? DateTime.now(),
    );

    if (widget.client != null) {
      await provider.updateClient(newClient);
    } else {
      await provider.addClient(newClient);
    }

    if (mounted) Navigator.pop(context);
  }
}
