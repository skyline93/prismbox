import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:prismbox/presentation/widgets/user/user_profile_indicator.dart';

/// 资料库页面
@RoutePage()
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资料库'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: UserProfileIndicator(),
          ),
        ],
      ),
      body: const Center(
        child: Text('资料库页面'),
      ),
    );
  }
}

