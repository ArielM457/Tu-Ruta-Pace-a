class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}

class ApiConnectionException extends ApiException {
  const ApiConnectionException()
      : super(
          code: 'CONNECTION_ERROR',
          message:
              'No se pudo conectar con el servidor. Revisa tu conexión e intenta de nuevo.',
        );
}
