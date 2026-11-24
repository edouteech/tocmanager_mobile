import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/media_upload_service.dart';
import '../../theme/app_theme.dart';

class ProductFormImageTile extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imagePath;
  final VoidCallback onTap;

  const ProductFormImageTile({
    super.key,
    required this.imageBytes,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
        ),
        child: _buildPreview(),
      ),
    );
  }

  Widget _buildPreview() {
    if (imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.memory(imageBytes!, fit: BoxFit.cover, width: 76, height: 76),
      );
    }
    if (imagePath != null) {
      if (MediaUploadService.isRemoteImagePath(imagePath)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.network(
            MediaUploadService.resolveDisplayImageUrl(imagePath!),
            fit: BoxFit.cover,
            width: 76,
            height: 76,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.file(
          File(imagePath!),
          fit: BoxFit.cover,
          width: 76,
          height: 76,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, color: AppColors.textLight, size: 22),
        SizedBox(height: 4),
        Text('Photo', style: TextStyle(color: AppColors.textLight, fontSize: 10)),
      ],
    );
  }
}

void showProductImageSourceSheet(
  BuildContext context, {
  required bool hasImage,
  required ValueChanged<ImageSource> onPick,
  required VoidCallback onClear,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Galerie'),
            onTap: () {
              Navigator.pop(ctx);
              onPick(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Appareil photo'),
            onTap: () {
              Navigator.pop(ctx);
              onPick(ImageSource.camera);
            },
          ),
          if (hasImage)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Supprimer la photo', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                onClear();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class ProductImageProcessorSheet extends StatefulWidget {
  final String sourcePath;
  final void Function(Uint8List) onConfirm;

  const ProductImageProcessorSheet({
    super.key,
    required this.sourcePath,
    required this.onConfirm,
  });

  @override
  State<ProductImageProcessorSheet> createState() => _ProductImageProcessorSheetState();
}

class _ProductImageProcessorSheetState extends State<ProductImageProcessorSheet> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Traiter l\'image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: Image.file(File(widget.sourcePath), fit: BoxFit.contain)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showMaterialImageCropper(
                    context,
                    imageProvider: FileImage(File(widget.sourcePath)),
                  );
                  Uint8List bytes;
                  if (result != null) {
                    final byteData = await result.uiImage.toByteData(format: ui.ImageByteFormat.png);
                    bytes = byteData != null
                        ? byteData.buffer.asUint8List()
                        : await File(widget.sourcePath).readAsBytes();
                  } else {
                    bytes = await File(widget.sourcePath).readAsBytes();
                  }
                  widget.onConfirm(bytes);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Utiliser cette image'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
