// lib/data/models/group/group.dart

/// 圈子数据模型（仅用于 API 响应解析）
class Group {
  final String uuid;
  final String name;
  final String? description;
  final String? coverMediaUuid;
  final int ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.uuid,
    required this.name,
    this.description,
    this.coverMediaUuid,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverMediaUuid: json['cover_media_uuid'] as String?,
      ownerId: json['owner_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'cover_media_uuid': coverMediaUuid,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

