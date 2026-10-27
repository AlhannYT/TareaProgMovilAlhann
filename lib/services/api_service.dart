import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'api_exceptions.dart';

/// Modos de simulación de red para pruebas y capturas de pantalla.
enum NetworkSimulationMode {
  none,
  offline,
  serverError,
  timeout,
}

/// Servicio encargado del consumo HTTP de la API pública JSONPlaceholder.
/// Implementa timeouts y un manejo exhaustivo de excepciones de red
/// para garantizar la resiliencia de la aplicación.
class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration _defaultTimeout = Duration(seconds: 10);

  final http.Client _client;

  /// Permite forzar estados sin red o errores para propósitos de prueba y demostración académica.
  NetworkSimulationMode simulationMode;

  ApiService({
    http.Client? client,
    this.simulationMode = NetworkSimulationMode.none,
  }) : _client = client ?? http.Client();

  /// Obtiene la lista completa de usuarios desde `/users`.
  ///
  /// Lanza:
  /// - [NoInternetException] si no hay conectividad a Internet.
  /// - [TimeoutApiException] si la petición supera el tiempo límite.
  /// - [FormatApiException] si el JSON de respuesta es inválido.
  /// - [ServerApiException] si el código de estado HTTP no es 200.
  Future<List<UserModel>> fetchUsers() async {
    _checkSimulation();

    final Uri url = Uri.parse('$_baseUrl/users');
    try {
      final response = await _client.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw const FormatApiException('La respuesta de usuarios no es una lista válida.');
        }
      } else {
        throw ServerApiException(
          message: 'Error en el servidor al obtener usuarios (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw const NoInternetException('Sin conexión a Internet. Verifica tu red Wi-Fi o datos móviles.');
    } on http.ClientException {
      throw const NoInternetException('No se pudo establecer conexión con el servidor. Verifica tu conexión.');
    } on TimeoutException {
      throw const TimeoutApiException('Tiempo de espera agotado al consultar usuarios.');
    } on FormatException {
      throw const FormatApiException('Error al procesar el formato de datos de usuarios.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownApiException('Error imprevisto al consultar usuarios: $e');
    }
  }

  /// Obtiene las publicaciones asociadas a un usuario específico desde `/posts?userId={userId}`.
  Future<List<PostModel>> fetchPostsByUser(int userId) async {
    _checkSimulation();

    final Uri url = Uri.parse('$_baseUrl/posts?userId=$userId');
    try {
      final response = await _client.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw const FormatApiException('La respuesta de publicaciones no es una lista válida.');
        }
      } else {
        throw ServerApiException(
          message: 'Error del servidor al obtener publicaciones (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw const NoInternetException('Sin conexión a Internet. No se pudieron cargar las publicaciones.');
    } on http.ClientException {
      throw const NoInternetException('No se pudo establecer conexión para cargar las publicaciones.');
    } on TimeoutException {
      throw const TimeoutApiException('Tiempo de espera agotado al consultar publicaciones.');
    } on FormatException {
      throw const FormatApiException('Error en el formato de datos de publicaciones.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownApiException('Error imprevisto al cargar publicaciones: $e');
    }
  }

  /// Evalúa el modo de simulación activo y lanza la excepción correspondiente si aplica.
  void _checkSimulation() {
    switch (simulationMode) {
      case NetworkSimulationMode.offline:
        throw const NoInternetException(
          'Modo Simulado: Sin conexión a Internet activa en la aplicación.',
        );
      case NetworkSimulationMode.serverError:
        throw const ServerApiException(
          message: 'Modo Simulado: Error interno 500 del servidor JSONPlaceholder.',
          statusCode: 500,
        );
      case NetworkSimulationMode.timeout:
        throw const TimeoutApiException(
          'Modo Simulado: Tiempo de espera agotado (Timeout simulado).',
        );
      case NetworkSimulationMode.none:
        break;
    }
  }

  /// Libera recursos del cliente HTTP si es necesario.
  void close() {
    _client.close();
  }
}
