// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element, unused_element_parameter
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    AlbumsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AlbumsPage(),
      );
    },
    BackupManagementRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const BackupManagementPage(),
      );
    },
    BackupSettingsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const BackupSettingsPage(),
      );
    },
    LibraryRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LibraryPage(),
      );
    },
    LoginRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LoginPage(),
      );
    },
    MainTimelineRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const MainTimelinePage(),
      );
    },
    MediaViewerRoute.name: (routeData) {
      final args = routeData.argsAs<MediaViewerRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: MediaViewerPage(
          key: args.key,
          initialAssetId: args.initialAssetId,
          assetIds: args.assetIds,
        ),
      );
    },
    PermissionRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const PermissionPage(),
      );
    },
    RegisterRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const RegisterPage(),
      );
    },
    SearchRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SearchPage(),
      );
    },
    SplashRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SplashPage(),
      );
    },
    TabShellRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const TabShellPage(),
      );
    },
    UploadDetailRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const UploadDetailPage(),
      );
    },
  };
}

/// generated route for
/// [AlbumsPage]
class AlbumsRoute extends PageRouteInfo<void> {
  const AlbumsRoute({List<PageRouteInfo>? children})
      : super(
          AlbumsRoute.name,
          initialChildren: children,
        );

  static const String name = 'AlbumsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [BackupManagementPage]
class BackupManagementRoute extends PageRouteInfo<void> {
  const BackupManagementRoute({List<PageRouteInfo>? children})
      : super(
          BackupManagementRoute.name,
          initialChildren: children,
        );

  static const String name = 'BackupManagementRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [BackupSettingsPage]
class BackupSettingsRoute extends PageRouteInfo<void> {
  const BackupSettingsRoute({List<PageRouteInfo>? children})
      : super(
          BackupSettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'BackupSettingsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LibraryPage]
class LibraryRoute extends PageRouteInfo<void> {
  const LibraryRoute({List<PageRouteInfo>? children})
      : super(
          LibraryRoute.name,
          initialChildren: children,
        );

  static const String name = 'LibraryRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [MainTimelinePage]
class MainTimelineRoute extends PageRouteInfo<void> {
  const MainTimelineRoute({List<PageRouteInfo>? children})
      : super(
          MainTimelineRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainTimelineRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [MediaViewerPage]
class MediaViewerRoute extends PageRouteInfo<MediaViewerRouteArgs> {
  MediaViewerRoute({
    Key? key,
    required String initialAssetId,
    required List<String> assetIds,
    List<PageRouteInfo>? children,
  }) : super(
          MediaViewerRoute.name,
          args: MediaViewerRouteArgs(
            key: key,
            initialAssetId: initialAssetId,
            assetIds: assetIds,
          ),
          initialChildren: children,
        );

  static const String name = 'MediaViewerRoute';

  static const PageInfo<MediaViewerRouteArgs> page =
      PageInfo<MediaViewerRouteArgs>(name);
}

class MediaViewerRouteArgs {
  const MediaViewerRouteArgs({
    this.key,
    required this.initialAssetId,
    required this.assetIds,
  });

  final Key? key;

  final String initialAssetId;

  final List<String> assetIds;

  @override
  String toString() {
    return 'MediaViewerRouteArgs{key: $key, initialAssetId: $initialAssetId, assetIds: $assetIds}';
  }
}

/// generated route for
/// [PermissionPage]
class PermissionRoute extends PageRouteInfo<void> {
  const PermissionRoute({List<PageRouteInfo>? children})
      : super(
          PermissionRoute.name,
          initialChildren: children,
        );

  static const String name = 'PermissionRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [RegisterPage]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SearchPage]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SplashPage]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [TabShellPage]
class TabShellRoute extends PageRouteInfo<void> {
  const TabShellRoute({List<PageRouteInfo>? children})
      : super(
          TabShellRoute.name,
          initialChildren: children,
        );

  static const String name = 'TabShellRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [UploadDetailPage]
class UploadDetailRoute extends PageRouteInfo<void> {
  const UploadDetailRoute({List<PageRouteInfo>? children})
      : super(
          UploadDetailRoute.name,
          initialChildren: children,
        );

  static const String name = 'UploadDetailRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
