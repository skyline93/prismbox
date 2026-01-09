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
    CreateGroupRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CreateGroupPage(),
      );
    },
    CreatePostRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<CreatePostRouteArgs>(
          orElse: () => CreatePostRouteArgs(
              groupUuid: pathParams.getString('groupUuid')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: CreatePostPage(
          key: args.key,
          groupUuid: args.groupUuid,
        ),
      );
    },
    FavoriteTimelineRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const FavoriteTimelinePage(),
      );
    },
    GroupDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<GroupDetailRouteArgs>(
          orElse: () => GroupDetailRouteArgs(
              groupUuid: pathParams.getString('groupUuid')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: GroupDetailPage(
          key: args.key,
          groupUuid: args.groupUuid,
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
          orElse: () => GroupMembersRouteArgs(
              groupUuid: pathParams.getString('groupUuid')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: GroupMembersPage(
          key: args.key,
          groupUuid: args.groupUuid,
        ),
      );
    },
    GroupSettingsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<GroupSettingsRouteArgs>(
          orElse: () => GroupSettingsRouteArgs(
              groupUuid: pathParams.getString('groupUuid')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: GroupSettingsPage(
          key: args.key,
          groupUuid: args.groupUuid,
        ),
      );
    },
    LanguageRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LanguagePage(),
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
    PostDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<PostDetailRouteArgs>(
          orElse: () => PostDetailRouteArgs(
                groupUuid: pathParams.getString('groupUuid'),
                postId: pathParams.getInt('postId'),
              ));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: PostDetailPage(
          key: args.key,
          groupUuid: args.groupUuid,
          postId: args.postId,
        ),
      );
    },
    PreferencesRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const PreferencesPage(),
      );
    },
    RecentlyAddedTimelineRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const RecentlyAddedTimelinePage(),
      );
    },
    RegisterRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const RegisterPage(),
      );
    },
    SettingsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SettingsPage(),
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
    TrashRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const TrashPage(),
      );
    },
    UploadDetailRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const UploadDetailPage(),
      );
    },
    VideoTimelineRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const VideoTimelinePage(),
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
/// [CreatePostPage]
class CreatePostRoute extends PageRouteInfo<CreatePostRouteArgs> {
  CreatePostRoute({
    Key? key,
    required String groupUuid,
    List<PageRouteInfo>? children,
  }) : super(
          CreatePostRoute.name,
          args: CreatePostRouteArgs(
            key: key,
            groupUuid: groupUuid,
          ),
          rawPathParams: {'groupUuid': groupUuid},
          initialChildren: children,
        );

  static const String name = 'CreatePostRoute';

  static const PageInfo<CreatePostRouteArgs> page =
      PageInfo<CreatePostRouteArgs>(name);
}

class CreatePostRouteArgs {
  const CreatePostRouteArgs({
    this.key,
    required this.groupUuid,
  });

  final Key? key;

  final String groupUuid;

  @override
  String toString() {
    return 'CreatePostRouteArgs{key: $key, groupUuid: $groupUuid}';
  }
}

/// generated route for
/// [FavoriteTimelinePage]
class FavoriteTimelineRoute extends PageRouteInfo<void> {
  const FavoriteTimelineRoute({List<PageRouteInfo>? children})
      : super(
          FavoriteTimelineRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteTimelineRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [GroupDetailPage]
class GroupDetailRoute extends PageRouteInfo<GroupDetailRouteArgs> {
  GroupDetailRoute({
    Key? key,
    required String groupUuid,
    List<PageRouteInfo>? children,
  }) : super(
          GroupDetailRoute.name,
          args: GroupDetailRouteArgs(
            key: key,
            groupUuid: groupUuid,
          ),
          rawPathParams: {'groupUuid': groupUuid},
          initialChildren: children,
        );

  static const String name = 'GroupDetailRoute';

  static const PageInfo<GroupDetailRouteArgs> page =
      PageInfo<GroupDetailRouteArgs>(name);
}

class GroupDetailRouteArgs {
  const GroupDetailRouteArgs({
    this.key,
    required this.groupUuid,
  });

  final Key? key;

  final String groupUuid;

  @override
  String toString() {
    return 'GroupDetailRouteArgs{key: $key, groupUuid: $groupUuid}';
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
    required String groupUuid,
    List<PageRouteInfo>? children,
  }) : super(
          GroupMembersRoute.name,
          args: GroupMembersRouteArgs(
            key: key,
            groupUuid: groupUuid,
          ),
          rawPathParams: {'groupUuid': groupUuid},
          initialChildren: children,
        );

  static const String name = 'GroupMembersRoute';

  static const PageInfo<GroupMembersRouteArgs> page =
      PageInfo<GroupMembersRouteArgs>(name);
}

class GroupMembersRouteArgs {
  const GroupMembersRouteArgs({
    this.key,
    required this.groupUuid,
  });

  final Key? key;

  final String groupUuid;

  @override
  String toString() {
    return 'GroupMembersRouteArgs{key: $key, groupUuid: $groupUuid}';
  }
}

/// generated route for
/// [GroupSettingsPage]
class GroupSettingsRoute extends PageRouteInfo<GroupSettingsRouteArgs> {
  GroupSettingsRoute({
    Key? key,
    required String groupUuid,
    List<PageRouteInfo>? children,
  }) : super(
          GroupSettingsRoute.name,
          args: GroupSettingsRouteArgs(
            key: key,
            groupUuid: groupUuid,
          ),
          rawPathParams: {'groupUuid': groupUuid},
          initialChildren: children,
        );

  static const String name = 'GroupSettingsRoute';

  static const PageInfo<GroupSettingsRouteArgs> page =
      PageInfo<GroupSettingsRouteArgs>(name);
}

class GroupSettingsRouteArgs {
  const GroupSettingsRouteArgs({
    this.key,
    required this.groupUuid,
  });

  final Key? key;

  final String groupUuid;

  @override
  String toString() {
    return 'GroupSettingsRouteArgs{key: $key, groupUuid: $groupUuid}';
  }
}

/// generated route for
/// [LanguagePage]
class LanguageRoute extends PageRouteInfo<void> {
  const LanguageRoute({List<PageRouteInfo>? children})
      : super(
          LanguageRoute.name,
          initialChildren: children,
        );

  static const String name = 'LanguageRoute';

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
/// [PostDetailPage]
class PostDetailRoute extends PageRouteInfo<PostDetailRouteArgs> {
  PostDetailRoute({
    Key? key,
    required String groupUuid,
    required int postId,
    List<PageRouteInfo>? children,
  }) : super(
          PostDetailRoute.name,
          args: PostDetailRouteArgs(
            key: key,
            groupUuid: groupUuid,
            postId: postId,
          ),
          rawPathParams: {
            'groupUuid': groupUuid,
            'postId': postId,
          },
          initialChildren: children,
        );

  static const String name = 'PostDetailRoute';

  static const PageInfo<PostDetailRouteArgs> page =
      PageInfo<PostDetailRouteArgs>(name);
}

class PostDetailRouteArgs {
  const PostDetailRouteArgs({
    this.key,
    required this.groupUuid,
    required this.postId,
  });

  final Key? key;

  final String groupUuid;

  final int postId;

  @override
  String toString() {
    return 'PostDetailRouteArgs{key: $key, groupUuid: $groupUuid, postId: $postId}';
  }
}

/// generated route for
/// [PreferencesPage]
class PreferencesRoute extends PageRouteInfo<void> {
  const PreferencesRoute({List<PageRouteInfo>? children})
      : super(
          PreferencesRoute.name,
          initialChildren: children,
        );

  static const String name = 'PreferencesRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [RecentlyAddedTimelinePage]
class RecentlyAddedTimelineRoute extends PageRouteInfo<void> {
  const RecentlyAddedTimelineRoute({List<PageRouteInfo>? children})
      : super(
          RecentlyAddedTimelineRoute.name,
          initialChildren: children,
        );

  static const String name = 'RecentlyAddedTimelineRoute';

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
/// [SettingsPage]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

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
/// [TrashPage]
class TrashRoute extends PageRouteInfo<void> {
  const TrashRoute({List<PageRouteInfo>? children})
      : super(
          TrashRoute.name,
          initialChildren: children,
        );

  static const String name = 'TrashRoute';

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

/// generated route for
/// [VideoTimelinePage]
class VideoTimelineRoute extends PageRouteInfo<void> {
  const VideoTimelineRoute({List<PageRouteInfo>? children})
      : super(
          VideoTimelineRoute.name,
          initialChildren: children,
        );

  static const String name = 'VideoTimelineRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
