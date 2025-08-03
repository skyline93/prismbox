import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: GboxApp()));
}

class GboxApp extends ConsumerStatefulWidget {
  // ignore: use_super_parameters
  const GboxApp({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GboxAppState();
}

class _GboxAppState extends ConsumerState<GboxApp> {
  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();

    return MaterialApp.router(
      title: 'mobile',
      debugShowCheckedModeBanner:
          false, // Hides the debug banner in development
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Colors.white,
          shadowColor: Colors.black,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
        ),
      ),
      // home: const HomeScreen(),
      routerConfig: appRouter.config(),
    );
  }
}
