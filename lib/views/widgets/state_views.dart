import 'package:flutter/material.dart';

/// Vista de estado de carga con indicador circular y mensaje descriptivo.
class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({
    super.key,
    this.message = 'Cargando datos...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de estado de error o sin conexión a internet.
/// Incluye ícono visual, mensaje amigable, botón de reintento y acceso directo a favoritos offline.
class ErrorStateView extends StatelessWidget {
  final bool isNoInternet;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback? onOpenOfflineFavorites;

  const ErrorStateView({
    super.key,
    required this.isNoInternet,
    required this.onRetry,
    this.message,
    this.onOpenOfflineFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon = isNoInternet
        ? Icons.wifi_off_rounded
        : Icons.error_outline_rounded;

    final String title = isNoInternet
        ? 'Sin Conexión a Internet'
        : 'Algo salió mal';

    final String defaultMessage = isNoInternet
        ? 'No se detecta conexión activa. Puedes reintentar o consultar los favoritos almacenados localmente.'
        : 'Ocurrió un problema al comunicarse con el servidor. Por favor intenta de nuevo.';

    final Color iconColor = isNoInternet
        ? (isDark ? Colors.amber.shade300 : Colors.amber.shade800)
        : theme.colorScheme.error;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message ?? defaultMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                if (onOpenOfflineFavorites != null)
                  OutlinedButton.icon(
                    onPressed: onOpenOfflineFavorites,
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    label: const Text('Ver Favoritos Offline'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
