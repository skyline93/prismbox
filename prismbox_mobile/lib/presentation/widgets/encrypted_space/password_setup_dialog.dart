// lib/presentation/widgets/encrypted_space/password_setup_dialog.dart

import 'package:flutter/material.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/presentation/widgets/encrypted_space/pin_input_widget.dart';

/// PIN设置对话框
/// 用于首次设置或更改加密空间PIN
class PasswordSetupDialog extends StatefulWidget {
  final String albumId;
  final EncryptedSpaceService encryptedSpaceService;
  final bool isChangePassword;

  const PasswordSetupDialog({
    super.key,
    required this.albumId,
    required this.encryptedSpaceService,
    this.isChangePassword = false,
  });

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
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final GlobalKey<State<PinInputWidget>> _pinInputKey = GlobalKey();
  final GlobalKey<State<PinInputWidget>> _confirmPinInputKey = GlobalKey();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showConfirmPin = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _onPinCompleted(String pin) {
    if (pin.length == 6) {
      setState(() {
        _showConfirmPin = true;
        _errorMessage = null;
      });
      // 聚焦到确认PIN输入框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        (_confirmPinInputKey.currentState as dynamic)?.focusFirst();
      });
    }
  }

  void _onConfirmPinCompleted(String confirmPin) {
    if (confirmPin.length == 6) {
      _handleSubmit();
    }
  }

  Future<void> _handleSubmit() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.length != 6) {
      setState(() {
        _errorMessage = '请输入6位PIN';
      });
      return;
    }

    if (confirmPin.length != 6) {
      setState(() {
        _errorMessage = '请确认6位PIN';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = '两次输入的PIN不一致';
      });
      _confirmPinController.clear();
      (_confirmPinInputKey.currentState as dynamic)?.clear();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.encryptedSpaceService.setEncryptionPassword(
        albumId: widget.albumId,
        password: pin,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        
        final biometricEnabled = AppSetting.get(Setting.encryptedSpaceBiometricEnabled);
        final message = biometricEnabled
          ? 'PIN设置成功！您已启用生物识别，后续可以使用生物识别快速解锁'
          : (widget.isChangePassword ? 'PIN更改成功' : 'PIN设置成功');
          
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
          _errorMessage = '设置PIN失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isChangePassword ? '更改PIN' : '设置PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isChangePassword
                  ? '请输入新的6位PIN'
                  : '为加密空间设置6位PIN，用于保护您的私密照片和视频',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'PIN',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            PinInputWidget(
              key: _pinInputKey,
              controller: _pinController,
              autofocus: true,
              enabled: !_isLoading,
              hasError: _errorMessage != null && !_showConfirmPin,
              onCompleted: _onPinCompleted,
              onChanged: (pin) {
                if (pin.length < 6) {
                  setState(() {
                    _showConfirmPin = false;
                    _errorMessage = null;
                  });
                }
              },
            ),
            if (_showConfirmPin) ...[
              const SizedBox(height: 24),
              Text(
                '确认PIN',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              PinInputWidget(
                key: _confirmPinInputKey,
                controller: _confirmPinController,
                enabled: !_isLoading,
                hasError: _errorMessage != null && _errorMessage!.contains('不一致'),
                onCompleted: _onConfirmPinCompleted,
                onChanged: (pin) {
                  if (pin.length < 6 && _errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        if (_showConfirmPin)
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
