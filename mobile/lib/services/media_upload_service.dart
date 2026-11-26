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
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('/api/') ||
        path.startsWith('/uploads/');
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

  Future<http.StreamedResponse> _sendMultipartUpload({
    required String baseUrl,
    required String token,
    required String? boutiqueId,
    required String? magasinId,
    required bool isConsolidated,
    required Uint8List imageBytes,
    required String filename,
    Future<http.StreamedResponse> Function(http.MultipartRequest)? sendRequest,
  }) {
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
      http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
    );
    final future = sendRequest != null ? sendRequest(request) : request.send();
    return future.timeout(const Duration(seconds: 20));
  }

  /// Upload image bytes to `/uploads/images`; returns remote URL or null when offline.
  Future<String?> uploadProductImage(
    Uint8List imageBytes, {
    String filename = 'product.png',
    @visibleForTesting Future<http.StreamedResponse> Function(http.MultipartRequest)? sendRequest,
    @visibleForTesting Future<bool> Function()? checkRefresh,
    @visibleForTesting Future<bool> Function()? onRefreshTokens,
  }) async {
    try {
      await (checkRefresh ?? ApiClient.instance.checkAndProactiveRefresh)();
      var token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final baseUrl = await SecureStorageService.getServerUrl();
      final boutiqueId = await SecureStorageService.getCurrentBoutiqueId();
      final magasinId = await SecureStorageService.getCurrentMagasinId();
      final isConsolidated = await SecureStorageService.isConsolidatedMode();

      var streamed = await _sendMultipartUpload(
        baseUrl: baseUrl,
        token: token,
        boutiqueId: boutiqueId,
        magasinId: magasinId,
        isConsolidated: isConsolidated,
        imageBytes: imageBytes,
        filename: filename,
        sendRequest: sendRequest,
      );

      if (streamed.statusCode == 401 && await (onRefreshTokens ?? ApiClient.instance.refreshTokens)()) {
        await streamed.stream.drain<void>();
        token = await SecureStorageService.getAccessToken();
        if (token == null || token.isEmpty) return null;
        streamed = await _sendMultipartUpload(
          baseUrl: baseUrl,
          token: token,
          boutiqueId: boutiqueId,
          magasinId: magasinId,
          isConsolidated: isConsolidated,
          imageBytes: imageBytes,
          filename: filename,
          sendRequest: sendRequest,
        );
      }

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
