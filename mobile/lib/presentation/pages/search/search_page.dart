import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/widgets/user/user_profile_indicator.dart';
import 'package:prismbox/providers/navigation/search_input_focus_provider.dart';

/// 搜索页面
@RoutePage()
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 在 build 方法中使用 ref.listen
    ref.listen<bool>(searchInputFocusProvider, (previous, next) {
      if (next && _searchFocusNode.canRequestFocus) {
        _searchFocusNode.requestFocus();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: const InputDecoration(
            hintText: '搜索照片、相册...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: UserProfileIndicator(),
          ),
        ],
      ),
      body: const Center(
        child: Text('搜索页面'),
      ),
    );
  }
}

