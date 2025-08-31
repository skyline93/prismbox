// lib/ui/new_thread/models/reply_permission.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// 定义回复权限的枚举类型
enum ReplyPermission { anyone, profilesYouFollow, mentionedOnly }

/// 为枚举添加扩展方法，方便获取显示文本、标题和图标
extension ReplyPermissionExtension on ReplyPermission {
  String get displayText {
    switch (this) {
      case ReplyPermission.anyone:
        return '任何人都可以回复';
      case ReplyPermission.profilesYouFollow:
        return '你关注的主页可以回复';
      case ReplyPermission.mentionedOnly:
        return '仅限被提及的主页可以回复';
    }
  }

  String get title {
    switch (this) {
      case ReplyPermission.anyone:
        return '任何人';
      case ReplyPermission.profilesYouFollow:
        return '你关注的主页';
      case ReplyPermission.mentionedOnly:
        return '仅限被提及';
    }
  }

  IconData get icon {
    switch (this) {
      case ReplyPermission.anyone:
        return Iconsax.global;
      case ReplyPermission.profilesYouFollow:
        return Iconsax.profile_2user;
      case ReplyPermission.mentionedOnly:
        return Iconsax.attach_circle;
    }
  }
}
