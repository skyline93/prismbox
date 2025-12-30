// lib/presentation/widgets/encrypted_space/password_verify_dialog.dart

import 'package:flutter/material.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/services/encrypted_space/album_access_control_service.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/services/encrypted_space/biometric_auth_service.dart';
import 'package:prismbox/services/encrypted_space/session_storage_service.dart';

/// 密码验证对话框
/// 用于解锁加密空间
class PasswordVerifyDialog extends StatefulWidget {
  final String albumId;
  final EncryptedSpaceService encryptedSpaceService;
  final AlbumAccessControlService accessControlService;

  const PasswordVerifyDialog({
    super.key,
    required this.albumId,
    required this.encryptedSpaceService,
    required this.accessControlService,
  });

  /// 显示密码验证对话框
  static Future<bool?> show(
    BuildContext context, {
    required String albumId,
    required EncryptedSpaceService encryptedSpaceService,
    required AlbumAccessControlService accessControlService,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordVerifyDialog(
        albumId: albumId,
        encryptedSpaceService: encryptedSpaceService,
        accessControlService: accessControlService,
      ),
    );
  }

  @override
  State<PasswordVerifyDialog> createState() => _PasswordVerifyDialogState();
}

class _PasswordVerifyDialogState extends State<PasswordVerifyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPasswordInput = false; // 是否显示密码输入框
  bool _isCheckingBiometric = false; // 是否正在检查生物识别

  @override
  void initState() {
    super.initState();
    _checkBiometricFirst();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// 首先尝试使用生物识别
  Future<void> _checkBiometricFirst() async {
    // 检查是否启用了生物识别
    final biometricEnabled = AppSetting.get(Setting.encryptedSpaceBiometricEnabled);
    if (!biometricEnabled) {
      setState(() {
        _showPasswordInput = true;
      });
      return;
    }

    // 检查设备是否支持
    final biometricAuthService = BiometricAuthService();
    final supported = await biometricAuthService.isDeviceSupported();
    if (!supported) {
      setState(() {
        _showPasswordInput = true;
      });
      return;
    }

    // 尝试生物识别认证
    setState(() {
      _isCheckingBiometric = true;
    });

    try {
      final result = await biometricAuthService.authenticate(
        reason: '请使用生物识别验证以访问加密空间',
      );

      if (result) {
        // 生物识别成功，直接解锁
        await _unlockWithBiometric();
      } else {
        // 用户取消或失败，显示密码输入框
        setState(() {
          _showPasswordInput = true;
          _isCheckingBiometric = false;
        });
      }
    } catch (e) {
      // 生物识别出错，显示密码输入框
      setState(() {
        _showPasswordInput = true;
        _isCheckingBiometric = false;
      });
    }
  }

  /// 使用生物识别解锁
  Future<void> _unlockWithBiometric() async {
    try {
      // 检查是否有有效的会话令牌
      final sessionStorage = SessionStorageService();
      final hasValidToken = await sessionStorage.isSessionTokenValid(widget.albumId);
      
      if (!hasValidToken) {
        // 令牌已过期，需要重新输入密码
        setState(() {
          _showPasswordInput = true;
          _isCheckingBiometric = false;
          _errorMessage = '会话已过期，请重新输入密码';
        });
        return;
      }

      // 解锁相册（不使用生物识别，因为已经验证过了）
      await widget.accessControlService.unlockAlbum(
        widget.albumId,
        useBiometric: false,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showPasswordInput = true;
          _isCheckingBiometric = false;
          _errorMessage = '解锁失败: $e';
        });
      }
    }
  }

  /// 手动触发生物识别（用户点击生物识别按钮）
  Future<void> _tryBiometricAgain() async {
    final biometricAuthService = BiometricAuthService();
    final supported = await biometricAuthService.isDeviceSupported();
    if (!supported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('您的设备不支持生物识别')),
        );
      }
      return;
    }

    setState(() {
      _isCheckingBiometric = true;
      _errorMessage = null;
    });

    try {
      final result = await biometricAuthService.authenticate(
        reason: '请使用生物识别验证以访问加密空间',
      );

      if (result) {
        await _unlockWithBiometric();
      } else {
        setState(() {
          _isCheckingBiometric = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingBiometric = false;
        _errorMessage = '生物识别失败: $e';
      });
    }
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 验证密码并获取会话令牌
      await widget.encryptedSpaceService.verifyPassword(
        albumId: widget.albumId,
        password: _passwordController.text,
      );

      // 解锁相册（不使用生物识别，因为用户已经输入了密码）
      await widget.accessControlService.unlockAlbum(
        widget.albumId,
        useBiometric: false,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '密码错误，请重试';
          _isLoading = false;
        });
        // 清空密码输入框
        _passwordController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('解锁加密空间'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isCheckingBiometric) ...[
                // 正在检查生物识别
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('正在验证生物识别...'),
                      ],
                    ),
                  ),
                ),
              ] else if (!_showPasswordInput) ...[
                // 显示生物识别提示和密码输入选项
                Text(
                  '请使用生物识别或输入密码解锁',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                // 生物识别按钮
                ElevatedButton.icon(
                  onPressed: _tryBiometricAgain,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('使用生物识别'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // 切换到密码输入
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showPasswordInput = true;
                    });
                  },
                  child: const Text('使用密码解锁'),
                ),
              ] else ...[
                // 显示密码输入框
                Text(
                  '请输入密码以访问加密空间',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleVerify(),
                ),
                // 如果启用了生物识别，显示生物识别按钮
                if (AppSetting.get(Setting.encryptedSpaceBiometricEnabled)) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _tryBiometricAgain,
                    icon: const Icon(Icons.fingerprint, size: 18),
                    label: const Text('使用生物识别解锁'),
                  ),
                ],
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading || _isCheckingBiometric 
            ? null 
            : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        if (_showPasswordInput)
          ElevatedButton(
            onPressed: _isLoading ? null : _handleVerify,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('解锁'),
          ),
      ],
    );
  }
}

