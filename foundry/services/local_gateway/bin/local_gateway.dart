import 'dart:async';
import 'dart:io';

import 'package:prototype_local_gateway/application/generate_prototype.dart';
import 'package:prototype_local_gateway/application/prototype_contract_builder.dart';
import 'package:prototype_local_gateway/domain/prototype_provider.dart';
import 'package:prototype_local_gateway/infrastructure/copilot/copilot_cli_client.dart';
import 'package:prototype_local_gateway/infrastructure/copilot/copilot_configuration.dart';
import 'package:prototype_local_gateway/infrastructure/copilot/copilot_process_runner.dart';
import 'package:prototype_local_gateway/infrastructure/copilot/copilot_provider.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/json_http_transport.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/opencode_api_client.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/opencode_configuration.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/opencode_host.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/opencode_provider.dart';
import 'package:prototype_local_gateway/infrastructure/tools/process_tool_probe.dart';
import 'package:prototype_local_gateway/infrastructure/tools/tool_inventory.dart';
import 'package:prototype_local_gateway/interface/http/local_gateway_server.dart';
import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';

Future<void> main() async {
  final Map<String, String> environment = Platform.environment;
  final OpenCodeConfiguration openCode =
      OpenCodeConfiguration.fromEnvironment(environment);
  final DartJsonHttpTransport transport = DartJsonHttpTransport();
  final ManagedOpenCodeHost host = ManagedOpenCodeHost(
    configuration: openCode,
    transport: transport,
  );
  final OpenCodePrototypeProvider provider = OpenCodePrototypeProvider(
    host: host,
    client: OpenCodeApiClient(
      configuration: openCode,
      host: host,
      transport: transport,
    ),
  );
  final DartCopilotProcessRunner copilotRunner = DartCopilotProcessRunner();
  final CopilotPrototypeProvider copilot = CopilotPrototypeProvider(
    client: CopilotCliClient(
      configuration: CopilotConfiguration.fromEnvironment(environment),
      runner: copilotRunner,
    ),
  );
  final PrototypeProviderRegistry providers =
      PrototypeProviderRegistry(<PrototypeProvider>[provider, copilot]);
  final ToolInventory toolInventory = ToolInventory(
    LocalToolDiscovery(probe: const ProcessToolProbe()),
  );
  final Completer<void> done = Completer<void>();
  var closing = false;
  late final LocalGatewayServer server;
  late final StreamSubscription<ProcessSignal> interruptSubscription;
  StreamSubscription<ProcessSignal>? terminateSubscription;
  Future<void> shutdown() async {
    if (closing) return;
    closing = true;
    await server.close();
    await providers.close();
    transport.close();
    await interruptSubscription.cancel();
    await terminateSubscription?.cancel();
    if (!done.isCompleted) done.complete();
  }

  server = LocalGatewayServer(
    host: environment['PROTOTYPE_GATEWAY_HOST'] ?? '127.0.0.1',
    port: int.tryParse(environment['PROTOTYPE_GATEWAY_PORT'] ?? '') ?? 8790,
    generatePrototype: GeneratePrototype(
      providers: providers,
      contractBuilder: const PrototypeSpecContractBuilder(),
    ),
    providers: providers,
    toolInventory: toolInventory,
    shutdownToken: environment['PROTOTYPE_GATEWAY_SHUTDOWN_TOKEN'],
    onShutdown: shutdown,
  );

  interruptSubscription =
      ProcessSignal.sigint.watch().listen((ProcessSignal _) => shutdown());
  if (!Platform.isWindows) {
    terminateSubscription =
        ProcessSignal.sigterm.watch().listen((ProcessSignal _) => shutdown());
  }

  unawaited(
    server.start().catchError((Object error, StackTrace stackTrace) async {
      stderr.writeln('Falha no gateway local: $error');
      stderr.writeln(stackTrace);
      await shutdown();
    }),
  );

  while (server.boundPort == null && !closing) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  if (!closing) {
    stdout.writeln(
      'Prototype Foundry gateway: http://127.0.0.1:${server.boundPort}',
    );
    stdout.writeln('OpenCode: ${openCode.baseUri} · ${openCode.model}');
  }
  await done.future;
}
