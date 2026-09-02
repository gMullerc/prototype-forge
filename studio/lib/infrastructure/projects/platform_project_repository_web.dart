// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html';

import 'package:prototype_workspace/prototype_workspace.dart';

PrototypeProjectRepository createProjectRepository() =>
    const _BrowserProjectRepository();

class _BrowserProjectRepository implements PrototypeProjectRepository {
  const _BrowserProjectRepository();

  static const String _storageKey = 'prototype-forge.projects.v1';

  @override
  Future<List<PrototypeProject>> loadProjects() async {
    final String? source = window.localStorage[_storageKey];
    if (source == null || source.trim().isEmpty) return <PrototypeProject>[];
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! List<Object?>) return <PrototypeProject>[];
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map(
            (Map<Object?, Object?> value) => PrototypeProject.fromJson(
              Map<String, Object?>.from(value),
            ),
          )
          .toList();
    } on Object {
      return <PrototypeProject>[];
    }
  }

  @override
  Future<void> saveProjects(List<PrototypeProject> projects) async {
    window.localStorage[_storageKey] = jsonEncode(
      projects.map((PrototypeProject project) => project.toJson()).toList(),
    );
  }
}
