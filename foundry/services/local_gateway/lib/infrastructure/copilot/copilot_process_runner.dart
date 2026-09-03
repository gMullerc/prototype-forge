import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CopilotProcessResult {
  const CopilotProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class CopilotProcessTimeout implements Exception {
  const CopilotProcessTimeout();
}

abstract interface class CopilotProcessRunner {
  Future<CopilotProcessResult> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
  });

  Future<void> close();
}

class DartCopilotProcessRunner implements CopilotProcessRunner {
  final Set<Process> _processes = <Process>{};

  @override
  Future<CopilotProcessResult> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
  }) async {
    final Process process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
    _processes.add(process);
    try {
      final Future<String> stdout = utf8.decoder.bind(process.stdout).join();
      final Future<String> stderr = utf8.decoder.bind(process.stderr).join();
      final List<Object> result = await Future.wait<Object>(<Future<Object>>[
        process.exitCode,
        stdout,
        stderr,
      ]).timeout(timeout);
      return CopilotProcessResult(
        exitCode: result[0] as int,
        stdout: result[1] as String,
        stderr: result[2] as String,
      );
    } on TimeoutException {
      process.kill();
      throw const CopilotProcessTimeout();
    } finally {
      _processes.remove(process);
    }
  }

  @override
  Future<void> close() async {
    for (final Process process in _processes.toList()) {
      process.kill();
    }
    _processes.clear();
  }
}
