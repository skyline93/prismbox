// lib/ui/group/widgets/feed_card/post_header.dart

import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostHeader extends StatelessWidget {
  final FeedAuthorEntity author;
  final DateTime createdAt;

  const PostHeader({super.key, required this.author, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: author.avatarUrl != null
              ? NetworkImage(author.avatarUrl!)
              : null,
          child: author.avatarUrl == null
              ? const Icon(Icons.person, size: 20)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                timeago.format(createdAt, locale: 'zh_CN'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            // TODO: Implement more options
          },
        ),
      ],
    );
  }
}
