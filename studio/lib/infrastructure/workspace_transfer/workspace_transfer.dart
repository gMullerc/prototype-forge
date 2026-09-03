import 'workspace_transfer_port.dart';

export 'workspace_transfer_port.dart';

import 'platform_workspace_transfer_stub.dart'
    if (dart.library.html) 'platform_workspace_transfer_web.dart' as platform;

WorkspaceTransfer createWorkspaceTransfer() =>
    platform.createWorkspaceTransfer();
