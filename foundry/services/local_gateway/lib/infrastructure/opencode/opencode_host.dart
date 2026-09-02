import 'dart:async';
import 'dart:io';

import '../../domain/prototype_provider.dart';
import 'json_http_transport.dart';
import 'opencode_configuration.dart';

abstract interface class OpenCodeHost {
  Future<ProviderHealth> health();

  Future<void> ensureReady();

  Future<void> close();
}

class ManagedOpenCodeHost implements OpenCodeHost {
  ManagedOpenCodeHost({
    required OpenCodeConfiguration configuration,
    required JsonHttpTransport transport,
  })  : _configuration = configuration,
        _transport = transport;

  final OpenCodeConfiguration _configuration;
  final JsonHttpTransport _transport;
  Process? _ownedProcess;
  Future<void>? _startup;

  @override
  Future<ProviderHealth> health() async {
    try {
      final Object? payload = await _transport.send(
        method: 'GET',
        uri: _configuration.baseUri.resolve('/global/health'),
        timeout: const Duration(seconds: 2),
      );
      if (payload is Map<Object?, Object?> && payload['healthy'] == true) {
        return ProviderHealth(
          available: true,
          version: payload['version'] as String?,
        );
      }
      return const ProviderHealth(
        available: false,
        message: 'OpenCode não respondeu como saudável.',
      );
    } on Object catch (error) {
      return ProviderHealth(available: false, message: '$error');
    }
  }

  @override
  Future<void> ensureReady() async {
    if ((await health()).available) return;
    _startup ??= _start().whenComplete(() => _startup = null);
    await _startup;
  }

  Future<void> _start() async {
    if (_ownedProcess == null) {
      final Process process = await Process.start(
        _configuration.executable,
        <String>[
          'serve',
          '--hostname',
          _configuration.host,
          '--port',
          '${_configuration.port}',
        ],
        workingDirectory: _configuration.workspaceDirectory,
        runInShell: Platform.isWindows,
      );
      _ownedProcess = process;
      unawaited(process.stdout.drain<void>());
      unawaited(process.stderr.drain<void>());
      unawaited(
        process.exitCode.then((int _) {
          if (identical(_ownedProcess, process)) _ownedProcess = null;
        }),
      );
    }

    final DateTime deadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(deadline)) {
      final ProviderHealth status = await health();
      if (status.available) return;
      if (_ownedProcess == null) {
        throw StateError(
          'O processo OpenCode encerrou antes de iniciar o servidor.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError(
      'OpenCode não iniciou em ${_configuration.baseUri} dentro de 15 segundos.',
    );
  }

  @override
  Future<void> close() async {
    final Process? process = _ownedProcess;
    _ownedProcess = null;
    if (process == null) return;
    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
    }
  }
}
