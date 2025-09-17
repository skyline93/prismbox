// lib/ui/trash/viewmodels/trash_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

part 'trash_state.freezed.dart';

@freezed
abstract class TrashState with _$TrashState {
  const factory TrashState.loading() = _Loading;
  const factory TrashState.data({
    required List<UnifiedMediaEntity> trashedMedia,
  }) = _Data;
  const factory TrashState.error({required String error}) = _Error;
}
