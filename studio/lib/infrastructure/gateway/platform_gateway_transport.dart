import 'package:prototype_gateway_client/prototype_gateway_client.dart';

import 'platform_gateway_transport_stub.dart'
    if (dart.library.html) 'platform_gateway_transport_web.dart'
    if (dart.library.io) 'platform_gateway_transport_io.dart' as platform;

GatewayTransport createPlatformGatewayTransport({required Uri baseUri}) =>
    platform.createGatewayTransport(baseUri);
