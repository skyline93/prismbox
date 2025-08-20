// lib/ui/gallery/pages/gallery_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/ui/gallery/viewmodels/gallery_viewmodel.dart';
import 'package:mobile/ui/gallery/pages/gallery_item_page.dart';

@RoutePage()
class GalleryPage extends HookConsumerWidget {
  final List<UnifiedMediaEntity> media;
  final int initialIndex;

  const GalleryPage({
    super.key,
    required this.media,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController(initialPage: initialIndex);
    final currentIndex = useState(initialIndex);
    final currentEntity = media[currentIndex.value];

    useEffect(() {
      void listener() {
        final newIndex = pageController.page?.round() ?? initialIndex;
        if (newIndex != currentIndex.value) {
          currentIndex.value = newIndex;
          _precacheAdjacent(ref, newIndex);
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _initialLoad(ref, initialIndex);
        }
      });

      pageController.addListener(listener);
      return () => pageController.removeListener(listener);
    }, [pageController]);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
        ),
        actions: [_buildAppBarActions(context, ref, currentEntity)],
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: media.length,
        itemBuilder: (context, index) {
          return GalleryItemPage(entity: media[index]);
        },
      ),
    );
  }

  void _initialLoad(WidgetRef ref, int index) {
    _precacheEntity(ref, media[index]);
    _precacheAdjacent(ref, index);
  }

  void _precacheAdjacent(WidgetRef ref, int index) {
    if (index + 1 < media.length) {
      _precacheEntity(ref, media[index + 1]);
    }
    if (index - 1 >= 0) {
      _precacheEntity(ref, media[index - 1]);
    }
  }

  void _precacheEntity(WidgetRef ref, UnifiedMediaEntity entity) {
    if (entity.isVideo) return;

    // ignore: body_might_complete_normally_catch_error
    ref.read(mediaDetailProvider(entity).future).catchError((_) {});
  }

  Widget _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    UnifiedMediaEntity entity,
  ) {
    final mediaState = ref.watch(mediaDetailProvider(entity));

    if (mediaState.isLoading && !mediaState.isRefreshing) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    switch (entity.syncStatus) {
      case SyncStatus.cloudOnly:
        return IconButton(
          icon: const Icon(Icons.cloud_download_outlined),
          tooltip: '下载到设备',
          onPressed: () =>
              ref.read(mediaDetailProvider(entity).notifier).download(),
        );
      case SyncStatus.localOnlyNotSelected:
        return IconButton(
          icon: const Icon(Icons.cloud_upload_outlined),
          tooltip: '上传到云端',
          onPressed: () =>
              ref.read(mediaDetailProvider(entity).notifier).upload(),
        );
      case SyncStatus.synced:
        return const IconButton(
          icon: Icon(Icons.cloud_done),
          tooltip: '已同步',
          onPressed: null,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
