// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/domain/entities/user_profile_entity.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
class UserProfileModel with _$UserProfileModel {
  const UserProfileModel._();

  const factory UserProfileModel({
    required int id,
    required String username,
    required String email,
    @JsonKey(name: 'has_password') required bool hasPassword,

    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'used_storage') required double usedStorage,
    @JsonKey(name: 'total_storage') required double totalStorage,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  UserProfileEntity toEntity() {
    return UserProfileEntity(
      id: id,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      usedStorage: usedStorage,
      totalStorage: totalStorage,
    );
  }
}
