import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_service.dart';
import '../services/settings_service.dart';
import '../../ai/domain/retention_service.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings_outlined, color: scheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Ajustes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: scheme.outline, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionLabel(context, 'TEMA'),
              const SizedBox(height: 8),
              _ThemeSelector(),
              const SizedBox(height: 24),
              _buildSectionLabel(context, 'MEMORIA DE IA'),
              const SizedBox(height: 8),
              _MemorySelector(),
              const SizedBox(height: 24),
              _buildSectionLabel(context, 'SESIÓN'),
              const SizedBox(height: 8),
              _SessionInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: scheme.outline,
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _themeCircle(context, ThemeModeType.dark, const Color(0xFF090D16),
            themeProvider.currentTheme == ThemeModeType.dark, () {
          themeProvider.setTheme(ThemeModeType.dark);
        }),
        _themeCircle(context, ThemeModeType.light, const Color(0xFFF5F5F0),
            themeProvider.currentTheme == ThemeModeType.light, () {
          themeProvider.setTheme(ThemeModeType.light);
        }),
        _themeCircle(context, ThemeModeType.sepia, const Color(0xFFF4ECD8),
            themeProvider.currentTheme == ThemeModeType.sepia, () {
          themeProvider.setTheme(ThemeModeType.sepia);
        }),
      ],
    );
  }

  Widget _themeCircle(BuildContext context, ThemeModeType type, Color color,
      bool isSelected, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant.withOpacity(0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: scheme.primary.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: isSelected
            ? Icon(Icons.check, size: 20, color: type == ThemeModeType.dark ? Colors.white : scheme.primary)
            : null,
      ),
    );
  }
}

class _MemorySelector extends StatefulWidget {
  @override
  State<_MemorySelector> createState() => _MemorySelectorState();
}

class _MemorySelectorState extends State<_MemorySelector> {
  MemoryRetention _selected = MemoryRetention.oneMonth;

  @override
  void initState() {
    super.initState();
    _selected = SettingsService.memoryRetention;
  }

  void _onChanged(MemoryRetention value) {
    setState(() => _selected = value);
    SettingsService.setMemoryRetention(value);
    final map = <MemoryRetention, RetentionPeriod>{
      MemoryRetention.oneWeek: RetentionPeriod.week,
      MemoryRetention.oneMonth: RetentionPeriod.month,
      MemoryRetention.threeMonths: RetentionPeriod.threeMonths,
      MemoryRetention.forever: RetentionPeriod.never,
    };
    RetentionService().updatePeriod(map[value] ?? RetentionPeriod.month);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: MemoryRetention.values.map((r) {
        final isSelected = _selected == r;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: GestureDetector(
            onTap: () => _onChanged(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? scheme.primary.withOpacity(0.3) : scheme.outlineVariant.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 16,
                    color: isSelected ? scheme.primary : scheme.outline,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SessionInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authService = context.watch<AuthService>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(
            authService.isGuest
                ? Icons.person_outline
                : authService.isAuthenticated
                    ? Icons.cloud_done_outlined
                    : Icons.person_off_outlined,
            size: 20,
            color: scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authService.isGuest
                      ? 'Modo Invitado'
                      : authService.isAuthenticated
                          ? 'Usuario autenticado'
                          : 'Sin sesión',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  authService.isGuest
                      ? 'Datos solo en este dispositivo'
                      : authService.isAuthenticated
                          ? 'Sincronización en la nube activa'
                          : 'Inicia sesión para sincronizar',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (authService.isGuest || authService.isAuthenticated)
            TextButton(
              onPressed: () => _signOut(context, authService),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
              ),
              child: const Text('Salir', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AuthService authService) async {
    await authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
