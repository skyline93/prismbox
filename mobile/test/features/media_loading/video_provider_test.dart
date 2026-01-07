// test/features/media_loading/video_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoProvider', () {
    group('getVideoSource', () {
      test('本地视频资产类型验证', () {
        // 测试资产类型判断
        final localAsset = LocalAsset(
          id: 'test-id',
          name: 'test.mp4',
          checksum: 'test-checksum',
          type: AssetType.video,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(localAsset.type, equals(AssetType.video));
        expect(localAsset.isVideo, isTrue);
      });

      test('远程视频资产类型验证', () {
        // 测试资产类型判断
        final remoteAsset = RemoteAsset(
          id: 'test-id',
          name: 'test.mp4',
          ownerId: 'test-owner',
          checksum: 'test-checksum',
          type: AssetType.video,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(remoteAsset.type, equals(AssetType.video));
        expect(remoteAsset.isVideo, isTrue);
      });

      // 注意：完整的视频源创建测试需要：
      // 1. Mock AssetEntityLoader（用于本地视频）
      // 2. Mock ApiService（用于远程视频）
      // 3. 真实的文件系统或 mock 文件系统
      // 这些测试应该在集成测试中完成
    });
  });
}

