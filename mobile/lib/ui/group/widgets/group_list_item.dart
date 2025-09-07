// lib/ui/group/widgets/group_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/group/group_models.dart';

class GroupListItemWidget extends ConsumerStatefulWidget {
  const GroupListItemWidget({
    super.key,
    required this.group,
    required this.onTap,
  });

  final GroupModel group;
  final VoidCallback onTap;

  @override
  ConsumerState<GroupListItemWidget> createState() =>
      _GroupListItemWidgetState();
}

class _GroupListItemWidgetState extends ConsumerState<GroupListItemWidget> {
  bool _isPressed = false;

  Color _generateColorFromName(String name) {
    final hash = name.hashCode;
    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.deepPurple,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
    ];
    return colors[hash % colors.length];
  }

  // ✨ 更智能、更美观的占位符
  Widget _buildSmartCover(BuildContext context) {
    Theme.of(context);
    final groupName = widget.group.name;
    final placeholderColor = _generateColorFromName(groupName);

    // TODO: 这里将来要替换为真实的图片加载逻辑
    // final bool hasCoverImage = widget.group.coverMediaUuid != null;
    final bool hasCoverImage = false; // 暂时假设没有封面图

    // ignore: dead_code
    if (hasCoverImage) {
      // 如果有封面图，显示封面图
    } else {
      // 使用圈子名称首字母作为占位符
      return CircleAvatar(
        radius: 28,
        backgroundColor: placeholderColor.withOpacity(0.8),
        child: Text(
          groupName.isNotEmpty ? groupName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // ✨ 增加触感反馈
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      // ✨【核心动画】使用 AnimatedScale 实现按压缩小效果
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            // ✨【核心质感】使用微妙的渐变代替纯色背景
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceVariant.withOpacity(0.7),
                theme.colorScheme.surfaceVariant.withOpacity(0.4),
              ],
            ),
            // 添加一个细微的边框，提升精致感
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              _buildSmartCover(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // ✨【信息丰富度】如果描述存在，则显示；否则显示成员数
                    Text(
                      widget.group.description?.isNotEmpty == true
                          ? widget.group.description!
                          : '${widget.group.memberCount ?? 0} 成员',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
