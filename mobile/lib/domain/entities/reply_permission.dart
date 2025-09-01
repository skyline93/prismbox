// lib/ui/new_thread/models/reply_permission.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// 定义回复权限的枚举类型
enum ReplyPermission {
  @JsonValue('anyone') // 明确指定序列化时的字符串值
  anyone,
  @JsonValue('profiles_you_follow') // 明确指定序列化时的字符串值
  profilesYouFollow,
  @JsonValue('mentioned_only') // 明确指定序列化时的字符串值
  mentionedOnly
}

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

  /// [新增] 用于将枚举转换为后端可识别的字符串
  /// 它返回 @JsonValue 指定的字符串，如果未指定则返回枚举名的小写形式
  String toJson() {
    // 假设后端期待的是枚举名的小写形式，或者你在枚举上使用了 @JsonValue 注解
    // 例如：ReplyPermission.anyone.name 会得到 "anyone"
    switch (this) {
      case ReplyPermission.anyone:
        return 'anyone';
      case ReplyPermission.profilesYouFollow:
        return 'profiles_you_follow';
      case ReplyPermission.mentionedOnly:
        return 'mentioned_only';
    }
  }
}
