const String gatewayProtocolVersion = '1';
const String gatewayHealthPath = '/v1/health';
const String gatewayGeneratePath = '/v1/generate';

class GatewayProtocolException implements FormatException {
  const GatewayProtocolException(this.message, [this.source, this.offset]);

  @override
  final String message;

  @override
  final Object? source;

  @override
  final int? offset;

  @override
  String toString() => 'GatewayProtocolException: $message';
}

Map<String, Object?> gatewayMap(Object? value, String field) {
  if (value is! Map<Object?, Object?>) {
    throw GatewayProtocolException('$field precisa ser um objeto.');
  }
  final Map<String, Object?> result = <String, Object?>{};
  for (final MapEntry<Object?, Object?> entry in value.entries) {
    if (entry.key is! String) {
      throw GatewayProtocolException('$field contém uma chave inválida.');
    }
    result[entry.key! as String] = entry.value;
  }
  return result;
}

String gatewayString(
  Map<String, Object?> source,
  String field, {
  bool allowEmpty = false,
}) {
  final Object? value = source[field];
  if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
    throw GatewayProtocolException('$field precisa ser um texto válido.');
  }
  return value;
}

String? gatewayOptionalString(Map<String, Object?> source, String field) {
  final Object? value = source[field];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw GatewayProtocolException('$field precisa ser um texto válido.');
  }
  return value;
}
