import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class SelectedAssetsPreview extends StatelessWidget {
  final List<AssetEntity> assets;
  final ValueChanged<int> onRemoveAsset;
  final VoidCallback onPickAssets; // 新增：接收用于打开照片选择器的回调

  const SelectedAssetsPreview({
    super.key,
    required this.assets,
    required this.onRemoveAsset,
    required this.onPickAssets, // 新增
  });

  @override
  Widget build(BuildContext context) {
    // 这里不再需要 if (assets.isEmpty) 判断，因为调用它的父组件已经处理了
    return Padding(
      // 移除顶部的 padding，让布局更紧凑，这个可以根据你的 UI 需求调整
      // padding: const EdgeInsets.only(top: 16.0),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              // 使用 GestureDetector 包裹整个图片项
              child: GestureDetector(
                onTap: onPickAssets, // 点击图片时，重新打开照片选择器
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AssetEntityImage(
                        asset,
                        isOriginal: false,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveAsset(index), // 这个 onTap 依然只负责移除
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
      ),
    );
  }
}
