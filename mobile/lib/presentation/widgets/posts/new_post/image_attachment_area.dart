// lib/presentation/widgets/posts/new_post/image_attachment_area.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:prismbox/data/database/app_database.dart';

/// 图片附件区域组件
/// 适配 Prismbox 的 LocalAssetEntityData
class ImageAttachmentArea extends StatelessWidget {
  final List<String> assetIds; // 选中的 assetId 列表
  final Map<String, LocalAssetEntityData> assetMap; // assetId 到 LocalAssetEntityData 的映射
  final VoidCallback onPickAssets;
  final ValueChanged<int> onRemoveAsset;

  const ImageAttachmentArea({
    super.key,
    required this.assetIds,
    required this.assetMap,
    required this.onPickAssets,
    required this.onRemoveAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (assetIds.isEmpty) {
      // 状态一：未选择任何图片，显示虚线框占位符
      return GestureDetector(
        onTap: onPickAssets,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade400,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.grey.shade500,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '添加图片',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // 状态二：已选择图片，显示预览
      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: assetIds.length,
          itemBuilder: (context, index) {
            final assetId = assetIds[index];
            final localAsset = assetMap[assetId];
            if (localAsset == null) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              // 使用 GestureDetector 包裹整个图片项
              child: GestureDetector(
                onTap: onPickAssets, // 点击图片时，重新打开照片选择器
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FutureBuilder<File?>(
                        future: _loadThumbnail(localAsset),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.file(
                              snapshot.data!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveAsset(index), // 这个 onTap 只负责移除
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  /// 加载缩略图
  Future<File?> _loadThumbnail(LocalAssetEntityData localAsset) async {
    try {
      final file = File(localAsset.path);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

