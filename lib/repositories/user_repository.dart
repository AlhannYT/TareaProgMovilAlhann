import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

/// Repositorio que unifica y coordina la obtención de datos remotos (API)
/// y la persistencia local offline (SQLite).
class UserRepository {
  final ApiService _apiService;
  final DatabaseHelper _databaseHelper;

  UserRepository({
    ApiService? apiService,
    DatabaseHelper? databaseHelper,
  })  : _apiService = apiService ?? ApiService(),
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  ApiService get apiService => _apiService;
  DatabaseHelper get databaseHelper => _databaseHelper;

  NetworkSimulationMode get simulationMode => _apiService.simulationMode;
  set simulationMode(NetworkSimulationMode mode) {
    _apiService.simulationMode = mode;
  }

  /// Consulta la lista de usuarios desde la API.
  Future<List<UserModel>> getUsers() async {
    return await _apiService.fetchUsers();
  }

  /// Consulta las publicaciones de un usuario desde la API.
  Future<List<PostModel>> getUserPosts(int userId) async {
    return await _apiService.fetchPostsByUser(userId);
  }

  /// Recupera los usuarios favoritos almacenados en la base de datos local SQLite.
  Future<List<UserModel>> getFavoriteUsers() async {
    return await _databaseHelper.getFavorites();
  }

  /// Retorna un conjunto de IDs con todos los usuarios actualmente en favoritos.
  Future<Set<int>> getFavoriteIds() async {
    final favorites = await _databaseHelper.getFavorites();
    return favorites.map((u) => u.id).toSet();
  }

  /// Comprueba si un usuario determinado está marcado como favorito.
  Future<bool> isFavorite(int userId) async {
    return await _databaseHelper.isFavorite(userId);
  }

  /// Alterna el estado de favorito de un usuario (inserta o elimina de SQLite).
  /// Retorna `true` si quedó guardado como favorito, `false` si fue eliminado.
  Future<bool> toggleFavorite(UserModel user) async {
    final bool alreadyFavorite = await _databaseHelper.isFavorite(user.id);
    if (alreadyFavorite) {
      await _databaseHelper.removeFavorite(user.id);
      return false;
    } else {
      await _databaseHelper.insertFavorite(user);
      return true;
    }
  }

  /// Agrega un usuario a favoritos.
  Future<void> addFavorite(UserModel user) async {
    await _databaseHelper.insertFavorite(user);
  }

  /// Elimina un usuario de favoritos.
  Future<void> removeFavorite(int userId) async {
    await _databaseHelper.removeFavorite(userId);
  }
}
