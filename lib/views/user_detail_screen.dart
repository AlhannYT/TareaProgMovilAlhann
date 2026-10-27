import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../viewmodels/ui_state.dart';
import '../viewmodels/user_detail_viewmodel.dart';
import 'widgets/post_card.dart';
import 'widgets/state_views.dart';

/// Pantalla de Detalle de Usuario (`UserDetailScreen`).
/// Presenta los datos completos del perfil del usuario (disponibles en memoria)
/// y orquesta la carga asíncrona independiente de sus publicaciones desde la API.
class UserDetailScreen extends StatefulWidget {
  final UserModel user;
  final UserRepository? repository;
  final VoidCallback? onFavoriteChanged;

  const UserDetailScreen({
    super.key,
    required this.user,
    this.repository,
    this.onFavoriteChanged,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late final UserDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UserDetailViewModel(
      user: widget.user,
      repository: widget.repository,
    );

    // Conectamos el ViewModel al ciclo de vida del Widget para reconstruir la vista
    _viewModel.addListener(_onViewModelUpdate);

    // Inicialización asíncrona: consulta estado de favoritos y descarga publicaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel.init();
    });
  }

  void _onViewModelUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdate);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleToggleFavorite() async {
    await _viewModel.toggleFavorite();
    if (!mounted) return;

    widget.onFavoriteChanged?.call();

    final bool isFav = _viewModel.isFavorite;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav
              ? 'Usuario "${widget.user.name}" guardado en Favoritos Offline.'
              : 'Usuario "${widget.user.name}" eliminado de Favoritos.',
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
    final user = widget.user;
    final postsState = _viewModel.postsState;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            icon: Icon(
              _viewModel.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _viewModel.isFavorite ? Colors.amber.shade700 : null,
              size: 28,
            ),
            tooltip: _viewModel.isFavorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
            onPressed: _handleToggleFavorite,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _viewModel.fetchPosts();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Tarjeta superior con datos del perfil del usuario
            SliverToBoxAdapter(
              child: _buildProfileCard(context, user, colorScheme, theme),
            ),

            // Encabezado de la sección de publicaciones
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Publicaciones del Usuario',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (postsState.isSuccess && postsState.hasData)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${postsState.data!.length} posts',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Contenido dinámico de las publicaciones según el estado de la UI
            _buildPostsContentSliver(postsState),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    UserModel user,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${user.username} (ID: ${user.id})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _buildDetailRow(
              icon: Icons.email_outlined,
              label: 'Correo Electrónico',
              value: user.email,
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: user.phone,
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.language_outlined,
              label: 'Sitio Web',
              value: user.website,
              colorScheme: colorScheme,
              theme: theme,
            ),
            if (user.companyName.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.business_outlined,
                label: 'Compañía',
                value: user.companyName,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _handleToggleFavorite,
                icon: Icon(
                  _viewModel.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _viewModel.isFavorite ? Colors.amber.shade800 : null,
                ),
                label: Text(
                  _viewModel.isFavorite ? 'Guardado en Favoritos Offline' : 'Guardar en Favoritos Offline',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value.isNotEmpty ? value : 'No disponible',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsContentSliver(UiState<List<dynamic>> postsState) {
    switch (postsState.status) {
      case UiStatus.initial:
      case UiStatus.loading:
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: LoadingView(message: 'Cargando publicaciones desde la API...'),
          ),
        );

      case UiStatus.noInternet:
        return SliverToBoxAdapter(
          child: ErrorStateView(
            isNoInternet: true,
            message: postsState.message,
            onRetry: () => _viewModel.fetchPosts(),
          ),
        );

      case UiStatus.error:
        return SliverToBoxAdapter(
          child: ErrorStateView(
            isNoInternet: false,
            message: postsState.message,
            onRetry: () => _viewModel.fetchPosts(),
          ),
        );

      case UiStatus.success:
        final posts = _viewModel.postsState.data ?? [];
        if (posts.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('Este usuario no tiene publicaciones disponibles.'),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                index: index + 1,
              );
            },
            childCount: posts.length,
          ),
        );
    }
  }
}
