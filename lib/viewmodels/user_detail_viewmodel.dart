import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/api_exceptions.dart';
import 'ui_state.dart';

/// ViewModel que controla la pantalla de detalle de un usuario,
/// administrando la carga asíncrona e independiente de publicaciones y el estado de favorito.
class UserDetailViewModel extends ChangeNotifier {
  final UserRepository _repository;
  final UserModel user;

  UserDetailViewModel({
    required this.user,
    UserRepository? repository,
  }) : _repository = repository ?? UserRepository();

  UiState<List<PostModel>> _postsState = const UiState.initial();
  UiState<List<PostModel>> get postsState => _postsState;

  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  /// Inicializa los datos del usuario: verifica si es favorito y solicita sus publicaciones.
  Future<void> init() async {
    await checkFavoriteStatus();
    await fetchPosts();
  }

  /// Verifica el estado de favorito en SQLite.
  Future<void> checkFavoriteStatus() async {
    try {
      _isFavorite = await _repository.isFavorite(user.id);
      notifyListeners();
    } catch (_) {}
  }

  /// Carga las publicaciones del usuario desde la API.
  Future<void> fetchPosts() async {
    _postsState = const UiState.loading('Cargando publicaciones del usuario...');
    notifyListeners();

    try {
      final posts = await _repository.getUserPosts(user.id);
      _postsState = UiState.success(posts);
    } on NoInternetException catch (e) {
      _postsState = UiState.noInternet(message: e.message);
    } on TimeoutApiException catch (e) {
      _postsState = UiState.error(e.message);
    } on AppException catch (e) {
      _postsState = UiState.error(e.message);
    } catch (e) {
      _postsState = UiState.error('Error al consultar publicaciones: $e');
    }

    notifyListeners();
  }

  /// Alterna el estado de favorito del usuario actual.
  Future<void> toggleFavorite() async {
    _isFavorite = await _repository.toggleFavorite(user);
    notifyListeners();
  }
}
