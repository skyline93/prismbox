// lib/presentation/pages/settings/language_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/core/settings/app_setting.dart';

/// 语言设置页面
@RoutePage()
class LanguagePage extends ConsumerStatefulWidget {
  const LanguagePage({super.key});

  @override
  ConsumerState<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends ConsumerState<LanguagePage> {
  String _selectedLanguage = 'zh_CN';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  void _loadLanguage() {
    setState(() {
      _selectedLanguage = AppSetting.get(Setting.language);
    });
  }

  Future<void> _onLanguageChanged(String language) async {
    await AppSetting.set(Setting.language, language);
    setState(() {
      _selectedLanguage = language;
    });
    // StreamProvider 会自动更新，不需要手动刷新
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('语言设置已更新'),
          duration: Duration(seconds: 1),
        ),
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
          '语言',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // 语言列表
            _buildLanguageList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 构建语言列表
  Widget _buildLanguageList() {
    final languages = [
      _LanguageOption(
        value: 'zh_CN',
        title: '中文简体',
        subtitle: '简体中文',
        flag: '🇨🇳',
      ),
      _LanguageOption(
        value: 'en',
        title: 'English',
        subtitle: 'English',
        flag: '🇺🇸',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        children: languages.map((language) {
          final isSelected = _selectedLanguage == language.value;
          final isLast = language == languages.last;

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onLanguageChanged(language.value),
                  borderRadius: BorderRadius.vertical(
                    top: language == languages.first
                        ? const Radius.circular(12)
                        : Radius.zero,
                    bottom: isLast
                        ? const Radius.circular(12)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        // 国旗图标
                        Text(
                          language.flag,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 16),
                        // 语言信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                language.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                language.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 选中指示器
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 24,
                          )
                        else
                          Icon(
                            Icons.radio_button_unchecked,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.grey[200],
                  indent: 60,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// 语言选项数据模型
class _LanguageOption {
  final String value;
  final String title;
  final String subtitle;
  final String flag;

  _LanguageOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.flag,
  });
}

