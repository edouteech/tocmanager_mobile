import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'secure_storage_service.dart';

class MediaUploadService {
  MediaUploadService._internal();
  static final MediaUploadService instance = MediaUploadService._internal();

  static bool isRemoteImagePath(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://') || path.startsWith('/');
  }

  static String resolveDisplayImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      final parsed = Uri.tryParse(SecureStorageService.apiUrl);
      if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
        return '${parsed.origin}$path';
      }
    }
    return path;
  }

  /// Upload image bytes to `/uploads/images`; returns remote URL or null when offline.
  Future<String?> uploadProductImage(
    Uint8List imageBytes, {
    String filename = 'product.png',
  }) async {
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final baseUrl = await SecureStorageService.getServerUrl();
      final boutiqueId = await SecureStorageService.getCurrentBoutiqueId();
      final magasinId = await SecureStorageService.getCurrentMagasinId();
      final isConsolidated = await SecureStorageService.isConsolidatedMode();

      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/uploads/images'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers.addAll(
        ApiClient.buildTenantHeaders(
          boutiqueId: boutiqueId,
          magasinId: magasinId,
          isConsolidated: isConsolidated,
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final url = decoded['url'] as String?;
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (e) {
      debugPrint('[MediaUploadService] Upload fallback local: $e');
    }
    return null;
  }
}
