import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'category_import_service.dart';

class CategoryFormModal extends StatefulWidget {
  final Category? category;
  final Future<void> Function(Category) onSave;

  const CategoryFormModal({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends State<CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
  late final _descCtrl = TextEditingController(text: widget.category?.description ?? '');
  late int _color = widget.category?.color ?? kCategoryPalette.first.toARGB32();
  late int _icon = widget.category?.icon ?? kCategoryIcons.first.codePoint;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie *',
                  hintText: 'Ex: Électronique',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Le nom de la catégorie est obligatoire';
                  if (val.trim().length < 2) return 'Le nom doit contenir au moins 2 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Description optionnelle'),
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              const Text('Couleur', style: TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kCategoryPalette.map((c) {
                  final selected = _color == c.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _color = c.toARGB32()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppColors.textDark : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: c.withAlpha(100), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Text('Icône', style: TextStyle(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCategoryIcons.map((icon) {
                  final selected = _icon == icon.codePoint;
                  final activeColor = Color(_color);
                  return GestureDetector(
                    onTap: () => setState(() => _icon = icon.codePoint),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: selected ? activeColor.withAlpha(30) : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? activeColor : AppColors.divider,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(icon, color: selected ? activeColor : AppColors.textMedium, size: 22),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Modifier' : 'Créer la catégorie'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez saisir un nom de catégorie valide.');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final cat = Category(
        id: widget.category?.id,
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        color: _color,
        icon: _icon,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
      );
      await widget.onSave(cat);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue. Veuillez réessayer.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
