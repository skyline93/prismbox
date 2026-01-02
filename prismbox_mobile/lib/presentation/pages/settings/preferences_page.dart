// lib/presentation/pages/settings/preferences_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/services/encrypted_space/album_access_control_service.dart';
import 'package:prismbox/services/biometric/biometric_auth_service.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/services/encrypted_space/session_storage_service.dart';
import 'package:prismbox/presentation/widgets/encrypted_space/password_verification_dialog.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart';

/// 偏好设置页面
@RoutePage()
class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  String _selectedThemeColor = 'blue';
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  int _lockTimeoutMinutes = 30;
  String? _encryptedSpaceAlbumId;
  EncryptedSpaceService? _encryptedSpaceService;
  AlbumAccessControlService? _albumAccessControlService;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeEncryptedSpace();
  }

  /// 初始化加密空间服务
  Future<void> _initializeEncryptedSpace() async {
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

      if (mounted) {
        setState(() {
          _encryptedSpaceAlbumId = albumId;
          _encryptedSpaceService = encryptedSpaceService;
        });
      }
    } catch (e) {
      // 初始化失败不影响页面显示
      // 在需要使用时再处理错误
    }
  }

  Future<void> _loadSettings() async {
    _loadThemeColor();
    await _loadBiometricSettings();
    _loadLockTimeoutSettings();
  }

  void _loadThemeColor() {
    setState(() {
      _selectedThemeColor = AppSetting.get(Setting.themeColor);
    });
  }

  Future<void> _loadBiometricSettings() async {
    setState(() {
      _biometricEnabled = AppSetting.get(Setting.encryptedSpaceBiometricEnabled);
    });
    
    // 检查设备是否支持生物识别
    try {
      final biometricAuthService = BiometricAuthService();
      final supported = await biometricAuthService.isDeviceSupported();
      if (mounted) {
        setState(() {
          _biometricSupported = supported;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _biometricSupported = false;
        });
      }
    }
  }

  void _loadLockTimeoutSettings() {
    setState(() {
      _lockTimeoutMinutes = AppSetting.get(Setting.encryptedSpaceLockTimeoutMinutes);
    });
  }

  /// 初始化访问控制服务
  Future<void> _initializeAccessControlService() async {
    if (_albumAccessControlService == null) {
      final sessionStorage = SessionStorageService();
      _albumAccessControlService = AlbumAccessControlService(
        sessionStorage: sessionStorage,
      );
    }
  }

  /// 处理超时时间变更
  Future<void> _onLockTimeoutChanged(int minutes) async {
    await _initializeAccessControlService();
    
    // 保存到 AppSetting
    await AppSetting.set(Setting.encryptedSpaceLockTimeoutMinutes, minutes);
    
    // 更新访问控制服务
    if (_albumAccessControlService != null) {
      await _albumAccessControlService!.setUserConfiguredTimeout(minutes);
    }
    
    if (mounted) {
      setState(() {
        _lockTimeoutMinutes = minutes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            minutes == 0 
              ? '已设置为永不自动锁定' 
              : '自动锁定超时时间已设置为 ${minutes} 分钟',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onBiometricEnabledChanged(bool value) async {
    // 1. 如果开启生物识别
    if (value) {
      // 1.1 检查设备支持
      if (!_biometricSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('您的设备不支持生物识别'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 1.2 验证密码
      final passwordVerified = await _verifyPasswordForEnable();
      if (!passwordVerified) {
        // 用户取消或验证失败，不更新开关
        return;
      }

      // 1.3 检查生物识别可用性（不更新UI状态，避免闪烁）
      bool available = false;
      try {
        final biometricAuthService = BiometricAuthService();
        available = await biometricAuthService.canCheckBiometrics();
        if (!available) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('未检测到可用的生物识别方法，请先在系统设置中配置'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('检查生物识别失败: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 1.4 所有验证通过，保存设置（一次性更新UI，避免闪烁）
      await AppSetting.set(Setting.encryptedSpaceBiometricEnabled, true);
      if (mounted) {
        setState(() {
          _biometricEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已启用生物识别解锁'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } 
    // 2. 如果关闭生物识别
    else {
      // 2.1 进行生物识别验证
      final biometricVerified = await _verifyBiometricForDisable();
      if (!biometricVerified) {
        // 验证失败或取消，不更新开关
        return;
      }

      // 2.2 验证通过，保存设置
      await AppSetting.set(Setting.encryptedSpaceBiometricEnabled, false);
      if (mounted) {
        setState(() {
          _biometricEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已禁用生物识别解锁'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 验证密码（用于开启生物识别）
  Future<bool> _verifyPasswordForEnable() async {
    // 确保加密空间服务已初始化
    if (_encryptedSpaceService == null || _encryptedSpaceAlbumId == null) {
      try {
        await _initializeEncryptedSpace();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('初始化加密空间失败: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return false;
      }
    }

    if (_encryptedSpaceService == null || _encryptedSpaceAlbumId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法获取加密空间信息'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    // 显示密码验证对话框
    final verified = await PasswordVerificationDialog.show(
      context,
      encryptedSpaceService: _encryptedSpaceService!,
      albumId: _encryptedSpaceAlbumId!,
    );

    return verified;
  }

  /// 验证生物识别（用于关闭生物识别）
  Future<bool> _verifyBiometricForDisable() async {
    try {
      final biometricAuthService = BiometricAuthService();
      
      // 检查设备支持
      final supported = await biometricAuthService.isDeviceSupported();
      if (!supported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('您的设备不支持生物识别'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }

      // 执行生物识别认证
      final result = await biometricAuthService.authenticate(
        reason: '请使用生物识别验证以关闭生物识别解锁',
      );

      return result.success;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生物识别验证失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _onThemeColorChanged(String color) async {
    await AppSetting.set(Setting.themeColor, color);
    setState(() {
      _selectedThemeColor = color;
    });
    // StreamProvider 会自动更新，不需要手动刷新
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('主题色已更新'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.router.maybePop(),
        ),
        title: const Text(
          '偏好设置',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // 加密空间设置区域
            _buildEncryptedSpaceSection(),
            const SizedBox(height: 8),
            // 主题色选择区域
            _buildThemeColorSection(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 构建加密空间设置区域
  Widget _buildEncryptedSpaceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '加密空间',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '启用后，设置密码后可使用生物识别快速解锁加密空间',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 20,
                    color: _biometricSupported 
                      ? Colors.grey[700] 
                      : Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '生物识别解锁',
                    style: TextStyle(
                      fontSize: 15,
                      color: _biometricSupported 
                        ? Colors.black87 
                        : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              Switch(
                value: _biometricEnabled && _biometricSupported,
                onChanged: _biometricSupported 
                  ? _onBiometricEnabledChanged 
                  : null,
              ),
            ],
          ),
          if (!_biometricSupported) ...[
            const SizedBox(height: 8),
            Text(
              '您的设备不支持生物识别',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 自动锁定超时时间设置
          _buildLockTimeoutSelector(),
        ],
      ),
    );
  }

  /// 构建自动锁定超时时间选择器
  Widget _buildLockTimeoutSelector() {
    final timeoutOptions = [
      _TimeoutOption(5, '5分钟'),
      _TimeoutOption(15, '15分钟'),
      _TimeoutOption(30, '30分钟'),
      _TimeoutOption(60, '1小时'),
      _TimeoutOption(120, '2小时'),
      _TimeoutOption(0, '永不（仅令牌过期时锁定）'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 20,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 8),
            const Text(
              '自动锁定超时时间',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '设置加密空间在多长时间后自动锁定（默认：30分钟）',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        // 使用下拉选择器
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<int>(
            value: _lockTimeoutMinutes,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: timeoutOptions.map((option) {
              return DropdownMenuItem<int>(
                value: option.minutes,
                child: Text(
                  option.label,
                  style: const TextStyle(fontSize: 15),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _onLockTimeoutChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  /// 构建主题色选择区域
  Widget _buildThemeColorSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '主题色',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '选择应用的主题颜色',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          // 颜色选择网格
          _buildColorGrid(),
        ],
      ),
    );
  }

  /// 构建颜色选择网格
  Widget _buildColorGrid() {
    final colors = [
      _ThemeColorOption('blue', Colors.blue, '蓝色'),
      _ThemeColorOption('green', Colors.green, '绿色'),
      _ThemeColorOption('purple', Colors.purple, '紫色'),
      _ThemeColorOption('orange', Colors.orange, '橙色'),
      _ThemeColorOption('red', Colors.red, '红色'),
      _ThemeColorOption('pink', Colors.pink, '粉色'),
      _ThemeColorOption('teal', Colors.teal, '青色'),
      _ThemeColorOption('indigo', Colors.indigo, '靛蓝'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final colorOption = colors[index];
        final isSelected = _selectedThemeColor == colorOption.value;

        return GestureDetector(
          onTap: () => _onThemeColorChanged(colorOption.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 颜色圆圈
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorOption.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black87 : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorOption.color.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(height: 6),
              // 颜色名称
              Flexible(
                child: Text(
                  colorOption.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.black87 : Colors.grey[600],
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 主题色选项数据模型
class _ThemeColorOption {
  final String value;
  final Color color;
  final String label;

  _ThemeColorOption(this.value, this.color, this.label);
}

/// 超时时间选项数据模型
class _TimeoutOption {
  final int minutes;
  final String label;

  _TimeoutOption(this.minutes, this.label);
}
