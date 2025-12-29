// lib/presentation/widgets/user/user_circle_avatar.dart

import 'package:flutter/material.dart';
import 'package:prismbox/domain/entities/user_profile.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 用户圆形头像组件
/// 
/// 显示用户头像，如果用户没有头像则显示用户名首字母
/// 参考 Immich 和 Google Photos 的设计
class UserCircleAvatar extends StatelessWidget {
  /// 用户资料
  final UserProfile user;
  
  /// 头像半径
  final double radius;
  
  /// 是否显示边框
  final bool hasBorder;

  const UserCircleAvatar({
    super.key,
    required this.user,
    this.radius = 17.0,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = _getAvatarColor(user.id, theme);
    
    // 构建头像URL（如果有）
    final String? avatarUrl = user.avatarUrl != null && user.avatarUrl!.isNotEmpty
        ? _buildAvatarUrl(user.avatarUrl!)
        : null;
    
    // 用户名首字母
    final String initials = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasBorder
            ? Border.all(
                color: theme.colorScheme.outline.withOpacity(0.12),
                width: 2.5,
              )
            : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: avatarColor,
        child: avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 加载失败时显示首字母
                    return _buildInitialsText(initials, avatarColor);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    // 加载中显示首字母
                    return _buildInitialsText(initials, avatarColor);
                  },
                ),
              )
            : _buildInitialsText(initials, avatarColor),
      ),
    );
  }

  /// 构建头像URL
  /// 
  /// 如果 avatarUrl 是相对路径，则拼接服务器地址
  String _buildAvatarUrl(String avatarUrl) {
    // 如果是完整的URL，直接返回
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return avatarUrl;
    }
    
    // 如果是相对路径，拼接服务器地址
    try {
      final apiService = ApiService();
      final endpoint = apiService.endpoint;
      if (endpoint != null && endpoint.isNotEmpty) {
        // 移除 /api/v1 后缀（如果有）
        final baseUrl = endpoint.replaceAll('/api/v1', '').replaceAll(RegExp(r'/+$'), '');
        // 确保 avatarUrl 以 / 开头
        final path = avatarUrl.startsWith('/') ? avatarUrl : '/$avatarUrl';
        return '$baseUrl$path';
      }
    } catch (e) {
      // 如果获取 endpoint 失败，返回原始 avatarUrl
    }
    
    return avatarUrl;
  }

  /// 根据用户ID生成主题色
  Color _getAvatarColor(int userId, ThemeData theme) {
    // 使用用户ID生成一个稳定的颜色
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    final index = userId % colors.length;
    return colors[index];
  }

  /// 构建首字母文本
  Widget _buildInitialsText(String initials, Color backgroundColor) {
    final textColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    
    return Text(
      initials,
      style: TextStyle(
        color: textColor,
        fontSize: radius * 0.7,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

