//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:prismbox/infrastructure/api/generated/lib/api.dart';
import 'package:test/test.dart';


/// tests for AuthApi
void main() {
  // final instance = AuthApi();

  group('tests for AuthApi', () {
    // Apple 登录
    //
    // 使用 Apple ID 登录，返回访问令牌和刷新令牌
    //
    //Future<AuthAppleLoginPost200Response> authAppleLoginPost(AuthAppleLoginInput input) async
    test('test authAppleLoginPost', () async {
      // TODO
    });

    // 上传头像
    //
    // 上传用户头像图片（需要认证），支持 jpg、jpeg、png 格式，最大 5MB
    //
    //Future<AuthAvatarPost200Response> authAvatarPost(MultipartFile avatar) async
    test('test authAvatarPost', () async {
      // TODO
    });

    // 用户登录
    //
    // 使用邮箱和密码登录，返回访问令牌和刷新令牌
    //
    //Future<AuthAppleLoginPost200Response> authLoginPost(AuthLoginInput input) async
    test('test authLoginPost', () async {
      // TODO
    });

    // 用户登出
    //
    // 撤销刷新令牌，登出用户
    //
    //Future<ResponseApiResponse> authLogoutPost(AuthLogoutInput input) async
    test('test authLogoutPost', () async {
      // TODO
    });

    // 设置密码
    //
    // 为用户账号设置密码（需要认证）
    //
    //Future authPasswordSetPost(AuthSetPasswordInput input) async
    test('test authPasswordSetPost', () async {
      // TODO
    });

    // 获取用户资料
    //
    // 获取当前登录用户的资料信息（需要认证）
    //
    //Future<ResponseApiResponse> authProfileGet() async
    test('test authProfileGet', () async {
      // TODO
    });

    // 刷新访问令牌
    //
    // 使用刷新令牌获取新的访问令牌
    //
    //Future<AuthRefreshPost200Response> authRefreshPost(AuthRefreshTokenInput input) async
    test('test authRefreshPost', () async {
      // TODO
    });

    // 用户注册
    //
    // 创建新用户账号，需要提供用户名、邮箱和密码
    //
    //Future<AuthRegisterPost200Response> authRegisterPost(InternalApiV1AuthRegisterInput input) async
    test('test authRegisterPost', () async {
      // TODO
    });

  });
}
