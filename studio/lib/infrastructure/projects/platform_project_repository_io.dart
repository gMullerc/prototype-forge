import 'package:prototype_workspace/prototype_workspace.dart';

PrototypeProjectRepository createProjectRepository() =>
    _MemoryProjectRepository();

class _MemoryProjectRepository implements PrototypeProjectRepository {
  List<PrototypeProject> _projects = <PrototypeProject>[];

  @override
  Future<List<PrototypeProject>> loadProjects() async =>
      List<PrototypeProject>.from(_projects);

  @override
  Future<void> saveProjects(List<PrototypeProject> projects) async {
    _projects = List<PrototypeProject>.from(projects);
  }
}
