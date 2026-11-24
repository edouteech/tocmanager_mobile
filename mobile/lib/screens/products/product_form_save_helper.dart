import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../services/media_upload_service.dart';
import '../../theme/app_theme.dart';

TextEditingController initProductNumericCtrl(double? value, {bool zeroAsEmpty = true, String fallback = ''}) {
  if (value == null || (zeroAsEmpty && value <= 0)) {
    return TextEditingController(text: fallback);
  }
  return TextEditingController(text: value.toStringAsFixed(0));
}

Future<String?> persistProductImageBytes(Uint8List? imageBytes, String? existingPath) async {
  if (imageBytes == null) return existingPath;
  final remoteUrl = await MediaUploadService.instance.uploadProductImage(imageBytes);
  if (remoteUrl != null) return remoteUrl;
  if (existingPath != null && !MediaUploadService.isRemoteImagePath(existingPath)) {
    try {
      await File(existingPath).delete();
    } catch (_) {}
  }
  final dir = await getApplicationDocumentsDirectory();
  final imgDir = Directory('${dir.path}/product_images');
  await imgDir.create(recursive: true);
  final path = '${imgDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
  await File(path).writeAsBytes(imageBytes);
  return path;
}

Future<int?> resolveOrCreateProductCategoryId(BuildContext context, String rawCategoryName) async {
  final catText = rawCategoryName.trim();
  if (catText.isEmpty) return null;
  final catProvider = context.read<CategoryProvider>();
  final existingCat =
      catProvider.categories.where((c) => c.name.toLowerCase() == catText.toLowerCase()).firstOrNull;
  if (existingCat != null) return existingCat.id;
  final newCat = Category(
    name: catText,
    color: AppColors.primary.toARGB32(),
    icon: Icons.category.codePoint,
    createdAt: DateTime.now(),
  );
  return catProvider.add(newCat);
}

Future<void> executeSaveProductForm(
  BuildContext context, {
  required Product? existingProduct,
  required String name,
  required String description,
  required String categoryText,
  required int? supplierId,
  required double price,
  required double priceSemiWholesale,
  required double priceWholesale,
  required double minQtySemiWholesale,
  required double minQtyWholesale,
  required double costPrice,
  required double quantity,
  required double alertQuantity,
  required Uint8List? imageBytes,
  required String? imagePath,
  required Future<void> Function(Product) onSave,
}) async {
  final now = DateTime.now();
  final resolvedCatId = await resolveOrCreateProductCategoryId(context, categoryText);
  final savedImagePath = await persistProductImageBytes(imageBytes, imagePath);
  final product = Product(
    id: existingProduct?.id,
    name: name,
    description: description.trim().isEmpty ? null : description.trim(),
    categoryId: resolvedCatId,
    supplierId: supplierId,
    price: price,
    priceSemiWholesale: priceSemiWholesale,
    priceWholesale: priceWholesale,
    minQtySemiWholesale: minQtySemiWholesale,
    minQtyWholesale: minQtyWholesale,
    costPrice: costPrice,
    averageCostPrice: existingProduct?.averageCostPrice,
    barcode: existingProduct?.barcode,
    quantity: quantity,
    unit: existingProduct?.unit ?? 'pce',
    alertQuantity: alertQuantity,
    imagePath: savedImagePath,
    createdAt: existingProduct?.createdAt ?? now,
    updatedAt: now,
  );
  await onSave(product);
  if (context.mounted) Navigator.pop(context, product);
}
