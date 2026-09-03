abstract interface class WorkspaceTransfer {
  Future<void> downloadText({
    required String filename,
    required String contents,
  });

  Future<String?> pickText();
}
