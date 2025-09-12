// lib/ui/new_thread/widgets/image_attachment_area.dart
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'selected_assets_preview.dart';

class ImageAttachmentArea extends StatelessWidget {
  final List<AssetEntity> assets;
  final VoidCallback onPickAssets;
  final ValueChanged<int> onRemoveAsset;

  const ImageAttachmentArea({
    super.key,
    required this.assets,
    required this.onPickAssets,
    required this.onRemoveAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return GestureDetector(
        onTap: onPickAssets,
        child: DottedBorder(
          options: RectDottedBorderOptions(
            color: Colors.grey.shade400,
            strokeWidth: 1.5,
            dashPattern: const [6, 4],
          ),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.gallery_add,
                    color: Colors.grey.shade500,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text('添加图片', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return SelectedAssetsPreview(
        assets: assets,
        onRemoveAsset: onRemoveAsset,
        onPickAssets: onPickAssets,
      );
    }
  }
}
