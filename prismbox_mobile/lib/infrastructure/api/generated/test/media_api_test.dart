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


/// tests for MediaApi
void main() {
  // final instance = MediaApi();

  group('tests for MediaApi', () {
    // 获取媒体变更
    //
    // 获取指定时间点之后的媒体变更记录（创建、更新、删除）
    //
    //Future<MediaChangesGet200Response> mediaChangesGet({ String since }) async
    test('test mediaChangesGet', () async {
      // TODO
    });

    // 检查文件哈希
    //
    // 批量检查文件哈希值，返回已存在和缺失的哈希列表（用于秒传检查）
    //
    //Future<MediaCheckHashesPost200Response> mediaCheckHashesPost(DtoCheckHashesRequest input) async
    test('test mediaCheckHashesPost', () async {
      // TODO
    });

    // 获取媒体列表
    //
    // 分页获取当前用户的媒体列表，支持按类型筛选
    //
    //Future<MediaGet200Response> mediaGet({ int page, int pageSize, String itemType }) async
    test('test mediaGet', () async {
      // TODO
    });

    // 上传媒体文件
    //
    // 上传图片或视频文件，支持秒传（通过 hash 检查）。如果文件已存在，直接返回已存在的媒体信息
    //
    //Future<MediaUuidGet200Response> mediaUploadStreamPost(MultipartFile file, String hash, String itemType, String cloudUuid, { String originalFilename, String mediaTakenAt }) async
    test('test mediaUploadStreamPost', () async {
      // TODO
    });

    // 删除媒体
    //
    // 将媒体移到回收站（软删除），可以恢复
    //
    //Future<ResponseApiResponse> mediaUuidDelete(String uuid) async
    test('test mediaUuidDelete', () async {
      // TODO
    });

    // 下载原始文件
    //
    // 下载媒体的原始文件，支持认证或签名 URL 访问
    //
    //Future mediaUuidDownloadOriginalGet(String uuid) async
    test('test mediaUuidDownloadOriginalGet', () async {
      // TODO
    });

    // 下载预览文件
    //
    // 下载媒体的预览图（压缩后的图片），支持认证或签名 URL 访问
    //
    //Future mediaUuidDownloadPreviewGet(String uuid) async
    test('test mediaUuidDownloadPreviewGet', () async {
      // TODO
    });

    // 下载缩略图
    //
    // 下载媒体的缩略图（小尺寸预览），支持认证或签名 URL 访问
    //
    //Future mediaUuidDownloadThumbnailGet(String uuid) async
    test('test mediaUuidDownloadThumbnailGet', () async {
      // TODO
    });

    // 获取媒体详情
    //
    // 获取指定媒体的详细信息，包括下载链接（需要认证）
    //
    //Future<MediaUuidGet200Response> mediaUuidGet(String uuid) async
    test('test mediaUuidGet', () async {
      // TODO
    });

    // 永久删除媒体
    //
    // 永久删除媒体（硬删除），无法恢复
    //
    //Future<ResponseApiResponse> mediaUuidPurgeDelete(String uuid) async
    test('test mediaUuidPurgeDelete', () async {
      // TODO
    });

    // 恢复媒体
    //
    // 从回收站恢复已删除的媒体
    //
    //Future<ResponseApiResponse> mediaUuidRestorePost(String uuid) async
    test('test mediaUuidRestorePost', () async {
      // TODO
    });

  });
}
