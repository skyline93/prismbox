import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/features/remote_sync/providers/remote_sync_providers.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';

/// 时间线事件监听管理器
///
/// 负责管理所有与时间线相关的 Stream 事件监听，包括：
/// - 数据源切换监听
/// - 上传完成监听
/// - 远程同步完成监听
class TimelineEventListeners {
  final WidgetRef ref;
  final bool Function() mounted;

  StreamSubscription<bool>? _dataSourceSwitchSubscription;
  StreamSubscription<String>? _uploadCompleteSubscription;
  StreamSubscription? _remoteSyncCompleteSubscription;

  TimelineEventListeners({
    required this.ref,
    required this.mounted,
  });

  /// 启动所有监听
  void start() {
    _listenDataSourceSwitch();
    _listenUploadComplete();
    _listenRemoteSyncComplete();
  }

  /// 清理所有订阅
  void dispose() {
    _dataSourceSwitchSubscription?.cancel();
    _uploadCompleteSubscription?.cancel();
    _remoteSyncCompleteSubscription?.cancel();
  }

  /// 监听数据源切换通知
  /// 当同步完成后，如果数据库数据可用，会自动切换到数据库数据源
  void _listenDataSourceSwitch() {
    ref
        .read(syncCoordinatorProvider.future)
        .then((coordinator) {
          debugPrint('✅ 数据源切换监听已启动');
          _dataSourceSwitchSubscription = coordinator.dataSourceSwitchStream
              .listen(
                (shouldSwitch) {
                  if (shouldSwitch && mounted()) {
                    debugPrint('✅ 收到数据源切换通知，刷新时间线数据');
                    // 刷新时间线数据，触发数据源切换
                    ref.invalidate(timelineSectionsProvider);
                    // 可选：显示提示信息（静默切换，不打扰用户）
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     content: Text('数据已同步完成'),
                    //     duration: Duration(seconds: 2),
                    //   ),
                    // );
                  }
                },
                onError: (error) {
                  // 记录错误但不影响功能
                  debugPrint('❌ 数据源切换监听错误: $error');
                },
              );
        })
        .catchError((error) {
          debugPrint('❌ 启动数据源切换监听失败: $error');
        });
  }

  /// 监听上传完成通知
  /// 当资产上传成功并更新数据库后，刷新时间线数据以更新上传状态图标
  void _listenUploadComplete() {
    ref
        .read(uploadOrchestratorProvider.future)
        .then((orchestrator) {
          debugPrint('✅ 上传完成监听已启动');
          _uploadCompleteSubscription = orchestrator.uploadCompleteStream.listen(
            (assetId) async {
              if (mounted()) {
                debugPrint('✅ 收到上传完成通知: assetId=$assetId，刷新时间线数据');
                // 短暂延迟，确保数据库事务已提交
                await Future.delayed(const Duration(milliseconds: 200));
                if (mounted()) {
                  // 同时 invalidate timelineAssetsProvider 和 timelineSectionsProvider
                  // 确保数据完全刷新
                  ref.invalidate(timelineAssetsProvider());
                  ref.invalidate(timelineSectionsProvider);
                  debugPrint('✅ 已刷新时间线数据');
                }
              }
            },
            onError: (error) {
              // 记录错误但不影响功能
              debugPrint('❌ 上传完成监听错误: $error');
            },
          );
        })
        .catchError((error) {
          debugPrint('❌ 启动上传完成监听失败: $error');
        });
  }

  /// 监听远程同步完成通知
  /// 当远程同步完成后，刷新时间线数据以更新上传状态图标
  void _listenRemoteSyncComplete() {
    ref
        .read(remoteSyncCoordinatorProvider.future)
        .then((coordinator) {
          debugPrint('✅ 远程同步完成监听已启动');
          _remoteSyncCompleteSubscription = coordinator.remoteSyncCompleteStream
              .listen(
                (result) async {
                  if (mounted() && result.addedCount > 0) {
                    debugPrint(
                      '✅ 收到远程同步完成通知: 新增 ${result.addedCount} 个资产，刷新时间线数据',
                    );
                    // 短暂延迟，确保数据库事务已提交
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (mounted()) {
                      // 刷新时间线数据，确保 LocalAsset 对象获取到最新的 remoteAssetId
                      ref.invalidate(timelineAssetsProvider());
                      ref.invalidate(timelineSectionsProvider);
                      debugPrint('✅ 已刷新时间线数据');
                    }
                  }
                },
                onError: (error) {
                  // 记录错误但不影响功能
                  debugPrint('❌ 远程同步完成监听错误: $error');
                },
              );
        })
        .catchError((error) {
          debugPrint('❌ 启动远程同步完成监听失败: $error');
        });
  }

}

