// lib/presentation/widgets/encrypted_space/password_verification_dialog.dart

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/presentation/widgets/encrypted_space/pin_input_widget.dart';

/// PIN验证对话框
/// 用于开启生物识别时验证PIN
class PasswordVerificationDialog extends StatefulWidget {
  final EncryptedSpaceService encryptedSpaceService;
  final String albumId;

  const PasswordVerificationDialog({
    super.key,
    required this.encryptedSpaceService,
    required this.albumId,
  });

  /// 显示PIN验证对话框
  /// 返回 true 表示验证成功，false 表示取消或失败
  static Future<bool> show(
    BuildContext context, {
    required EncryptedSpaceService encryptedSpaceService,
    required String albumId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordVerificationDialog(
        encryptedSpaceService: encryptedSpaceService,
        albumId: albumId,
      ),
    );
    return result ?? false;
  }

  @override
  State<PasswordVerificationDialog> createState() => _PasswordVerificationDialogState();
}

class _PasswordVerificationDialogState extends State<PasswordVerificationDialog> {
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<State<PinInputWidget>> _pinInputKey = GlobalKey();
  final Logger _log = Logger('PasswordVerificationDialog');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
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
      await widget.encryptedSpaceService.verifyPassword(
        albumId: widget.albumId,
        password: pin,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _log.warning('PIN verification failed', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'PIN错误，请重试';
          _isLoading = false;
        });
        _pinController.clear();
        (_pinInputKey.currentState as dynamic)?.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('验证PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '请输入加密空间PIN以启用生物识别',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
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
              : const Text('验证'),
        ),
      ],
    );
  }
}
