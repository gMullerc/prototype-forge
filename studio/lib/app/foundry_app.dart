import 'package:flutter/material.dart';
import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_gateway_client/prototype_gateway_client.dart';
import 'package:prototype_material_catalog/prototype_material_catalog.dart';
import 'package:prototype_runtime/prototype_runtime.dart';

import '../application/studio_session.dart';
import '../infrastructure/gateway/platform_gateway_transport.dart';
import '../infrastructure/local_prototype_agent.dart';
import '../presentation/foundry_theme.dart';
import '../presentation/studio_page.dart';

class FoundryApp extends StatefulWidget {
  const FoundryApp({super.key});

  @override
  State<FoundryApp> createState() => _FoundryAppState();
}

class _FoundryAppState extends State<FoundryApp> {
  static const String _gatewayUrl = String.fromEnvironment(
    'PROTOTYPE_GATEWAY_URL',
    defaultValue: 'http://127.0.0.1:8790',
  );

  late final FlutterPrototypeCatalog _catalog =
      createMaterialPrototypeCatalog();
  late final StudioSession _session = StudioSession(
    agents: <PrototypeAgent>[
      const LocalPrototypeAgent(),
      GatewayPrototypeAgent(
        id: 'opencode',
        label: 'OpenCode',
        providerId: 'opencode',
        transport: createPlatformGatewayTransport(
          baseUri: Uri.parse(_gatewayUrl),
        ),
        catalog: _catalog.runtimeCatalog,
      ),
    ],
    initialAgentId: 'local-contract',
    engine: PrototypeEngine(
      catalog: _catalog.runtimeCatalog,
    ),
  );

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prototype Foundry',
      theme: buildFoundryTheme(),
      home: StudioPage(session: _session, catalog: _catalog),
    );
  }
}
