import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/media_upload_service.dart';
import 'sync_dao.dart';

Map<String, dynamic> buildCategorySyncPayload(
  Category cat,
  String syncId,
  String now, {
  String? deletedAt,
}) {
  final hexColor = '#${(cat.color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  return {
    'sync_id': syncId,
    'name': cat.name,
    'description': cat.description,
    'color': hexColor,
    'icon': cat.icon.toString(),
    'updated_at': now,
    if (deletedAt != null) 'deleted_at': deletedAt,
  };
}

Future<Map<String, dynamic>> buildProductSyncPayload(
  DatabaseExecutor txn,
  Product p,
  String syncId,
  String now, {
  String? deletedAt,
  String? magasinId,
}) async {
  final catSyncId = await SyncDao.findSyncId(txn, 'categories', p.categoryId);
  return {
    'sync_id': syncId,
    'name': p.name,
    'category_sync_id': catSyncId,
    'price': p.price,
    'cost_price': p.costPrice,
    'average_cost_price': p.averageCostPrice ?? 0.0,
    'stock': p.quantity,
    'min_stock': p.alertQuantity,
    'barcode': p.barcode,
    'unit': p.unit,
    if (MediaUploadService.isRemoteImagePath(p.imagePath)) 'image_path': p.imagePath,
    if (magasinId != null && magasinId.isNotEmpty) 'magasin_id': magasinId,
    'is_active': deletedAt == null,
    'updated_at': now,
    if (deletedAt != null) 'deleted_at': deletedAt,
  };
}
