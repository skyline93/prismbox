import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/data/models/post/post.dart';
import 'package:prismbox/data/models/post/user_simple_info.dart';

void main() {
  group('Post', () {
    test('fromJson parses group_uuid and group_name when present', () {
      final json = {
        'id': 1,
        'caption': 'test',
        'created_at': '2025-01-01T00:00:00.000Z',
        'creator': {'user_id': 1, 'username': 'u'},
        'media': [],
        'likes_count': 0,
        'comments_count': 0,
        'group_uuid': 'g-uuid-1',
        'group_name': '圈子A',
      };
      final post = Post.fromJson(json);
      expect(post.groupUuid, 'g-uuid-1');
      expect(post.groupName, '圈子A');
    });

    test('fromJson leaves groupUuid and groupName null when absent', () {
      final json = {
        'id': 1,
        'caption': 'test',
        'created_at': '2025-01-01T00:00:00.000Z',
        'creator': {'user_id': 1, 'username': 'u'},
        'media': [],
        'likes_count': 0,
        'comments_count': 0,
      };
      final post = Post.fromJson(json);
      expect(post.groupUuid, isNull);
      expect(post.groupName, isNull);
    });

    test('toJson includes group_uuid and group_name when set', () {
      final post = Post(
        id: 1,
        caption: 'c',
        createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
        creator: UserSimpleInfo(userId: 1, username: 'u'),
        media: [],
        likesCount: 0,
        commentsCount: 0,
        groupUuid: 'g-uuid',
        groupName: '圈子',
      );
      final json = post.toJson();
      expect(json['group_uuid'], 'g-uuid');
      expect(json['group_name'], '圈子');
    });
  });
}
