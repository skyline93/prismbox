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


/// tests for StorageApi
void main() {
  // final instance = StorageApi();

  group('tests for StorageApi', () {
    // 列出存储池
    //
    // 获取所有存储池列表，支持按类型和状态筛选（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsGet({ String storageType, String status }) async
    test('test storagePoolsGet', () async {
      // TODO
    });

    // 创建存储池
    //
    // 创建新的存储池（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsPost(StorageCreatePoolRequest input) async
    test('test storagePoolsPost', () async {
      // TODO
    });

    // 触发存储池对账
    //
    // 触发存储池的对账操作，检查数据库记录与实际存储的一致性（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsReconcilePost({ StorageReconcileRequest input }) async
    test('test storagePoolsReconcilePost', () async {
      // TODO
    });

    // 刷新存储池缓存
    //
    // 刷新所有存储池的缓存信息（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsRefreshPost() async
    test('test storagePoolsRefreshPost', () async {
      // TODO
    });

    // 获取存储池使用情况
    //
    // 获取存储池的使用情况，包括数据库记录大小和实际存储大小的对比（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsUsageGet({ String poolUuid }) async
    test('test storagePoolsUsageGet', () async {
      // TODO
    });

    // 禁用存储池
    //
    // 禁用指定的存储池（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsUuidDisablePost(String uuid) async
    test('test storagePoolsUuidDisablePost', () async {
      // TODO
    });

    // 启用存储池
    //
    // 启用指定的存储池（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsUuidEnablePost(String uuid) async
    test('test storagePoolsUuidEnablePost', () async {
      // TODO
    });

    // 获取存储池详情
    //
    // 获取指定存储池的详细信息（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsUuidGet(String uuid) async
    test('test storagePoolsUuidGet', () async {
      // TODO
    });

    // 更新存储池
    //
    // 更新存储池的配置信息（需要认证）
    //
    //Future<ResponseApiResponse> storagePoolsUuidPatch(String uuid, StorageUpdatePoolRequest input) async
    test('test storagePoolsUuidPatch', () async {
      // TODO
    });

  });
}
