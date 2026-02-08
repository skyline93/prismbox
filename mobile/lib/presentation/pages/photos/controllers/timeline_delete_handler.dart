// lib/presentation/pages/photos/controllers/timeline_delete_handler.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/providers/photo_filter/photo_filter_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';
import 'package:prismbox/services/trash/local_asset_delete_service.dart';
import 'package:prismbox/services/trash/remote_asset_delete_service.dart';
import 'package:prismbox/services/trash/trash_storage_service.dart';

/// 时间线删除处理器
/// 负责处理照片页面的删除操作
class TimelineDeleteHandler {
  final Logger _logger = Logger('TimelineDeleteHandler');
  final BuildContext context;
  final WidgetRef ref;
  final bool Function() mounted;

  TimelineDeleteHandler({
    required this.context,
    required this.ref,
    required this.mounted,
  });

  /// 处理删除操作
  /// 
  /// **参数**：
  /// - [selectedAssets] - 选中的资产列表
  /// 
  /// **行为**：
  /// 1. 根据当前过滤模式决定删除行为
  /// 2. 显示确认对话框
  /// 3. 执行删除操作
  /// 4. 刷新时间线数据
  Future<void> handleDelete(List<BaseAsset> selectedAssets) async {
    if (selectedAssets.isEmpty) {
      return;
    }

    // 获取当前过滤模式
    final filterMode = ref.read(photoFilterModeProvider);
    
    // 根据过滤模式决定删除行为
    final shouldDeleteLocal = filterMode == PhotoFilterModeEnum.all ||
        filterMode == PhotoFilterModeEnum.backedUp ||
        filterMode == PhotoFilterModeEnum.notBackedUp;
    final shouldDeleteRemote = filterMode == PhotoFilterModeEnum.remoteOnly;

    // 分离本地和远程资产
    final localAssets = selectedAssets.whereType<LocalAsset>().toList();
    final remoteAssets = selectedAssets.whereType<RemoteAsset>().toList();

    // 验证删除行为是否符合过滤模式
    if (shouldDeleteLocal && localAssets.isEmpty) {
      _logger.warning('过滤模式为本地，但选中的资产中没有本地资源');
      _showError('当前过滤模式下无法删除选中的资源');
      return;
    }

    if (shouldDeleteRemote && remoteAssets.isEmpty) {
      _logger.warning('过滤模式为仅云端，但选中的资产中没有远程资源');
      _showError('当前过滤模式下无法删除选中的资源');
      return;
    }

    // 显示确认对话框
    final confirmed = await _showDeleteConfirmationDialog(
      localCount: shouldDeleteLocal ? localAssets.length : 0,
      remoteCount: shouldDeleteRemote ? remoteAssets.length : 0,
    );

    if (!confirmed || !mounted()) {
      return;
    }

    // 执行删除操作
    try {
      await _performDelete(
        localAssets: shouldDeleteLocal ? localAssets : [],
        remoteAssets: shouldDeleteRemote ? remoteAssets : [],
      );

      // 刷新时间线数据
      // 同时 invalidate 依赖链上的所有 provider，确保数据完全刷新
      ref.invalidate(timelineAssetsProvider());
      ref.invalidate(timelineSectionsProvider);

      // 显示成功提示并退出选择模式
      if (mounted()) {
        ref.read(assetSelectionProvider.notifier).deactivate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('删除操作失败', e, stackTrace);
      if (mounted()) {
        _showError('删除失败: ${e.toString()}');
      }
    }
  }

  /// 执行删除操作
  Future<void> _performDelete({
    required List<LocalAsset> localAssets,
    required List<RemoteAsset> remoteAssets,
  }) async {
    final database = await DatabaseConnection.getInstance();
    final apiService = ApiService();
    final trashStorage = TrashStorageService();

    // 删除本地资源
    if (localAssets.isNotEmpty) {
      final localDao = LocalAssetDao(database);
      final localDeleteService = LocalAssetDeleteService(
        dao: localDao,
        trashStorage: trashStorage,
      );

      final localIds = localAssets.map((a) => a.id).toList();
      await localDeleteService.softDeleteAssets(localIds);
    }

    // 删除远程资源
    if (remoteAssets.isNotEmpty) {
      final remoteDao = RemoteAssetDao(database);
      final remoteDeleteService = RemoteAssetDeleteService(
        dao: remoteDao,
        apiService: apiService,
      );

      final remoteIds = remoteAssets.map((a) => a.id).toList();
      await remoteDeleteService.softDeleteAssets(remoteIds);
    }
  }

  /// 显示删除确认对话框
  Future<bool> _showDeleteConfirmationDialog({
    required int localCount,
    required int remoteCount,
  }) async {
    final totalCount = localCount + remoteCount;
    final message = totalCount == 1
        ? '确定要删除这个资源吗？删除后可以在回收站中恢复。'
        : '确定要删除这 $totalCount 个资源吗？删除后可以在回收站中恢复。';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

