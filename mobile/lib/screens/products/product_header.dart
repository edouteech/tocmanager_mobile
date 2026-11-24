import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import 'product_export_service.dart';
import 'product_import_service.dart';

class ProductsHeader extends StatelessWidget {
  final VoidCallback? onBackToHome;
  final VoidCallback onAddProduct;

  const ProductsHeader({
    super.key,
    required this.onBackToHome,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    onBackToHome?.call();
                  }
                },
                tooltip: 'Retour',
              ),
              const Expanded(
                child: Text(
                  'Produits & Stocks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Import / Export',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.ios_share_outlined, color: AppColors.primary, size: 20),
                ),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Exporter la liste'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.upload_file_outlined, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text('Importer des produits'),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'export') {
                    showProductExportSheet(context, context.read<ProductProvider>().products);
                  } else if (val == 'import') {
                    importProductsFromExcel(context);
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAddProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
