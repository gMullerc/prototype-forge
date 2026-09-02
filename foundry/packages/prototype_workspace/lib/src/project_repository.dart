import 'project_models.dart';

abstract interface class PrototypeProjectRepository {
  Future<List<PrototypeProject>> loadProjects();

  Future<void> saveProjects(List<PrototypeProject> projects);
}
