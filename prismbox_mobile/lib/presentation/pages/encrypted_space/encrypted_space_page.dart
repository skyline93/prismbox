// lib/presentation/pages/encrypted_space/encrypted_space_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/encrypted_space/password_setup_dialog.dart';
import 'package:prismbox/presentation/widgets/media/selectable_media_grid_sliver.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';
import 'package:prismbox/services/encrypted_space/album_access_control_service.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/services/encrypted_space/session_storage_service.dart';

/// 加密空间页面
/// 显示加密空间中的照片和视频
@RoutePage()
class EncryptedSpacePage extends ConsumerStatefulWidget {
  const EncryptedSpacePage({super.key});

  @override
  ConsumerState<EncryptedSpacePage> createState() =>
      _EncryptedSpacePageState();
}

class _EncryptedSpacePageState extends ConsumerState<EncryptedSpacePage> {
  String? _albumId;
  bool _isUnlocked = false;
  bool _isLoading = true;
  bool _hasPassword = false;
  bool _isShowingDialog = false; // 防止重复显示对话框
  List<BaseAsset> _assets = []; // 加密空间的资产列表
  bool _isLoadingAssets = false; // 是否正在加载资产列表

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final database = await ref.read(databaseProvider.future);
      final apiService = ref.read(apiServiceProvider);
      final sessionStorage = SessionStorageService();
      final encryptedSpaceService = EncryptedSpaceService(
        database: database,
        apiService: apiService,
        sessionStorage: sessionStorage,
      );

      // 获取或创建加密空间相册
      final albumId = await encryptedSpaceService.getOrCreateEncryptedSpaceAlbum();
      
      // 检查是否已设置密码
      final hasPassword = await _checkPasswordSet(encryptedSpaceService, albumId);
      
      // 检查是否有有效的会话令牌
      final accessControlService = AlbumAccessControlService(
        sessionStorage: sessionStorage,
      );
      final hasValidToken = await sessionStorage.isSessionTokenValid(albumId);
      
      // 如果有有效令牌，自动解锁
      bool isUnlocked = false;
      if (hasValidToken) {
        try {
          await accessControlService.unlockAlbum(albumId, useBiometric: false);
          isUnlocked = true;
        } catch (e) {
          // 解锁失败，保持锁定状态
          isUnlocked = false;
        }
      }

      if (mounted) {
        setState(() {
          _albumId = albumId;
          _hasPassword = hasPassword;
          _isUnlocked = isUnlocked;
          _isLoading = false;
        });
        
        // setState 之后，再加载资产列表（此时 _albumId 已经设置）
        if (isUnlocked) {
          await _loadAssets();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _checkPasswordSet(
    EncryptedSpaceService service,
    String albumId,
  ) async {
    try {
      // 尝试获取会话令牌，如果存在说明已设置密码
      final sessionStorage = SessionStorageService();
      final isValid = await sessionStorage.isSessionTokenValid(albumId);
      // TODO: 更好的方式是调用API检查相册是否已设置密码
      return isValid;
    } catch (e) {
      return false;
    }
  }

  Future<bool?> _showPasswordSetupPrompt(
    EncryptedSpaceService encryptedSpaceService,
  ) async {
    if (_albumId == null) return false;

    return await PasswordSetupDialog.show(
      context,
      albumId: _albumId!,
      encryptedSpaceService: encryptedSpaceService,
    );
  }

  // 移除了 _showPasswordVerifyDialog 和 _handleUnlock 方法
  // 因为现在从合集页面进入时已经验证过了，不需要在页面内再次验证

  Future<void> _handleChangePassword() async {
    if (_albumId == null) return;

    final database = await ref.read(databaseProvider.future);
    final apiService = ref.read(apiServiceProvider);
    final sessionStorage = SessionStorageService();
    final encryptedSpaceService = EncryptedSpaceService(
      database: database,
      apiService: apiService,
      sessionStorage: sessionStorage,
    );

    await PasswordSetupDialog.show(
      context,
      albumId: _albumId!,
      encryptedSpaceService: encryptedSpaceService,
      isChangePassword: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('加密空间'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('加密空间'),
        actions: [
          if (_isUnlocked)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'change_password') {
                  _handleChangePassword();
                } else if (value == 'lock') {
                  setState(() {
                    _isUnlocked = false;
                  });
                  final sessionStorage = SessionStorageService();
                  final accessControlService = AlbumAccessControlService(
                    sessionStorage: sessionStorage,
                  );
                  if (_albumId != null) {
                    accessControlService.lockAlbum(_albumId!);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, size: 20),
                      SizedBox(width: 8),
                      Text('更改密码'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'lock',
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 20),
                      SizedBox(width: 8),
                      Text('锁定'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isUnlocked ? _buildUnlockedContent() : _buildLockedContent(),
    );
  }

  Widget _buildLockedContent() {
    // 如果有密码但未解锁，说明验证失败，显示提示信息
    // 这种情况不应该发生（因为从合集页面进入时已经验证过了）
    if (_hasPassword) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              '会话已过期',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请返回并重新验证以访问加密空间',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // 如果没有密码，显示设置密码提示
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '加密空间未设置密码',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请设置密码以保护您的私密照片和视频',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isShowingDialog ? null : _handleSetupPassword,
            icon: const Icon(Icons.lock),
            label: const Text('设置密码'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleSetupPassword() async {
    if (_albumId == null) return;
    
    // 防止重复显示对话框
    if (_isShowingDialog) return;
    
    setState(() {
      _isShowingDialog = true;
    });

    try {
      final database = await ref.read(databaseProvider.future);
      final apiService = ref.read(apiServiceProvider);
      final sessionStorage = SessionStorageService();
      final encryptedSpaceService = EncryptedSpaceService(
        database: database,
        apiService: apiService,
        sessionStorage: sessionStorage,
      );

      final result = await _showPasswordSetupPrompt(encryptedSpaceService);
      
      if (result == true && mounted) {
        setState(() {
          _hasPassword = true;
          _isShowingDialog = false;
        });
      } else if (mounted) {
        setState(() {
          _isShowingDialog = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isShowingDialog = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设置密码失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 加载加密空间的资产列表
  Future<void> _loadAssets() async {
    if (_albumId == null) return;
    
    setState(() {
      _isLoadingAssets = true;
    });

    try {
      final database = await ref.read(databaseProvider.future);
      final albumDao = database.albumDao;
      final remoteAssetDao = database.remoteAssetDao;
      
      final allAssets = <BaseAsset>[];
      
      // 1. 获取远程加密相册的资产
      try {
        final remoteAssetsData = await albumDao.getAlbumAssets(_albumId!);
        for (final data in remoteAssetsData) {
          allAssets.add(
            RemoteAsset.fromData(
              id: data.id,
              name: data.name,
              checksum: data.checksum,
              ownerId: data.ownerId,
              type: data.type,
              createdAt: data.createdAt,
              updatedAt: data.updatedAt,
              width: data.width,
              height: data.height,
              durationInSeconds: data.durationInSeconds,
              isFavorite: data.isFavorite,
              thumbHash: data.thumbHash,
              visibility: data.visibility,
              livePhotoVideoId: data.livePhotoVideoId,
              stackId: data.stackId,
            ),
          );
        }
      } catch (e) {
        // 远程资产加载失败，继续加载本地资产
        debugPrint('加载远程加密相册资产失败: $e');
      }
      
      // 2. 获取本地加密相册的资产
      try {
        final localEncryptedAlbumId = await albumDao.getOrCreateLocalEncryptedSpaceAlbum();
        final localAssetsData = await albumDao.getLocalAlbumAssets(localEncryptedAlbumId);
        
        for (final data in localAssetsData) {
          // 检查是否已有对应的远程资产（通过 checksum）
          String? remoteAssetId;
          if (data.checksum != null && data.checksum!.isNotEmpty) {
            try {
              final remoteAsset = await remoteAssetDao.getAssetByChecksum(data.checksum!);
              remoteAssetId = remoteAsset?.id;
            } catch (e) {
              // 忽略错误
            }
          }
          
          allAssets.add(
            LocalAsset.fromData(
              id: data.id,
              name: data.name,
              checksum: data.checksum,
              type: data.type,
              createdAt: data.createdAt,
              updatedAt: data.updatedAt,
              width: data.width,
              height: data.height,
              durationInSeconds: data.durationInSeconds,
              isFavorite: data.isFavorite,
              orientation: data.orientation,
              remoteAssetId: remoteAssetId,
              assetEntity: null,
            ),
          );
        }
      } catch (e) {
        // 本地资产加载失败，继续
        debugPrint('加载本地加密相册资产失败: $e');
      }
      
      // 3. 去重：如果本地资产和远程资产有相同的 checksum，只保留一个（优先保留有远程ID的）
      final assetsMap = <String, BaseAsset>{};
      for (final asset in allAssets) {
        if (asset.checksum != null && asset.checksum!.isNotEmpty) {
          final existing = assetsMap[asset.checksum!];
          if (existing == null) {
            assetsMap[asset.checksum!] = asset;
          } else {
            // 如果新资产有远程ID而现有资产没有，则替换
            if (asset.remoteId != null && existing.remoteId == null) {
              assetsMap[asset.checksum!] = asset;
            }
          }
        } else {
          // 没有 checksum 的资产直接添加（使用 ID 作为 key）
          assetsMap[asset.id] = asset;
        }
      }
      
      final assets = assetsMap.values.toList();
      
      // 4. 按创建时间倒序排列
      assets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _assets = assets;
          _isLoadingAssets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAssets = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载资产列表失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUnlockedContent() {
    if (_isLoadingAssets) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_assets.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '加密空间',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您的私密照片和视频将显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 实现添加照片到加密空间的功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('添加功能待实现'),
                ),
              );
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('添加照片'),
          ),
        ],
        ),
      );
    }

    // 显示资产网格
    final assetEntityLoaderAsync = ref.watch(assetEntityLoaderProvider);
    
    return assetEntityLoaderAsync.when(
      data: (assetEntityLoader) {
        final assetIds = _assets.map((a) => a.id).toList();
        
        return CustomScrollView(
          slivers: [
            SelectableMediaGridSliver(
              assets: _assets,
              crossAxisCount: 4,
              crossAxisSpacing: 2.0,
              mainAxisSpacing: 2.0,
              childAspectRatio: 1.0,
              assetEntityLoader: assetEntityLoader,
              selectionActive: false, // 加密空间不需要多选功能
              selectedIds: const {}, // 空集合
              onTap: (asset, index) {
                // 点击资产，导航到媒体查看器
                context.router.push(
                  MediaViewerRoute(
                    initialAssetId: asset.id,
                    assetIds: assetIds,
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

