import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';

void showCategoryImportPreviewSheet(
  BuildContext context,
  List<Map<String, String>> rows,
  Future<void> Function(BuildContext context, List<Map<String, String>> rows) onConfirmImport,
) {
  final catProvider = context.read<CategoryProvider>();
  final existingNames = {
    for (final c in catProvider.categories) c.name.toLowerCase().trim()
  };

  final newCount = rows.where((r) => !existingNames.contains(r['name']!.toLowerCase().trim())).length;
  final alreadyExistCount = rows.length - newCount;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final preview = rows.take(4).toList();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.upload_file_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Importer ${rows.length} catégorie${rows.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                '$newCount nouvelle${newCount > 1 ? 's' : ''} catégorie${newCount > 1 ? 's' : ''} à créer'
                '${alreadyExistCount > 0 ? ' ($alreadyExistCount déjà existante${alreadyExistCount > 1 ? 's' : ''} ignorée${alreadyExistCount > 1 ? 's' : ''})' : ''}.',
                style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...preview.map((r) {
                final isDuplicate = existingNames.contains(r['name']!.toLowerCase().trim());
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(
                      isDuplicate ? Icons.info_outline : Icons.check_circle_outline,
                      size: 18,
                      color: isDuplicate ? AppColors.warning : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDuplicate ? AppColors.textMedium : AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDuplicate)
                      const Text('Déjà existante', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                  ]),
                );
              }),
              if (rows.length > 4) ...[
                Text(
                  '... et ${rows.length - 4} autre${rows.length - 4 > 1 ? 's' : ''}',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                ),
                const SizedBox(height: 4),
              ],
              const Divider(height: 1),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await onConfirmImport(context, rows);
                  },
                  child: const Text("Confirmer l'importation"),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ),
            ],
          ),
        ),
      );
    },
  );
}
