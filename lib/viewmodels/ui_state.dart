/// Estados posibles para las vistas de la interfaz de usuario.
enum UiStatus {
  initial,
  loading,
  success,
  error,
  noInternet,
}

/// Envoltorio genérico inmutable que encapsula el estado de una petición o flujo de datos.
class UiState<T> {
  final UiStatus status;
  final T? data;
  final String? message;

  const UiState._({
    required this.status,
    this.data,
    this.message,
  });

  const UiState.initial() : this._(status: UiStatus.initial);

  const UiState.loading([String? message])
      : this._(
          status: UiStatus.loading,
          message: message ?? 'Cargando información...',
        );

  const UiState.success(T data)
      : this._(
          status: UiStatus.success,
          data: data,
        );

  const UiState.error(String message, {T? previousData})
      : this._(
          status: UiStatus.error,
          message: message,
          data: previousData,
        );

  const UiState.noInternet({
    String message = 'Sin conexión a Internet. Verifica tu red Wi-Fi o datos móviles.',
    T? previousData,
  }) : this._(
          status: UiStatus.noInternet,
          message: message,
          data: previousData,
        );

  bool get isInitial => status == UiStatus.initial;
  bool get isLoading => status == UiStatus.loading;
  bool get isSuccess => status == UiStatus.success;
  bool get isError => status == UiStatus.error;
  bool get isNoInternet => status == UiStatus.noInternet;
  bool get hasData => data != null;

  @override
  String toString() => 'UiState(status: $status, data: $data, message: $message)';
}
