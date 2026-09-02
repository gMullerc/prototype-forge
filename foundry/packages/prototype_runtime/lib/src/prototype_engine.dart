import 'package:prototype_spec/prototype_spec.dart';

import 'component_contract.dart';
import 'prototype_validator.dart';

enum PrototypeStatus {
  idle,
  ready,
  invalid,
}

class PrototypeSnapshot {
  const PrototypeSnapshot({
    required this.status,
    required this.rawResponse,
    this.document,
    this.issues = const <ValidationIssue>[],
  });

  const PrototypeSnapshot.idle()
      : status = PrototypeStatus.idle,
        rawResponse = '',
        document = null,
        issues = const <ValidationIssue>[];

  final PrototypeStatus status;
  final String rawResponse;
  final PrototypeDocument? document;
  final List<ValidationIssue> issues;
}

class PrototypeEngine {
  PrototypeEngine({
    required this.catalog,
    PrototypeSpecDecoder decoder = const PrototypeSpecDecoder(),
    PrototypeValidator validator = const PrototypeValidator(),
  })  : _decoder = decoder,
        _validator = validator;

  final PrototypeCatalog catalog;
  final PrototypeSpecDecoder _decoder;
  final PrototypeValidator _validator;

  PrototypeSnapshot load(String rawResponse) {
    PrototypeDocument document;
    try {
      document = _decoder.decode(rawResponse);
    } on PrototypeSpecException catch (error) {
      return PrototypeSnapshot(
        status: PrototypeStatus.invalid,
        rawResponse: rawResponse,
        issues: <ValidationIssue>[
          ValidationIssue(
            code: 'decode_error',
            path: error.path,
            message: error.message,
          ),
        ],
      );
    }

    final List<ValidationIssue> issues = _validator.validate(document, catalog);
    return PrototypeSnapshot(
      status: issues.isEmpty ? PrototypeStatus.ready : PrototypeStatus.invalid,
      rawResponse: rawResponse,
      document: document,
      issues: issues,
    );
  }
}
