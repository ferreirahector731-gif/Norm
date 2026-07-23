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
    final normTheme = themeProvider.theme;

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: NormThemeType.values.map((type) {
        final t = type.theme;
        final isSelected = themeProvider.currentTheme == type;
        return GestureDetector(
          onTap: () => themeProvider.setTheme(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.canvasBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? t.accent : t.borderColor,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: t.accent.withOpacity(0.3), blurRadius: 8)]
                  : [],
            ),
            child: Center(
              child: isSelected
                  ? Icon(Icons.check, size: 20, color: t.accent)
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.accent,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: MemoryRetention.values.map((retention) {
        final isSelected = _selected == retention;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: () {
              setState(() => _selected = retention);
              SettingsService.setMemoryRetention(retention);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? scheme.primary.withOpacity(0.4)
                      : scheme.outlineVariant.withOpacity(0.15),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: isSelected ? scheme.primary : scheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    retention.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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
    final authService = context.read<AuthService>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authService.currentUserEmail ?? 'Invitado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      authService.isCloudEnabled
                          ? 'Sesión en la nube'
                          : 'Modo local',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (authService.isCloudEnabled && authService.currentUserEmail != null)
                TextButton(
                  onPressed: () {
                    authService.signOut();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
