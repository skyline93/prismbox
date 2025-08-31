// lib/data/mock_feed_data.dart

import 'dart:math';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/data/models/media/media_model.dart';

/// 一个工具函数，用于为UI测试生成模拟的 feed 项列表。
List<GroupFeedItemEntity> getMockFeedItems() {
  const uuid = Uuid();
  final random = Random();

  // 将 "2h" 这样的相对时间字符串解析为 DateTime 对象。
  DateTime parseTimeAgo(String timeAgo) {
    final now = DateTime.now();
    if (timeAgo.contains('h')) {
      final value = int.tryParse(timeAgo.replaceAll('h', '')) ?? 0;
      return now.subtract(Duration(hours: value));
    }
    if (timeAgo.contains('d')) {
      final value = int.tryParse(timeAgo.replaceAll('d', '')) ?? 0;
      return now.subtract(Duration(days: value));
    }
    return now;
  }

  // 从 Unsplash URL 中提取唯一ID，用于模拟 cloudUuid。
  String extractIdFromUrl(String url) {
    try {
      return Uri.parse(url).pathSegments.last;
    } catch (e) {
      return uuid.v4();
    }
  }

  // 这是你的参考项目的原始数据。
  final rawPosts = [
    {
      'username': 'travel_diaries',
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1887&q=80',
      'content':
          'Sunset views from Santorini 🌅 Absolutely breathtaking! Who else loves Greek islands?',
      'time': '2h',
      'likes': 3245,
      'replies': 267,
      'imageUrls': [
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2069&q=80',
      ],
    },
    {
      'username': 'foodie_adventures',
      'avatar':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib-rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1964&q=80',
      'content':
          'Just tried this amazing pasta at the new Italian place downtown. Here are a few shots! Everything was delicious. Definitely worth the wait!',
      'time': '4h',
      'likes': 1256,
      'replies': 148,
      'imageUrls': [
        'https://images.unsplash.com/photo-1551183053-bf91a1d81141?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1974&q=80',
        'https://images.unsplash.com/photo-1563379926898-05f4575a457f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1974&q=80',
        'https://images.unsplash.com/photo-1595295333158-4742f28fbd85?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1974&q=80',
      ],
    },
    {
      'username': 'tech_guru',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1887&q=80',
      'content':
          'The future of AI is here. Just tried the new GPT-5 and it\'s mind blowing! What do you think about AI advancements?',
      'time': '6h',
      'likes': 2456,
      'replies': 348,
      'imageUrls': [
        'https://images.unsplash.com/photo-1620712943543-26fc76334419?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1740&q=80',
        'https://images.unsplash.com/photo-1677442136019-21780ecad995?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1887&q=80',
      ],
    },
    {
      'username': 'nature_lover',
      'avatar':
          'https://images.unsplash.com/photo-1552058544-f2b08422138a?ixlib-rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1899&q=80',
      'content':
          'Morning hike in the mountains. Nothing beats the fresh air and stunning views! 🏞️',
      'time': '8h',
      'likes': 1890,
      'replies': 132,
      'imageUrls': [],
    },
    {
      'username': 'art_exhibit',
      'avatar':
          'https://images.unsplash.com/photo-1564564321837-a57b7070ac4f?ixlib-rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1976&q=80',
      'content':
          'Visited the modern art gallery today. So many inspiring pieces.',
      'time': '1d',
      'likes': 890,
      'replies': 72,
      'imageUrls': [
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1945&q=80',
        'https://images.unsplash.com/photo-1579965342575-5fab2a4d6890?ixlib-rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1935&q=80',
        'https://images.unsplash.com/photo-1547891654-e66ed7ebb968?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
        'https://images.unsplash.com/photo-1536924940846-227afb31e2a5?ixlib-rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1944&q=80',
        'https://images.unsplash.com/photo-1506806782131-5c18c426e288?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1974&q=80',
      ],
    },
  ];

  // 将原始数据映射到你的项目的实体结构。
  return rawPosts.map((post) {
    // <-- 关键修复：安全的类型转换 -->
    // 1. 从 map 中获取 'imageUrls'，它是一个 dynamic 类型
    final imageUrlsObject = post['imageUrls'];
    // 2. 安全地创建一个新的、类型正确的 List<String>
    final List<String> imageUrls = imageUrlsObject is List
        ? List<String>.from(imageUrlsObject)
        : [];

    final mediaAttachments = imageUrls.map((url) {
      return UnifiedMediaEntity(
        id: random.nextInt(99999),
        cloudUuid: extractIdFromUrl(url),
        syncStatus: SyncStatus.synced,
        assetType: MediaType.image,
        createdAt: DateTime.now(),
        width: 800,
        height: 600,
      );
    }).toList();

    return GroupFeedItemEntity(
      id: random.nextInt(99999),
      author: FeedAuthorEntity(
        userId: random.nextInt(99999),
        username: post['username'] as String,
        avatarUrl: post['avatar'] as String,
      ),
      content: post['content'] as String,
      createdAt: parseTimeAgo(post['time'] as String),
      likesCount: post['likes'] as int,
      commentsCount: post['replies'] as int,
      mediaAttachments: mediaAttachments,
    );
  }).toList();
}
