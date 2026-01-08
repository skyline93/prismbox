// lib/presentation/widgets/groups/group_info_card.dart

import 'package:flutter/material.dart';
import 'package:prismbox/data/models/group/group_detail.dart';

/// 圈子信息卡片组件
/// 用于圈子详情页面，展示圈子的详细信息
class GroupInfoCard extends StatelessWidget {
  final GroupDetail groupDetail;

  const GroupInfoCard({
    super.key,
    required this.groupDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            _buildCoverImage(context),
            const SizedBox(height: 16),
            // 名称
            Text(
              groupDetail.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // 描述
            if (groupDetail.description != null && groupDetail.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                groupDetail.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // 统计信息
            Row(
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.people_outline,
                  label: '成员',
                  value: groupDetail.memberCount.toString(),
                ),
                const SizedBox(width: 24),
                // TODO: 后续可以添加帖子数统计
                // _buildStatItem(
                //   context,
                //   icon: Icons.image_outlined,
                //   label: '帖子',
                //   value: '0',
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    // TODO: 后续可以添加封面图显示
    // 当前使用占位符
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.group,
        color: Colors.grey.shade400,
        size: 64,
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

