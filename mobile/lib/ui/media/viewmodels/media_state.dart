import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

part 'media_state.freezed.dart';

@freezed
class MediaState with _$MediaState {
  const factory MediaState.loading() = _Loading;
  const factory MediaState.data({required List<UnifiedMediaEntity> media}) =
      _Data;
  const factory MediaState.error({required String error}) = _Error;
}
