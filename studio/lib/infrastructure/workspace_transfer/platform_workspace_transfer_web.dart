// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html';

import 'workspace_transfer_port.dart';

WorkspaceTransfer createWorkspaceTransfer() => const _WebWorkspaceTransfer();

class _WebWorkspaceTransfer implements WorkspaceTransfer {
  const _WebWorkspaceTransfer();

  @override
  Future<void> downloadText({
    required String filename,
    required String contents,
  }) async {
    final Blob blob = Blob(<Object>[contents], 'application/json');
    final String url = Url.createObjectUrlFromBlob(blob);
    AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    Url.revokeObjectUrl(url);
  }

  @override
  Future<String?> pickText() async {
    final FileUploadInputElement input = FileUploadInputElement()
      ..accept = '.json,application/json';
    input.click();
    await input.onChange.first;
    final File? file = input.files?.first;
    if (file == null) return null;
    final FileReader reader = FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    return reader.result is String ? reader.result as String : null;
  }
}
