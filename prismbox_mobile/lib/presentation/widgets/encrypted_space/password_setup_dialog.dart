// lib/presentation/widgets/encrypted_space/password_setup_dialog.dart

import 'package:flutter/material.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/core/settings/app_setting.dart';

/// 密码设置对话框
/// 用于首次设置或更改加密空间密码
class PasswordSetupDialog extends StatefulWidget {
  final String albumId;
  final EncryptedSpaceService encryptedSpaceService;
  final bool isChangePassword; // 是否为更改密码

  const PasswordSetupDialog({
    super.key,
    required this.albumId,
    required this.encryptedSpaceService,
    this.isChangePassword = false,
  });

  /// 显示密码设置对话框
  static Future<bool?> show(
    BuildContext context, {
    required String albumId,
    required EncryptedSpaceService encryptedSpaceService,
    bool isChangePassword = false,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordSetupDialog(
        albumId: albumId,
        encryptedSpaceService: encryptedSpaceService,
        isChangePassword: isChangePassword,
      ),
    );
  }

  @override
  State<PasswordSetupDialog> createState() => _PasswordSetupDialogState();
}

class _PasswordSetupDialogState extends State<PasswordSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = '两次输入的密码不一致';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.encryptedSpaceService.setEncryptionPassword(
        albumId: widget.albumId,
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        
        // 检查是否启用了生物识别
        final biometricEnabled = AppSetting.get(Setting.encryptedSpaceBiometricEnabled);
        final message = biometricEnabled
          ? '密码设置成功！您已启用生物识别，后续可以使用生物识别快速解锁'
          : (widget.isChangePassword ? '密码更改成功' : '密码设置成功');
          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '设置密码失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isChangePassword ? '更改密码' : '设置密码'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isChangePassword
                    ? '请输入新密码'
                    : '为加密空间设置密码，用于保护您的私密照片和视频',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              // 密码输入
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
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
                  if (value.length < 8) {
                    return '密码至少需要8个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 确认密码输入
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请确认密码';
                  }
                  if (value != _passwordController.text) {
                    return '两次输入的密码不一致';
                  }
                  return null;
                },
              ),
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isChangePassword ? '更改' : '设置'),
        ),
      ],
    );
  }
}

