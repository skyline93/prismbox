// lib/presentation/widgets/encrypted_space/pin_input_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 6位PIN码输入组件
/// 使用6个小框显示输入的数字
class PinInputWidget extends StatefulWidget {
  final Function(String)? onCompleted;
  final Function(String)? onChanged;
  final bool autofocus;
  final bool hasError;
  final String? errorMessage;
  final TextEditingController? controller;
  final bool enabled;

  const PinInputWidget({
    super.key,
    this.onCompleted,
    this.onChanged,
    this.autofocus = false,
    this.hasError = false,
    this.errorMessage,
    this.controller,
    this.enabled = true,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  final int _pinLength = 6;
  String _pinValue = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _pinLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      _pinLength,
      (index) => FocusNode(),
    );

    // 监听外部controller的变化
    if (widget.controller != null) {
      widget.controller!.addListener(_onExternalControllerChanged);
    }

    // 监听每个输入框的变化
    for (int i = 0; i < _pinLength; i++) {
      _controllers[i].addListener(() => _onControllerChanged(i));
      _focusNodes[i].addListener(() => _onFocusChanged(i));
    }

    // 自动聚焦第一个输入框
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller!.removeListener(_onExternalControllerChanged);
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onExternalControllerChanged() {
    if (widget.controller == null) return;
    final value = widget.controller!.text;
    if (value != _pinValue) {
      _setPinValue(value);
    }
  }

  void _onControllerChanged(int index) {
    final value = _controllers[index].text;
    
    // 只允许输入一个数字
    if (value.length > 1) {
      _controllers[index].text = value.substring(0, 1);
      return;
    }

    // 只允许输入数字
    if (value.isNotEmpty && !RegExp(r'^\d$').hasMatch(value)) {
      _controllers[index].clear();
      return;
    }

    _updatePinValue();

    // 自动聚焦到下一个输入框
    if (value.isNotEmpty && index < _pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // 如果所有框都填满，触发完成回调
    if (_pinValue.length == _pinLength) {
      widget.onCompleted?.call(_pinValue);
    }
  }

  void _onFocusChanged(int index) {
    // 当聚焦时，选中所有文本
    if (_focusNodes[index].hasFocus) {
      _controllers[index].selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controllers[index].text.length,
      );
    }
  }

  void _updatePinValue() {
    final newValue = _controllers.map((c) => c.text).join();
    if (newValue != _pinValue) {
      _pinValue = newValue;
      widget.controller?.text = _pinValue;
      widget.onChanged?.call(_pinValue);
    }
  }

  void _setPinValue(String value) {
    if (value.length > _pinLength) {
      value = value.substring(0, _pinLength);
    }

    for (int i = 0; i < _pinLength; i++) {
      if (i < value.length) {
        _controllers[i].text = value[i];
      } else {
        _controllers[i].clear();
      }
    }
    _pinValue = value;
  }

  void _clear() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _pinValue = '';
    widget.controller?.text = '';
    _focusNodes[0].requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;

    // 找到当前输入框的索引
    int index = _focusNodes.indexOf(node);
    if (index < 0) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // 如果当前框为空，聚焦到上一个框并清空
          _controllers[index - 1].clear();
          _focusNodes[index - 1].requestFocus();
          _updatePinValue();
        } else {
          // 清空当前框
          _controllers[index].clear();
          _updatePinValue();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index > 0) {
        _focusNodes[index - 1].requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && index < _pinLength - 1) {
        _focusNodes[index + 1].requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _focusFirst() {
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final borderColor = widget.hasError
        ? errorColor
        : theme.colorScheme.outline.withOpacity(0.5);
    final focusedBorderColor = widget.hasError
        ? errorColor
        : theme.colorScheme.primary;

    return FocusScope(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                return Flexible(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < _pinLength - 1 ? 8.0 : 0,
                    ),
                    height: 56.0,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Focus(
                        onKeyEvent: _handleKeyEvent,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          enabled: widget.enabled,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          obscureText: true,
                          obscuringCharacter: '●',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: borderColor,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: focusedBorderColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: errorColor,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: errorColor,
                                width: 2,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: borderColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: widget.hasError
                                ? errorColor.withOpacity(0.05)
                                : theme.colorScheme.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (widget.errorMessage != null && widget.hasError) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                widget.errorMessage!,
                style: TextStyle(
                  color: errorColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 暴露清除方法和聚焦方法
  void clear() => _clear();
  void focusFirst() => _focusFirst();
}

