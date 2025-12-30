// lib/presentation/pages/settings/preferences_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/services/encrypted_space/biometric_auth_service.dart';

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
  bool _isCheckingBiometric = false;
  bool _biometricSupported = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _loadThemeColor();
    await _loadBiometricSettings();
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
      setState(() {
        _biometricSupported = supported;
        _isCheckingBiometric = false;
      });
    } catch (e) {
      setState(() {
        _biometricSupported = false;
        _isCheckingBiometric = false;
      });
    }
  }

  Future<void> _onBiometricEnabledChanged(bool value) async {
    if (value && !_biometricSupported) {
      // 如果设备不支持，提示用户
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

    // 如果启用生物识别，先测试一下是否可用
    if (value) {
      setState(() {
        _isCheckingBiometric = true;
      });
      
      try {
        final biometricAuthService = BiometricAuthService();
        final available = await biometricAuthService.canCheckBiometrics();
        if (!available) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('未检测到可用的生物识别方法，请先在系统设置中配置'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() {
            _isCheckingBiometric = false;
          });
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
        setState(() {
          _isCheckingBiometric = false;
        });
        return;
      }
    }

    await AppSetting.set(Setting.encryptedSpaceBiometricEnabled, value);
    setState(() {
      _biometricEnabled = value;
      _isCheckingBiometric = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value 
            ? '已启用生物识别解锁，设置密码后可使用生物识别快速解锁' 
            : '已禁用生物识别解锁'),
          duration: const Duration(seconds: 2),
        ),
      );
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
              if (_isCheckingBiometric)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
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
        ],
      ),
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
