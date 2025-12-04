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


/// tests for SharesApi
void main() {
  // final instance = SharesApi();

  group('tests for SharesApi', () {
    // 访问分享的资源
    //
    // 通过分享令牌访问分享的媒体资源，返回HTML页面（公开访问，不需要认证）
    //
    //Future sShareTokenGet(String shareToken) async
    test('test sShareTokenGet', () async {
      // TODO
    });

    // 创建分享链接
    //
    // 创建媒体分享链接，可以指定目标用户或创建公开链接（需要认证）
    //
    //Future<ResponseApiResponse> sharesPost(DtoCreateShareInput input) async
    test('test sharesPost', () async {
      // TODO
    });

    // 获取分享元数据
    //
    // 通过分享令牌获取分享的元数据信息（公开访问，不需要认证）
    //
    //Future<ResponseApiResponse> sharesShareTokenMetaGet(String shareToken) async
    test('test sharesShareTokenMetaGet', () async {
      // TODO
    });

    // 查看分享给我的内容
    //
    // 获取所有分享给当前用户的内容列表（需要认证）
    //
    //Future<ResponseApiResponse> sharesWithMeGet() async
    test('test sharesWithMeGet', () async {
      // TODO
    });

  });
}
