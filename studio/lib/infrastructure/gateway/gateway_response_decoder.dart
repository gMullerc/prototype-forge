import 'dart:convert';

import 'package:prototype_gateway_client/prototype_gateway_client.dart';

Map<String, Object?> decodeGatewayResponse({
  required int statusCode,
  required String body,
}) {
  Object? decoded;
  if (body.trim().isNotEmpty) {
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw GatewayTransportException(
        statusCode: statusCode,
        message: 'O gateway local respondeu com conteúdo inválido.',
      );
    }
  }
  if (statusCode < 200 || statusCode >= 300) {
    String code = 'gateway_error';
    String message = 'O gateway local respondeu HTTP $statusCode.';
    if (decoded is Map<Object?, Object?>) {
      final Object? error = decoded['error'];
      if (error is Map<Object?, Object?>) {
        if (error['code'] is String) code = error['code']! as String;
        if (error['message'] is String) {
          message = error['message']! as String;
        }
      }
    }
    throw GatewayTransportException(
      statusCode: statusCode,
      code: code,
      message: message,
    );
  }
  if (decoded is! Map<Object?, Object?>) {
    throw GatewayTransportException(
      statusCode: statusCode,
      message: 'O gateway local não retornou um objeto JSON.',
    );
  }
  return <String, Object?>{
    for (final MapEntry<Object?, Object?> entry in decoded.entries)
      if (entry.key is String) entry.key! as String: entry.value,
  };
}
