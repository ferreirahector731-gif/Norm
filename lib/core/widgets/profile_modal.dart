import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';

class ProfileModal extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String avatarLetter;

  const ProfileModal({
    super.key,
    this.userName = 'Usuario Pro',
    this.userEmail = 'usuario@norm.ai',
    this.avatarLetter = 'U',
  });

  static Future<void> show(BuildContext context, {
    String userName = 'Usuario Pro',
    String userEmail = 'usuario@norm.ai',
    String avatarLetter = 'U',
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => ProfileModal(
        userName: userName,
        userEmail: userEmail,
        avatarLetter: avatarLetter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normTheme = context.read<ThemeProvider>().theme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(normTheme.cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: normTheme.liquidBlur, sigmaY: normTheme.liquidBlur),
          child: Container(
            width: 400,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer.withOpacity(0.95),
              borderRadius: BorderRadius.circular(normTheme.cardRadius),
              border: Border.all(color: scheme.outline.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 32, spreadRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildProfileCard(context),
                const SizedBox(height: 16),
                _buildStorageMetrics(context),
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary,
            boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.6), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Perfil de Usuario & Estado de Almacenamiento',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: scheme.primary,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.close, size: 16, color: scheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normTheme = context.read<ThemeProvider>().theme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(normTheme.innerRadius),
        border: Border.all(color: scheme.outline.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(normTheme.innerMostRadius),
              border: Border.all(color: scheme.primary.withOpacity(0.5), width: 2),
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'PRO ACTIVE',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 12, color: const Color(0xFF34D399)),
                    const SizedBox(width: 4),
                    Text(
                      'Motor Offline Gemma Activo',
                      style: TextStyle(fontSize: 10, color: const Color(0xFF34D399), fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageMetrics(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normTheme = context.read<ThemeProvider>().theme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(normTheme.innerRadius),
        border: Border.all(color: scheme.outline.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estadísticas de Memoria Local',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: scheme.onSurface,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Text(
                '12.4 KB / 5.0 MB',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: const Color(0xFF34D399),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(normTheme.innerMostRadius),
                    border: Border.all(color: scheme.outline.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total de Notas', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(normTheme.innerMostRadius),
                    border: Border.all(color: scheme.outline.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sincronización', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('Supabase Sync', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scheme.primary, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Capacidad Local (LocalFirst):', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                  Text('1% utilizado', style: TextStyle(fontSize: 10, color: const Color(0xFF34D399))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  color: scheme.surfaceContainerLow,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.01,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final normTheme = context.read<ThemeProvider>().theme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Respaldo exportado'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Icons.download, size: 14),
            label: const Text('Exportar JSON'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(normTheme.innerMostRadius)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sincronización completada'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Icons.sync, size: 14),
            label: const Text('Sincronizar'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF090A0C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(normTheme.innerMostRadius)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
