import 'workspace_transfer_port.dart';

WorkspaceTransfer createWorkspaceTransfer() =>
    const _UnsupportedWorkspaceTransfer();

class _UnsupportedWorkspaceTransfer implements WorkspaceTransfer {
  const _UnsupportedWorkspaceTransfer();

  @override
  Future<void> downloadText({
    required String filename,
    required String contents,
  }) {
    throw UnsupportedError('Backup local disponível somente no Flutter Web.');
  }

  @override
  Future<String?> pickText() {
    throw UnsupportedError(
        'Importação local disponível somente no Flutter Web.');
  }
}
