// test/presentation/widgets/viewer/viewer_video_manager_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/presentation/widgets/viewer/viewer_video_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ViewerVideoManager', () {
    late ViewerVideoManager manager;

    setUp(() {
      manager = ViewerVideoManager();
    });

    // 注意：不再需要 tearDown，因为 ViewerVideoManager 不再管理 controller
    // 每个 ViewerVideoPage Widget 独立管理自己的 controller

    group('setCurrentVideoAssetId', () {
      test('应该正确设置当前视频 ID', () {
        manager.setCurrentVideoAssetId('test-id');
        expect(manager.getCurrentVideoAssetId(), equals('test-id'));
      });

      test('应该能够清除当前视频 ID', () {
        manager.setCurrentVideoAssetId('test-id');
        manager.setCurrentVideoAssetId(null);
        expect(manager.getCurrentVideoAssetId(), isNull);
      });
    });

    group('calculateVisibleIndices', () {
      test('应该正确计算可见页面索引范围', () {
        final indices = manager.calculateVisibleIndices(5, 10);
        // 当前页 ± 1，即 4, 5, 6
        expect(indices, containsAll([4, 5, 6]));
        expect(indices.length, equals(3));
      });

      test('边界情况：第一页', () {
        final indices = manager.calculateVisibleIndices(0, 10);
        // 应该只包含 0, 1
        expect(indices, containsAll([0, 1]));
        expect(indices.length, equals(2));
      });

      test('边界情况：最后一页', () {
        final indices = manager.calculateVisibleIndices(9, 10);
        // 应该只包含 8, 9
        expect(indices, containsAll([8, 9]));
        expect(indices.length, equals(2));
      });

      test('边界情况：单页', () {
        final indices = manager.calculateVisibleIndices(0, 1);
        // 应该只包含 0
        expect(indices, containsAll([0]));
        expect(indices.length, equals(1));
      });
    });

    group('updateVisibleIndices', () {
      test('应该能够更新可见页面索引', () {
        final indices = {0, 1, 2};
        expect(
          () => manager.updateVisibleIndices(indices),
          returnsNormally,
        );
      });
    });

    // 注意：getVideoSource 测试需要 mock BaseAsset 和 VideoProvider
    // 这些测试应该在集成测试中完成，或使用 mock 对象
  });
}

