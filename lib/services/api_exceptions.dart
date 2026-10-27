/// Jerarquía de excepciones personalizadas de la aplicación.
/// Permite capturar errores de red y de servidor para presentarlos al usuario
/// con mensajes claros, evitando que la app sufra cierres abruptos (crashes).
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Lanzada cuando el dispositivo no tiene acceso a internet (ej. SocketException, ClientException).
class NoInternetException extends AppException {
  const NoInternetException([
    super.message = 'Sin conexión a Internet. Verifica tu conexión de red o activa el Wi-Fi.',
  ]);
}

/// Lanzada cuando la petición excede el tiempo límite de espera configurado (TimeoutException).
class TimeoutApiException extends AppException {
  const TimeoutApiException([
    super.message = 'Tiempo de espera agotado. El servidor tardó demasiado en responder.',
  ]);
}

/// Lanzada cuando el servidor responde con códigos HTTP distintos a 200 (4xx o 5xx).
class ServerApiException extends AppException {
  final int? statusCode;
  const ServerApiException({
    required String message,
    this.statusCode,
  }) : super(message);
}

/// Lanzada cuando la respuesta no se puede deserializar como JSON válido (FormatException).
class FormatApiException extends AppException {
  const FormatApiException([
    super.message = 'Error en el formato de datos devuelto por el servidor.',
  ]);
}

/// Excepción genérica para casos imprevistos controlados.
class UnknownApiException extends AppException {
  const UnknownApiException([
    super.message = 'Ocurrió un error inesperado al procesar la solicitud.',
  ]);
}
