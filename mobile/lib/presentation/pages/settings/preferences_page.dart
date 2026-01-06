// lib/presentation/pages/settings/preferences_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/core/settings/app_setting.dart';

/// 偏好设置页面
@RoutePage()
class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  String _selectedThemeColor = 'blue';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _loadThemeColor();
  }

  void _loadThemeColor() {
    setState(() {
      _selectedThemeColor = AppSetting.get(Setting.themeColor);
    });
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
            // 主题色选择区域
            _buildThemeColorSection(),
            const SizedBox(height: 8),
          ],
        ),
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
