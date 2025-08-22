// lib/domain/entities/unified_album_entity.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';

part 'unified_album_entity.freezed.dart';

@freezed
class UnifiedAlbumEntity with _$UnifiedAlbumEntity {
  const factory UnifiedAlbumEntity({
    required String id,
    required String name,
    required int assetCount,
    required AlbumSource source,
    String? thumbnailId,
  }) = _UnifiedAlbumEntity;
}
