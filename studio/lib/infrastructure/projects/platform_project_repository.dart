import 'package:prototype_workspace/prototype_workspace.dart';

import 'platform_project_repository_stub.dart'
    if (dart.library.html) 'platform_project_repository_web.dart'
    if (dart.library.io) 'platform_project_repository_io.dart' as platform;

PrototypeProjectRepository createPlatformProjectRepository() =>
    platform.createProjectRepository();
