import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/ui/library/widgets/server_endpoint_input.dart';
import 'package:mobile/ui/library/widgets/server_endpoint_button.dart';
import 'package:mobile/ui/library/viewmodel/server_config_viewmodel.dart';

@RoutePage()
class ServerConfigPage extends HookConsumerWidget {
  const ServerConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverUrlController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isTesting = useState(false);
    final notifier = ref.read(serverConnectionNotifier.notifier);

    Future<void> testConnection() async {
      if (!formKey.currentState!.validate()) return;

      isTesting.value = true;

      final isConnected = await notifier.testConnectState();
      if (isConnected) {
        print("已连通");
      }else{
        print("未连通");
      }

      isTesting.value = false;
    }

    Future<void> saveAndContinue() async {
      // TODO
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('服务器配置', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => context.router.pop(),
        ),
      ),
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 36.0,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('配置 GBox 服务器'),
                  const SizedBox(height: 48),
                  ServerEndpointInput(controller: serverUrlController),
                  const SizedBox(height: 24),
                  ServerEndpointButton(
                    title: "测试连接",
                    onPressed: testConnection,
                  ),
                  const SizedBox(height: 12),
                  ServerEndpointButton(
                    title: "保存并继续",
                    onPressed: saveAndContinue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
