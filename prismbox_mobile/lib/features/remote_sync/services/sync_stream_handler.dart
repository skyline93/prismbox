// lib/features/remote_sync/services/sync_stream_handler.dart

import 'dart:convert';
import 'package:logging/logging.dart';

/// 同步实体类型枚举
enum SyncEntityType {
  assetV1,
  syncCompleteV1,
  syncResetV1,
  assetDeleteV1,
  unknown;

  static SyncEntityType fromString(String type) {
    switch (type) {
      case 'asset_v1':
        return SyncEntityType.assetV1;
      case 'sync_complete_v1':
        return SyncEntityType.syncCompleteV1;
      case 'sync_reset_v1':
        return SyncEntityType.syncResetV1;
      case 'asset_delete_v1':
        return SyncEntityType.assetDeleteV1;
      default:
        return SyncEntityType.unknown;
    }
  }
}

/// 同步事件
class SyncEvent {
  final SyncEntityType type;
  final List<String> ids;
  final Map<String, dynamic> data;
  final String? ack;

  SyncEvent({
    required this.type,
    required this.ids,
    required this.data,
    this.ack,
  });
}

/// 流式同步处理器
/// 负责解析 JSON Lines 格式的流式数据
class SyncStreamHandler {
  final Logger _logger = Logger('SyncStreamHandler');
  final StringBuffer _buffer = StringBuffer();

  /// 解析一行 JSON 数据
  SyncEvent? parseLine(String line) {
    try {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      final typeStr = json['type'] as String? ?? '';
      final ids = (json['ids'] as List?)?.cast<String>() ?? [];
      // data 可能是数组（批量数据）或对象（单个数据或空对象）
      // 根据后端实现，对于 asset_v1 类型，data 是数组
      final data = json['data'];
      final ack = json['ack'] as String?;

      // 将 data 转换为统一的 Map 格式，便于后续处理
      // 如果是数组，包装在 'data' 键下；如果是对象，直接使用
      final dataMap = <String, dynamic>{};
      if (data is List) {
        dataMap['data'] = data;
      } else if (data is Map) {
        dataMap.addAll(data as Map<String, dynamic>);
      } else {
        // 空数据或其他类型
        dataMap['data'] = data;
      }

      return SyncEvent(
        type: SyncEntityType.fromString(typeStr),
        ids: ids,
        data: dataMap,
        ack: ack,
      );
    } catch (e, stackTrace) {
      _logger.warning('解析同步事件失败: $line', e, stackTrace);
      return null;
    }
  }

  /// 处理流式数据块
  /// 返回解析出的事件列表
  List<SyncEvent> processChunk(String chunk) {
    final events = <SyncEvent>[];
    
    // 将新数据添加到缓冲区
    _buffer.write(chunk);
    
    // 按行分割并处理
    final content = _buffer.toString();
    final lines = content.split('\n');
    
    // 保留最后一行（可能不完整）
    if (lines.isNotEmpty) {
      _buffer.clear();
      _buffer.write(lines.last);
      
      // 处理完整的行
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i];
        if (line.trim().isNotEmpty) {
          final event = parseLine(line);
          if (event != null) {
            events.add(event);
          }
        }
      }
    }
    
    return events;
  }

  /// 清空缓冲区
  void clear() {
    _buffer.clear();
  }
}

