// lib/presentation/widgets/encrypted_space/password_verify_dialog.dart

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/services/pin/pin_access_control_service.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/services/biometric/biometric_auth_service.dart';
// import 'package:prismbox/services/encrypted_space/session_storage_service.dart';
import 'package:prismbox/presentation/widgets/encrypted_space/pin_input_widget.dart';

/// PIN验证对话框
/// 用于解锁加密空间
class PasswordVerifyDialog extends StatefulWidget {
  final String albumId;
  final EncryptedSpaceService encryptedSpaceService;
  final PinAccessControlService accessControlService;

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
    required PinAccessControlService accessControlService,
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
  final Logger _log = Logger('PasswordVerifyDialog');
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<State<PinInputWidget>> _pinInputKey = GlobalKey();
  bool _isLoading = false;
  bool _showPinInput = false;
  bool _isCheckingBiometric = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保对话框完全初始化后再执行生物识别
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricFirst();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// 首先尝试使用生物识别
  Future<void> _checkBiometricFirst() async {
    // 确保 Widget 已挂载
    if (!mounted) return;
    
    // 检查是否启用了生物识别
    final biometricEnabled = AppSetting.get(Setting.encryptedSpaceBiometricEnabled);
    if (!biometricEnabled) {
      if (mounted) {
        setState(() {
          _showPinInput = true;
        });
      }
      return;
    }

    // 检查设备是否支持
    final biometricAuthService = BiometricAuthService();
    try {
      final supported = await biometricAuthService.isDeviceSupported();
      if (!supported || !mounted) {
        if (mounted) {
          setState(() {
            _showPinInput = true;
          });
        }
        return;
      }

      // 尝试生物识别认证
      if (mounted) {
        setState(() {
          _isCheckingBiometric = true;
        });
      }

      final result = await biometricAuthService.authenticate(
        reason: '请使用生物识别验证以访问加密空间',
      );

      if (result.success && mounted) {
        // 生物识别成功，直接解锁
        await _unlockWithBiometric();
      } else if (mounted) {
        // 用户取消或失败，显示PIN输入框
        setState(() {
          _showPinInput = true;
          _isCheckingBiometric = false;
        });
      }
    } catch (e, stackTrace) {
      // 生物识别出错，显示PIN输入框
      _log.warning('Biometric authentication error', e, stackTrace);
      if (mounted) {
        setState(() {
          _showPinInput = true;
          _isCheckingBiometric = false;
        });
      }
    }
  }

  /// 使用生物识别解锁
  Future<void> _unlockWithBiometric() async {
    try {
      // 检查是否有有效的会话令牌
      final hasValidToken = await widget.encryptedSpaceService.isAlbumUnlocked(
        widget.albumId,
      );
      
      if (!hasValidToken) {
        // 令牌已过期，需要重新输入PIN
        setState(() {
          _showPinInput = true;
          _isCheckingBiometric = false;
          _errorMessage = '会话已过期，请重新输入PIN';
        });
        return;
      }

      // 解锁相册（不使用生物识别，因为已经验证过了）
      await widget.accessControlService.unlockResource(
        widget.albumId,
        useBiometric: false,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showPinInput = true;
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

      if (result.success) {
        await _unlockWithBiometric();
      } else {
        setState(() {
          _isCheckingBiometric = false;
        });
      }
    } catch (e, stackTrace) {
      _log.warning('Biometric authentication error in _tryBiometricAgain', e, stackTrace);
      if (mounted) {
        setState(() {
          _isCheckingBiometric = false;
          _errorMessage = '生物识别失败: $e';
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    final pin = _pinController.text;
    if (pin.length != 6) {
      setState(() {
        _errorMessage = '请输入6位PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 验证PIN并获取会话令牌
      await widget.encryptedSpaceService.verifyPassword(
        albumId: widget.albumId,
        password: pin,
      );

      // 解锁相册（不使用生物识别，因为用户已经输入了PIN）
      await widget.accessControlService.unlockResource(
        widget.albumId,
        useBiometric: false,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'PIN错误，请重试';
          _isLoading = false;
        });
        // 清空PIN输入框
        _pinController.clear();
        (_pinInputKey.currentState as dynamic)?.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('解锁加密空间'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isCheckingBiometric) ...[
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
            ] else if (!_showPinInput) ...[
              Text(
                '请使用生物识别或输入PIN解锁',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _tryBiometricAgain,
                icon: const Icon(Icons.fingerprint),
                label: const Text('使用生物识别'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showPinInput = true;
                  });
                },
                child: const Text('使用PIN解锁'),
              ),
            ] else ...[
              Text(
                '请输入6位PIN以访问加密空间',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PinInputWidget(
                key: _pinInputKey,
                controller: _pinController,
                autofocus: true,
                enabled: !_isLoading,
                hasError: _errorMessage != null,
                errorMessage: _errorMessage,
                onCompleted: (pin) {
                  if (pin.length == 6 && !_isLoading) {
                    _handleVerify();
                  }
                },
                onChanged: (pin) {
                  if (pin.length < 6 && _errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              if (AppSetting.get(Setting.encryptedSpaceBiometricEnabled)) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _tryBiometricAgain,
                  icon: const Icon(Icons.fingerprint, size: 18),
                  label: const Text('使用生物识别解锁'),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading || _isCheckingBiometric 
            ? null 
            : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        if (_showPinInput)
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (_pinController.text.length == 6) {
                _handleVerify();
              }
            },
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

