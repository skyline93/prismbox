// lib/platform/thumbnail_api_service.dart

import 'dart:ffi';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/platform/thumbnail_api.g.dart';

/// 原生缩略图解码服务
///
/// 封装 ThumbnailApi 调用，提供类型安全的接口，处理指针转换和错误处理
class ThumbnailApiService {
  final ThumbnailApi _api;
  static final _log = Logger('ThumbnailApiService');

  ThumbnailApiService() : _api = ThumbnailApi();

  /// 请求图片解码
  ///
  /// **参数**：
  /// - [assetId] - 资源 ID（本地资源标识符）
  /// - [width] - 目标宽度（像素）
  /// - [height] - 目标高度（像素）
  /// - [isVideo] - 是否为视频资源
  ///
  /// **返回值**：
  /// - `FrameInfo?` - 解码后的图片帧信息，如果请求被取消则返回 `null`
  ///
  /// **异常**：
  /// - 抛出 `Exception` 如果解码失败
  Future<ui.FrameInfo?> requestImage({
    required String assetId,
    required int width,
    required int height,
    required bool isVideo,
    int? requestId,
  }) async {
    final id = requestId ?? _generateRequestId();
    try {
      final info = await _api.requestImage(
        assetId,
        requestId: id,
        width: width,
        height: height,
        isVideo: isVideo,
      );

      // 空 Map 表示请求已取消
      if (info.isEmpty) {
        return null;
      }

      return _fromPlatformImage(info);
    } catch (e) {
      throw Exception('Failed to decode image for asset $assetId: $e');
    }
  }

  /// 取消图片请求
  ///
  /// **参数**：
  /// - [requestId] - 要取消的请求 ID
  void cancelImageRequest(int requestId) {
    _api.cancelImageRequest(requestId);
  }

  /// 解码 ThumbHash 为 RGBA 图片
  ///
  /// **参数**：
  /// - [thumbhash] - Base64 编码的 ThumbHash 字符串
  ///
  /// **返回值**：
  /// - `FrameInfo?` - 解码后的图片帧信息
  ///
  /// **异常**：
  /// - 抛出 `Exception` 如果解码失败
  Future<ui.FrameInfo?> getThumbhash(String thumbhash) async {
    try {
      final info = await _api.getThumbhash(thumbhash);
      return _fromPlatformImage(info);
    } catch (e) {
      throw Exception('Failed to decode thumbhash: $e');
    }
  }

  /// 请求图片解码并返回 Codec（用于 ImageProvider 系统）
  ///
  /// **参数**：
  /// - [assetId] - 资源 ID（本地资源标识符）
  /// - [width] - 目标宽度（像素）
  /// - [height] - 目标高度（像素）
  /// - [isVideo] - 是否为视频资源
  ///
  /// **返回值**：
  /// - `ui.Codec?` - 解码后的 Codec，如果请求被取消则返回 `null`
  ///
  /// **异常**：
  /// - 抛出 `Exception` 如果解码失败
  Future<ui.Codec?> requestImageCodec({
    required String assetId,
    required int width,
    required int height,
    required bool isVideo,
    int? requestId,
  }) async {
    final id = requestId ?? _generateRequestId();
    _log.info(
      'Requesting image codec: assetId=$assetId, width=$width, height=$height, isVideo=$isVideo, requestId=$id',
    );
    
    try {
      _log.fine('Calling native requestImage API...');
      final info = await _api.requestImage(
        assetId,
        requestId: id,
        width: width,
        height: height,
        isVideo: isVideo,
      );

      _log.fine('Native requestImage returned: info keys=${info.keys.toList()}, isEmpty=${info.isEmpty}');

      // 空 Map 表示请求已取消
      if (info.isEmpty) {
        _log.info('Request cancelled: assetId=$assetId');
        return null;
      }

      _log.fine('Converting platform image to Codec...');
      final codec = await _codecFromPlatformImage(info, assetId);
      _log.info('Successfully created codec: assetId=$assetId');
      return codec;
    } on PlatformException catch (e) {
      _log.severe(
        'PlatformException in requestImageCodec: assetId=$assetId, code=${e.code}, message=${e.message}, details=${e.details}',
        e,
        StackTrace.current,
      );
      throw Exception('Platform error decoding image for asset $assetId: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      _log.severe(
        'Exception in requestImageCodec: assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
      throw Exception('Failed to decode image for asset $assetId: $e');
    }
  }

  /// 将原生平台返回的图片信息转换为 Flutter Codec
  Future<ui.Codec?> _codecFromPlatformImage(Map<String, int> info, String assetId) async {
    _log.fine('_codecFromPlatformImage: assetId=$assetId, info=$info');
    
    final address = info['pointer'];
    if (address == null) {
      _log.warning('Pointer address is null: assetId=$assetId');
      return null;
    }

    _log.fine('Creating pointer from address: $address');
    final pointer = Pointer<Uint8>.fromAddress(address);

    final int actualWidth;
    final int actualHeight;
    final int actualSize;
    final ui.ImmutableBuffer buffer;
    
    try {
      actualWidth = info['width']!;
      actualHeight = info['height']!;
      actualSize = actualWidth * actualHeight * 4;
      
      _log.fine(
        'Creating ImmutableBuffer: assetId=$assetId, width=$actualWidth, height=$actualHeight, size=$actualSize bytes',
      );
      
      try {
        buffer = await ui.ImmutableBuffer.fromUint8List(
          pointer.asTypedList(actualSize),
        );
        _log.fine('ImmutableBuffer created successfully: assetId=$assetId');
      } catch (e, stackTrace) {
        _log.severe(
          'Failed to create ImmutableBuffer: assetId=$assetId, size=$actualSize, error=$e',
          e,
          stackTrace,
        );
        rethrow;
      }
    } finally {
      malloc.free(pointer);
      _log.fine('Freed native pointer: assetId=$assetId');
    }

    _log.fine('Creating ImageDescriptor: assetId=$assetId, width=$actualWidth, height=$actualHeight');
    ui.ImageDescriptor descriptor;
    try {
      descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: actualWidth,
        height: actualHeight,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      _log.fine('ImageDescriptor created successfully: assetId=$assetId');
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to create ImageDescriptor: assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
      buffer.dispose();
      rethrow;
    }
    
    _log.fine('Instantiating codec: assetId=$assetId');
    ui.Codec codec;
    try {
      codec = await descriptor.instantiateCodec();
      _log.fine('Codec instantiated successfully: assetId=$assetId');
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to instantiate codec: assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
      buffer.dispose();
      descriptor.dispose();
      rethrow;
    }

    // 注意：这里不 dispose buffer 和 descriptor，因为 Codec 可能需要它们
    // Codec 的 dispose 方法会处理这些资源的释放
    return codec;
  }

  /// 将原生平台返回的图片信息转换为 Flutter FrameInfo
  Future<ui.FrameInfo?> _fromPlatformImage(Map<String, int> info) async {
    _log.fine('_fromPlatformImage: info=$info');
    
    final address = info['pointer'];
    if (address == null) {
      _log.warning('Pointer address is null in _fromPlatformImage');
      return null;
    }

    _log.fine('Creating pointer from address: $address');
    final pointer = Pointer<Uint8>.fromAddress(address);

    final int actualWidth;
    final int actualHeight;
    final int actualSize;
    final ui.ImmutableBuffer buffer;
    
    try {
      actualWidth = info['width']!;
      actualHeight = info['height']!;
      actualSize = actualWidth * actualHeight * 4;
      
      _log.fine('Creating ImmutableBuffer: width=$actualWidth, height=$actualHeight, size=$actualSize bytes');
      
      try {
        buffer = await ui.ImmutableBuffer.fromUint8List(
          pointer.asTypedList(actualSize),
        );
        _log.fine('ImmutableBuffer created successfully');
      } catch (e, stackTrace) {
        _log.severe(
          'Failed to create ImmutableBuffer: size=$actualSize, error=$e',
          e,
          stackTrace,
        );
        rethrow;
      }
    } finally {
      malloc.free(pointer);
      _log.fine('Freed native pointer');
    }

    _log.fine('Creating ImageDescriptor: width=$actualWidth, height=$actualHeight');
    ui.ImageDescriptor descriptor;
    try {
      descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: actualWidth,
        height: actualHeight,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      _log.fine('ImageDescriptor created successfully');
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to create ImageDescriptor: error=$e',
        e,
        stackTrace,
      );
      buffer.dispose();
      rethrow;
    }
    
    _log.fine('Instantiating codec');
    ui.Codec codec;
    try {
      codec = await descriptor.instantiateCodec();
      _log.fine('Codec instantiated successfully');
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to instantiate codec: error=$e',
        e,
        stackTrace,
      );
      buffer.dispose();
      descriptor.dispose();
      rethrow;
    }

    _log.fine('Getting next frame');
    try {
      final frame = await codec.getNextFrame();
      _log.fine('Frame obtained successfully');
      return frame;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to get next frame: error=$e',
        e,
        stackTrace,
      );
      rethrow;
    } finally {
      buffer.dispose();
      descriptor.dispose();
      codec.dispose();
      _log.fine('Disposed buffer, descriptor, and codec');
    }
  }

  static int _nextRequestId = 0;
  static int _generateRequestId() => _nextRequestId++;
}
