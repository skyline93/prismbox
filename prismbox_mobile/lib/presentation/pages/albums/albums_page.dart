import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/widgets/user/user_profile_indicator.dart';

/// 合集页面
/// 模仿 Google 相册的 UI 设计
@RoutePage()
class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '合集',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              // TODO: 添加新内容
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              // TODO: 通知
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: UserProfileIndicator(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 快捷操作按钮区
            _buildQuickActions(context),

            const SizedBox(height: 16),

            // 卡片预览区
            _buildCardSection(context, ref),

            const SizedBox(height: 24),

            // 分类列表区
            _buildCategoryList(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 构建快捷操作按钮区
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.star_outline,
                  label: '收藏',
                  onTap: () {
                    // TODO: 跳转到收藏页面
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.delete_outline,
                  label: '回收站',
                  onTap: () {
                    // TODO: 跳转到回收站
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.crop_square_outlined,
                  label: '屏幕截图',
                  onTap: () {
                    // TODO: 跳转到截图页面
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.archive_outlined,
                  label: '归档',
                  onTap: () {
                    // TODO: 跳转到归档页面
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // 使用足够大的圆角值实现左右两边完全圆形（胶囊形状）
    const double borderRadius = 50.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.grey[300]!, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建卡片预览区
  Widget _buildCardSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMediaCard(
              context,
              title: '在此设备上',
              onTap: () {
                // TODO: 跳转到设备媒体页面
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMediaCard(
              context,
              title: '相册',
              onTap: () {
                // TODO: 跳转到相册列表页面
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建媒体卡片
  Widget _buildMediaCard(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2x2 网格缩略图
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildThumbnailGrid(context),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建缩略图网格（2x2）
  Widget _buildThumbnailGrid(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        // TODO: 从实际数据源获取缩略图
        // 这里先用占位符
        return Container(
          color: Colors.grey[200],
          child: index == 0
              ? const Icon(Icons.image, size: 40, color: Colors.grey)
              : null,
        );
      },
    );
  }

  /// 构建分类列表区
  Widget _buildCategoryList(BuildContext context) {
    final categories = [
      _CategoryItem(
        icon: Icons.location_on_outlined,
        label: '地点',
        onTap: () {
          // TODO: 跳转到地点页面
        },
      ),
      _CategoryItem(
        icon: Icons.crop_square_outlined,
        label: '屏幕截图',
        onTap: () {
          // TODO: 跳转到截图页面
        },
      ),
      _CategoryItem(
        icon: Icons.videocam_outlined,
        label: '视频',
        onTap: () {
          // TODO: 跳转到视频页面
        },
      ),
      _CategoryItem(
        icon: Icons.access_time_outlined,
        label: '最近添加',
        onTap: () {
          // TODO: 跳转到最近添加页面
        },
      ),
      _CategoryItem(
        icon: Icons.archive_outlined,
        label: '归档',
        onTap: () {
          // TODO: 跳转到归档页面
        },
      ),
      _CategoryItem(
        icon: Icons.lock_outline,
        label: '加密',
        onTap: () {
          // TODO: 跳转到加密页面
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: categories.map((category) {
          return _buildCategoryListItem(context, category);
        }).toList(),
      ),
    );
  }

  /// 构建分类列表项
  Widget _buildCategoryListItem(BuildContext context, _CategoryItem category) {
    return InkWell(
      onTap: category.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(category.icon, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.label,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// 分类项数据模型
class _CategoryItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _CategoryItem({required this.icon, required this.label, required this.onTap});
}
