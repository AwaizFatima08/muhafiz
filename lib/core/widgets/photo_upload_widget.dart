import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Reusable photo upload widget.
/// Shows existing photo if [currentUrl] is provided.
/// Tapping opens a bottom sheet to choose camera or gallery.
/// [onFilePicked] returns the local File — caller handles the upload.
/// [label] is shown below the tile.
/// [isRequired] adds a red asterisk to the label (visual only — no validation block).
class PhotoUploadWidget extends StatelessWidget {
  final String label;
  final String? currentUrl;
  final File? localFile;
  final bool isRequired;
  final bool isUploading;
  final ValueChanged<File> onFilePicked;

  const PhotoUploadWidget({
    super.key,
    required this.label,
    required this.onFilePicked,
    this.currentUrl,
    this.localFile,
    this.isRequired = false,
    this.isUploading = false,
  });

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked != null) {
      onFilePicked(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = localFile != null || currentUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isUploading ? null : () => _pick(context),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: localFile != null
                            ? Image.file(localFile!, fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: currentUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to add photo',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (isRequired)
              const Text(' *',
                  style: TextStyle(fontSize: 12, color: Colors.red)),
            const Spacer(),
            if (hasImage && !isUploading)
              GestureDetector(
                onTap: () => _pick(context),
                child: Text(
                  'Change',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
