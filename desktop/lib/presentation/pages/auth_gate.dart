// lib/presentation/pages/auth_gate.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../app/router/app_router.gr.dart';
import '../providers/providers.dart';

@RoutePage()
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the auth state. If it becomes unauthenticated (e.g., after logout),
    // this will trigger a navigation back to the login page.
    // ref.listen<AsyncValue<void>>(authViewModelProvider, (_, state) {
    //   if (state is AsyncData) {
    //     context.router.replace(const LoginRoute());
    //   }
    // });

    return FutureBuilder<bool>(
      // Check the initial login state once.
      future: ref.read(authRepositoryProvider).isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Once the check is complete, use a post-frame callback to navigate.
          // This avoids trying to navigate during a build phase.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              final bool isLoggedIn = snapshot.data ?? false;
              if (isLoggedIn) {
                context.router.replace(const HomeRoute());
              } else {
                context.router.replace(const LoginRoute());
              }
            }
          });
        }

        // While checking, show a loading indicator. This screen will be
        // replaced immediately once the future completes.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
