import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/services/server_check_service.dart';
import 'package:mobile/providers/providers.dart';

class ServerConnectionNotifier extends StateNotifier<ServerConnectionState> {
  final Ref _ref;

  ServerConnectionNotifier(this._ref) : super(ServerConnectionState.checking) {
    initialCheck();
  }

  ServerCheckService get _service => _ref.read(serverCheckServiceProvider);

  Future<void> initialCheck() async {
    state = ServerConnectionState.checking;
    final currentState = await _service.getCurrentState();
    if (mounted) {
      state = currentState;
    }
  }

  Future<bool> testConnectState() async {
    final currentState = await _service.getCurrentState();
    return currentState == ServerConnectionState.readyToLogin;
  }
}

final serverConnectionNotifier =
    StateNotifierProvider<ServerConnectionNotifier, ServerConnectionState>((
      ref,
    ) {
      return ServerConnectionNotifier(ref);
    });
