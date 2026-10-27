import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/api_exceptions.dart';
import '../services/api_service.dart';
import 'ui_state.dart';

/// ViewModel que gestiona la lógica de presentación para la lista de usuarios y favoritos.
/// Notifica a la interfaz de usuario ante cambios en los estados de carga, éxito o error.
class UsersViewModel extends ChangeNotifier {
  final UserRepository _repository;

  UsersViewModel({UserRepository? repository})
      : _repository = repository ?? UserRepository();

  UserRepository get repository => _repository;

  UiState<List<UserModel>> _usersState = const UiState.initial();
  UiState<List<UserModel>> get usersState => _usersState;

  UiState<List<UserModel>> _favoritesState = const UiState.initial();
  UiState<List<UserModel>> get favoritesState => _favoritesState;

  Set<int> _favoriteIds = {};
  Set<int> get favoriteIds => _favoriteIds;

  NetworkSimulationMode get simulationMode => _repository.simulationMode;

  /// Cambia el modo de simulación de red para facilitar pruebas y capturas académicas.
  void setSimulationMode(NetworkSimulationMode mode) {
    _repository.simulationMode = mode;
    notifyListeners();
  }

  /// Carga la lista de usuarios desde la API y sincroniza los favoritos locales.
  Future<void> fetchUsers() async {
    _usersState = const UiState.loading('Consultando directorio de usuarios...');
    notifyListeners();

    try {
      // Cargamos favoritos simultáneamente para conocer qué usuarios están marcados
      await _refreshFavoriteIds();

      final users = await _repository.getUsers();
      _usersState = UiState.success(users);
    } on NoInternetException catch (e) {
      _usersState = UiState.noInternet(message: e.message);
    } on TimeoutApiException catch (e) {
      _usersState = UiState.error(e.message);
    } on AppException catch (e) {
      _usersState = UiState.error(e.message);
    } catch (e) {
      _usersState = UiState.error('Error inesperado al cargar usuarios: $e');
    }

    notifyListeners();
  }

  /// Carga la lista de favoritos directamente desde la base de datos local SQLite.
  /// No requiere conexión a internet y opera 100% offline.
  Future<void> fetchFavorites() async {
    _favoritesState = const UiState.loading('Cargando usuarios favoritos locales...');
    notifyListeners();

    try {
      final favorites = await _repository.getFavoriteUsers();
      _favoriteIds = favorites.map((u) => u.id).toSet();
      _favoritesState = UiState.success(favorites);
    } catch (e) {
      _favoritesState = UiState.error('Error al consultar SQLite: $e');
    }

    notifyListeners();
  }

  /// Alterna el estado de favorito de un usuario y actualiza tanto SQLite como el estado en memoria.
  Future<bool> toggleFavorite(UserModel user) async {
    final bool isNowFavorite = await _repository.toggleFavorite(user);

    if (isNowFavorite) {
      _favoriteIds.add(user.id);
    } else {
      _favoriteIds.remove(user.id);
    }

    // Refrescamos la lista de favoritos offline para mantener sincronización
    await fetchFavorites();

    notifyListeners();
    return isNowFavorite;
  }

  /// Elimina un usuario de favoritos directamente por ID.
  Future<void> removeFavorite(int userId) async {
    await _repository.removeFavorite(userId);
    _favoriteIds.remove(userId);
    await fetchFavorites();
    notifyListeners();
  }

  /// Verifica si un usuario con [userId] está en favoritos.
  bool isUserFavorite(int userId) {
    return _favoriteIds.contains(userId);
  }

  /// Actualiza internamente el conjunto de IDs de favoritos.
  Future<void> _refreshFavoriteIds() async {
    try {
      _favoriteIds = await _repository.getFavoriteIds();
    } catch (_) {
      // No interrumpimos la carga de la API si la base de datos aún no ha inicializado
    }
  }
}
