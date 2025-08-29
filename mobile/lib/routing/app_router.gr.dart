// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint, unused_element_parameter
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    AlbumDetailRoute.name: (routeData) {
      final args = routeData.argsAs<AlbumDetailRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: AlbumDetailPage(
          key: args.key,
          albumId: args.albumId,
          albumSource: args.albumSource,
          albumName: args.albumName,
        ),
      );
    },
    AlbumRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AlbumPage(),
      );
    },
    CreateGroupRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CreateGroupPage(),
      );
    },
    GalleryRoute.name: (routeData) {
      final args = routeData.argsAs<GalleryRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: GalleryPage(
          key: args.key,
          media: args.media,
          initialIndex: args.initialIndex,
        ),
      );
    },
    GroupFeedRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<GroupFeedRouteArgs>(
          orElse: () => GroupFeedRouteArgs(uuid: pathParams.getString('uuid')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: GroupFeedPage(
          key: args.key,
          uuid: args.uuid,
        ),
      );
    },
    GroupListRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const GroupListPage(),
      );
    },
    GroupMembersRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<GroupMembersRouteArgs>(
          orElse: () =>
              GroupMembersRouteArgs(uuid: pathParams.getString('uuid')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: GroupMembersPage(
          key: args.key,
          uuid: args.uuid,
        ),
      );
    },
    GroupSettingsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<GroupSettingsRouteArgs>(
          orElse: () =>
              GroupSettingsRouteArgs(uuid: pathParams.getString('uuid')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: GroupSettingsPage(
          key: args.key,
          uuid: args.uuid,
        ),
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
    MediaItemRoute.name: (routeData) {
      final args = routeData.argsAs<MediaItemRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: MediaItemPage(
          key: args.key,
          groupMedia: args.groupMedia,
        ),
      );
    },
    MediaRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const MediaPage(),
      );
    },
    NavigationRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const NavigationPage(),
      );
    },
    ServerConfigRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ServerConfigPage(),
      );
    },
    SplashRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SplashPage(),
      );
    },
  };
}

/// generated route for
/// [AlbumDetailPage]
class AlbumDetailRoute extends PageRouteInfo<AlbumDetailRouteArgs> {
  AlbumDetailRoute({
    Key? key,
    required String albumId,
    required AlbumSource albumSource,
    required String albumName,
    List<PageRouteInfo>? children,
  }) : super(
          AlbumDetailRoute.name,
          args: AlbumDetailRouteArgs(
            key: key,
            albumId: albumId,
            albumSource: albumSource,
            albumName: albumName,
          ),
          initialChildren: children,
        );

  static const String name = 'AlbumDetailRoute';

  static const PageInfo<AlbumDetailRouteArgs> page =
      PageInfo<AlbumDetailRouteArgs>(name);
}

class AlbumDetailRouteArgs {
  const AlbumDetailRouteArgs({
    this.key,
    required this.albumId,
    required this.albumSource,
    required this.albumName,
  });

  final Key? key;

  final String albumId;

  final AlbumSource albumSource;

  final String albumName;

  @override
  String toString() {
    return 'AlbumDetailRouteArgs{key: $key, albumId: $albumId, albumSource: $albumSource, albumName: $albumName}';
  }
}

/// generated route for
/// [AlbumPage]
class AlbumRoute extends PageRouteInfo<void> {
  const AlbumRoute({List<PageRouteInfo>? children})
      : super(
          AlbumRoute.name,
          initialChildren: children,
        );

  static const String name = 'AlbumRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CreateGroupPage]
class CreateGroupRoute extends PageRouteInfo<void> {
  const CreateGroupRoute({List<PageRouteInfo>? children})
      : super(
          CreateGroupRoute.name,
          initialChildren: children,
        );

  static const String name = 'CreateGroupRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [GalleryPage]
class GalleryRoute extends PageRouteInfo<GalleryRouteArgs> {
  GalleryRoute({
    Key? key,
    required List<UnifiedMediaEntity> media,
    required int initialIndex,
    List<PageRouteInfo>? children,
  }) : super(
          GalleryRoute.name,
          args: GalleryRouteArgs(
            key: key,
            media: media,
            initialIndex: initialIndex,
          ),
          initialChildren: children,
        );

  static const String name = 'GalleryRoute';

  static const PageInfo<GalleryRouteArgs> page =
      PageInfo<GalleryRouteArgs>(name);
}

class GalleryRouteArgs {
  const GalleryRouteArgs({
    this.key,
    required this.media,
    required this.initialIndex,
  });

  final Key? key;

  final List<UnifiedMediaEntity> media;

  final int initialIndex;

  @override
  String toString() {
    return 'GalleryRouteArgs{key: $key, media: $media, initialIndex: $initialIndex}';
  }
}

/// generated route for
/// [GroupFeedPage]
class GroupFeedRoute extends PageRouteInfo<GroupFeedRouteArgs> {
  GroupFeedRoute({
    Key? key,
    required String uuid,
    List<PageRouteInfo>? children,
  }) : super(
          GroupFeedRoute.name,
          args: GroupFeedRouteArgs(
            key: key,
            uuid: uuid,
          ),
          rawPathParams: {'uuid': uuid},
          initialChildren: children,
        );

  static const String name = 'GroupFeedRoute';

  static const PageInfo<GroupFeedRouteArgs> page =
      PageInfo<GroupFeedRouteArgs>(name);
}

class GroupFeedRouteArgs {
  const GroupFeedRouteArgs({
    this.key,
    required this.uuid,
  });

  final Key? key;

  final String uuid;

  @override
  String toString() {
    return 'GroupFeedRouteArgs{key: $key, uuid: $uuid}';
  }
}

/// generated route for
/// [GroupListPage]
class GroupListRoute extends PageRouteInfo<void> {
  const GroupListRoute({List<PageRouteInfo>? children})
      : super(
          GroupListRoute.name,
          initialChildren: children,
        );

  static const String name = 'GroupListRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [GroupMembersPage]
class GroupMembersRoute extends PageRouteInfo<GroupMembersRouteArgs> {
  GroupMembersRoute({
    Key? key,
    required String uuid,
    List<PageRouteInfo>? children,
  }) : super(
          GroupMembersRoute.name,
          args: GroupMembersRouteArgs(
            key: key,
            uuid: uuid,
          ),
          rawPathParams: {'uuid': uuid},
          initialChildren: children,
        );

  static const String name = 'GroupMembersRoute';

  static const PageInfo<GroupMembersRouteArgs> page =
      PageInfo<GroupMembersRouteArgs>(name);
}

class GroupMembersRouteArgs {
  const GroupMembersRouteArgs({
    this.key,
    required this.uuid,
  });

  final Key? key;

  final String uuid;

  @override
  String toString() {
    return 'GroupMembersRouteArgs{key: $key, uuid: $uuid}';
  }
}

/// generated route for
/// [GroupSettingsPage]
class GroupSettingsRoute extends PageRouteInfo<GroupSettingsRouteArgs> {
  GroupSettingsRoute({
    Key? key,
    required String uuid,
    List<PageRouteInfo>? children,
  }) : super(
          GroupSettingsRoute.name,
          args: GroupSettingsRouteArgs(
            key: key,
            uuid: uuid,
          ),
          rawPathParams: {'uuid': uuid},
          initialChildren: children,
        );

  static const String name = 'GroupSettingsRoute';

  static const PageInfo<GroupSettingsRouteArgs> page =
      PageInfo<GroupSettingsRouteArgs>(name);
}

class GroupSettingsRouteArgs {
  const GroupSettingsRouteArgs({
    this.key,
    required this.uuid,
  });

  final Key? key;

  final String uuid;

  @override
  String toString() {
    return 'GroupSettingsRouteArgs{key: $key, uuid: $uuid}';
  }
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
/// [MediaItemPage]
class MediaItemRoute extends PageRouteInfo<MediaItemRouteArgs> {
  MediaItemRoute({
    Key? key,
    required GroupMediaModel groupMedia,
    List<PageRouteInfo>? children,
  }) : super(
          MediaItemRoute.name,
          args: MediaItemRouteArgs(
            key: key,
            groupMedia: groupMedia,
          ),
          initialChildren: children,
        );

  static const String name = 'MediaItemRoute';

  static const PageInfo<MediaItemRouteArgs> page =
      PageInfo<MediaItemRouteArgs>(name);
}

class MediaItemRouteArgs {
  const MediaItemRouteArgs({
    this.key,
    required this.groupMedia,
  });

  final Key? key;

  final GroupMediaModel groupMedia;

  @override
  String toString() {
    return 'MediaItemRouteArgs{key: $key, groupMedia: $groupMedia}';
  }
}

/// generated route for
/// [MediaPage]
class MediaRoute extends PageRouteInfo<void> {
  const MediaRoute({List<PageRouteInfo>? children})
      : super(
          MediaRoute.name,
          initialChildren: children,
        );

  static const String name = 'MediaRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [NavigationPage]
class NavigationRoute extends PageRouteInfo<void> {
  const NavigationRoute({List<PageRouteInfo>? children})
      : super(
          NavigationRoute.name,
          initialChildren: children,
        );

  static const String name = 'NavigationRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ServerConfigPage]
class ServerConfigRoute extends PageRouteInfo<void> {
  const ServerConfigRoute({List<PageRouteInfo>? children})
      : super(
          ServerConfigRoute.name,
          initialChildren: children,
        );

  static const String name = 'ServerConfigRoute';

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
