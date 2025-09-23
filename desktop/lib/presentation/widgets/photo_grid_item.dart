import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/datasources/local/app_database.dart';

class PhotoGridItem extends StatelessWidget {
  final MediaAsset asset;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PhotoGridItem({
    super.key,
    required this.asset,
    this.isSelected = false, // 新增：是否被选中
    this.onTap,
    this.onLongPress, // 新增：长按回调
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress, // 绑定长按事件
      child: GridTile(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: asset.hash,
              child: CachedNetworkImage(
                imageUrl: asset.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // 如果被选中，显示遮罩和图标
            if (isSelected) Container(color: Colors.black.withOpacity(0.5)),
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
