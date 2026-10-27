import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../viewmodels/ui_state.dart';
import '../viewmodels/users_viewmodel.dart';
import 'user_detail_screen.dart';
import 'widgets/state_views.dart';
import 'widgets/user_card.dart';

/// Pantalla Principal con dos pestañas:
/// 1. Directorio (Online): Consumo de JSONPlaceholder API.
/// 2. Favoritos (Offline): Persistencia en SQLite 100% independiente de internet.
class HomeScreen extends StatefulWidget {
  final UserRepository? repository;

  const HomeScreen({
    super.key,
    this.repository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final UsersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UsersViewModel(repository: widget.repository);
    _viewModel.addListener(_onViewModelChange);

    // Carga inicial de datos asegurando la verificación de mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel.fetchUsers();
      _viewModel.fetchFavorites();
    });
  }

  void _onViewModelChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateToDetail(UserModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          user: user,
          repository: _viewModel.repository,
          onFavoriteChanged: () {
            // Sincroniza el listado principal al volver
            _viewModel.fetchFavorites();
          },
        ),
      ),
    );
  }

  Future<void> _handleToggleFavorite(UserModel user) async {
    final bool isNowFavorite = await _viewModel.toggleFavorite(user);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNowFavorite
              ? '★ "${user.name}" guardado en Favoritos Offline'
              : '☆ "${user.name}" removido de Favoritos',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentSimulation = _viewModel.simulationMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Directorio de Usuarios' : 'Favoritos (Offline SQLite)',
        ),
        elevation: 0,
        actions: [
          // Selector para simular estados de red / error (ideal para pruebas y capturas académicas)
          PopupMenuButton<NetworkSimulationMode>(
            icon: Badge(
              isLabelVisible: currentSimulation != NetworkSimulationMode.none,
              backgroundColor: currentSimulation == NetworkSimulationMode.offline
                  ? Colors.orange
                  : Colors.red,
              child: const Icon(Icons.settings_ethernet_rounded),
            ),
            tooltip: 'Simular Estado de Red / Fallos',
            initialValue: currentSimulation,
            onSelected: (mode) {
              _viewModel.setSimulationMode(mode);
              _viewModel.fetchUsers();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: NetworkSimulationMode.none,
                child: Row(
                  children: [
                    Icon(Icons.wifi_rounded, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Modo Normal (Online)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NetworkSimulationMode.offline,
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Simular Sin Red (Offline)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NetworkSimulationMode.serverError,
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Simular Error Servidor (500)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NetworkSimulationMode.timeout,
                child: Row(
                  children: [
                    Icon(Icons.timer_off_rounded, color: Colors.purple),
                    SizedBox(width: 12),
                    Text('Simular Timeout (Espera)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
            onPressed: () {
              if (_currentIndex == 0) {
                _viewModel.fetchUsers();
              } else {
                _viewModel.fetchFavorites();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner discreto de modo simulado activo
          if (currentSimulation != NetworkSimulationMode.none)
            Container(
              width: double.infinity,
              color: currentSimulation == NetworkSimulationMode.offline
                  ? Colors.orange.shade800
                  : Colors.red.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentSimulation == NetworkSimulationMode.offline
                          ? 'Modo Simulado: Sin Red activo'
                          : 'Modo Simulado: Fallo activo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _viewModel.setSimulationMode(NetworkSimulationMode.none);
                      _viewModel.fetchUsers();
                    },
                    child: const Text(
                      'RESTAURAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Contenido principal de la pestaña seleccionada
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildDirectoryTab(),
                _buildFavoritesTab(colorScheme, theme),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            _viewModel.fetchFavorites();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Directorio',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Favoritos Offline',
          ),
        ],
      ),
    );
  }

  /// Pestaña 1: Directorio de Usuarios obtenido desde la API
  Widget _buildDirectoryTab() {
    final usersState = _viewModel.usersState;

    switch (usersState.status) {
      case UiStatus.initial:
      case UiStatus.loading:
        return LoadingView(
          message: usersState.message ?? 'Consultando directorio de usuarios...',
        );

      case UiStatus.noInternet:
        return ErrorStateView(
          isNoInternet: true,
          message: usersState.message,
          onRetry: () => _viewModel.fetchUsers(),
          onOpenOfflineFavorites: () {
            setState(() {
              _currentIndex = 1;
            });
            _viewModel.fetchFavorites();
          },
        );

      case UiStatus.error:
        return ErrorStateView(
          isNoInternet: false,
          message: usersState.message,
          onRetry: () => _viewModel.fetchUsers(),
          onOpenOfflineFavorites: () {
            setState(() {
              _currentIndex = 1;
            });
            _viewModel.fetchFavorites();
          },
        );

      case UiStatus.success:
        final users = usersState.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text('No se encontraron usuarios en el directorio.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _viewModel.fetchUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isFavorite = _viewModel.isUserFavorite(user.id);
              return UserCard(
                user: user,
                isFavorite: isFavorite,
                onToggleFavorite: () => _handleToggleFavorite(user),
                onTap: () => _navigateToDetail(user),
              );
            },
          ),
        );
    }
  }

  /// Pestaña 2: Usuarios Favoritos persistidos en SQLite (Modo Offline)
  Widget _buildFavoritesTab(ColorScheme colorScheme, ThemeData theme) {
    final favoritesState = _viewModel.favoritesState;

    if (favoritesState.isLoading) {
      return const LoadingView(
        message: 'Accediendo a la base de datos local SQLite...',
      );
    }

    if (favoritesState.isError) {
      return ErrorStateView(
        isNoInternet: false,
        message: favoritesState.message,
        onRetry: () => _viewModel.fetchFavorites(),
      );
    }

    final favorites = favoritesState.data ?? [];

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_border_rounded,
                  size: 56,
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sin favoritos guardados',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Marca usuarios con la estrella en el Directorio para acceder a sus datos sin necesidad de conexión a Internet.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('Explorar Directorio'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _viewModel.fetchFavorites(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final user = favorites[index];
          return Dismissible(
            key: Key('fav_${user.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: colorScheme.error,
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
            ),
            onDismissed: (_) {
              _viewModel.removeFavorite(user.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${user.name}" eliminado de favoritos.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: UserCard(
              user: user,
              isFavorite: true,
              onToggleFavorite: () => _handleToggleFavorite(user),
              onTap: () => _navigateToDetail(user),
            ),
          );
        },
      ),
    );
  }
}
