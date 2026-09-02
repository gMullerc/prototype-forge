abstract interface class GatewayTransport {
  Future<Map<String, Object?>> getJson(String path);

  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  );
}

class GatewayTransportException implements Exception {
  const GatewayTransportException({
    required this.message,
    this.code = 'transport_error',
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
