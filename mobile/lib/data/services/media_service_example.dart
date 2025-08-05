// 媒体服务使用示例
import 'dart:io';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/data/services/remote_media_service.dart';

/// 媒体服务使用示例类
class MediaServiceExample {
  final MediaService _mediaService;

  MediaServiceExample(this._mediaService);

  /// 示例1：获取媒体列表
  Future<void> getMediaListExample() async {
    try {
      // 获取第1页，每页50条记录
      final mediaList = await _mediaService.getMediaList(
        page: 1,
        limit: 50,
      );
      
      print('获取到 ${mediaList.length} 个媒体文件');
      for (var media in mediaList) {
        print('UUID: ${media.uuid}, 文件名: ${media.filename}, 类型: ${media.itemType}');
      }
    } catch (e) {
      print('获取媒体列表失败: $e');
    }
  }

  /// 示例2：上传图片
  Future<void> uploadImageExample(String filePath) async {
    try {
      // 读取文件
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // 计算文件哈希（这里简化处理，实际应使用SHA256）
      final hash = 'dummy_hash_${DateTime.now().millisecondsSinceEpoch}';
      
      // 上传文件
      final mediaDetail = await _mediaService.uploadMedia(
        file: bytes,
        hash: hash,
        itemType: MediaType.image,
        originalFilename: file.uri.pathSegments.last,
      );
      
      print('上传成功！媒体UUID: ${mediaDetail.uuid}');
    } catch (e) {
      print('上传失败: $e');
    }
  }

  /// 示例3：上传视频
  Future<void> uploadVideoExample(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final hash = 'video_hash_${DateTime.now().millisecondsSinceEpoch}';
      
      final mediaDetail = await _mediaService.uploadMedia(
        file: bytes,
        hash: hash,
        itemType: MediaType.video,
        originalFilename: file.uri.pathSegments.last,
      );
      
      print('视频上传成功！UUID: ${mediaDetail.uuid}');
    } catch (e) {
      print('视频上传失败: $e');
    }
  }

  /// 示例4：下载缩略图
  Future<void> downloadThumbnailExample(String uuid) async {
    try {
      final thumbnailBytes = await _mediaService.downloadThumbnail(uuid);
      
      // 保存缩略图到文件
      final file = File('thumbnail_$uuid.jpg');
      await file.writeAsBytes(thumbnailBytes);
      
      print('缩略图下载成功，保存到: ${file.path}');
    } catch (e) {
      print('下载缩略图失败: $e');
    }
  }

  /// 示例5：删除媒体文件
  Future<void> deleteMediaExample(String uuid) async {
    try {
      final success = await _mediaService.deleteMedia(uuid);
      if (success) {
        print('媒体文件删除成功！UUID: $uuid');
      }
    } catch (e) {
      print('删除媒体文件失败: $e');
    }
  }

  /// 示例6：获取媒体详细信息
  Future<void> getMediaDetailExample(String uuid) async {
    try {
      final mediaDetail = await _mediaService.getMediaDetail(uuid);
      
      print('媒体详细信息:');
      print('UUID: ${mediaDetail.uuid}');
      print('文件名: ${mediaDetail.filename}');
      print('原始文件名: ${mediaDetail.originalFilename}');
      print('类型: ${mediaDetail.itemType}');
      print('大小: ${mediaDetail.fileSize} bytes');
      print('尺寸: ${mediaDetail.width}x${mediaDetail.height}');
      print('拍摄时间: ${mediaDetail.mediaTakenAt}');
      print('处理状态: ${mediaDetail.processingStatus}');
      
      if (mediaDetail.cameraMake != null) {
        print('相机: ${mediaDetail.cameraMake} ${mediaDetail.cameraModel}');
      }
      
      if (mediaDetail.latitude != null && mediaDetail.longitude != null) {
        print('位置: ${mediaDetail.latitude}, ${mediaDetail.longitude}');
      }
    } catch (e) {
      print('获取媒体详情失败: $e');
    }
  }

  /// 示例7：批量操作
  Future<void> batchOperationsExample() async {
    try {
      // 1. 获取媒体列表
      final mediaList = await _mediaService.getMediaList(page: 1, limit: 10);
      
      if (mediaList.isEmpty) {
        print('没有媒体文件');
        return;
      }
      
      // 2. 下载第一个文件的缩略图
      final firstMedia = mediaList.first;
      final thumbnail = await _mediaService.downloadThumbnail(firstMedia.uuid);
      
      // 3. 获取详细信息
      final detail = await _mediaService.getMediaDetail(firstMedia.uuid);
      
      print('批量操作完成！');
      print('处理了文件: ${detail.filename}');
      print('缩略图大小: ${thumbnail.length} bytes');
      
    } catch (e) {
      print('批量操作失败: $e');
    }
  }
}