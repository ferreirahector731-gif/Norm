import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'profile_modal.dart';
import 'doc_modal.dart';
import 'lock_screen.dart';

class UserAvatarMenu extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String avatarLetter;

  const UserAvatarMenu({
    super.key,
    this.userName = 'Usuario Pro',
    this.userEmail = 'usuario@norm.ai',
    this.avatarLetter = 'U',
  });

  @override
  State<UserAvatarMenu> createState() => _UserAvatarMenuState();
}

class _UserAvatarMenuState extends State<UserAvatarMenu> {
  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);
  void _close() => setState(() => _isOpen = false);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normTheme = context.watch<ThemeProvider>().theme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: _isOpen
                  ? [BoxShadow(color: scheme.primary.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]
                  : [],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
              ),
              child: Center(
                child: Text(
                  widget.avatarLetter,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isOpen)
          Positioned(
            right: 0,
            top: 40,
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(normTheme.cardRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: normTheme.liquidBlur,
                    sigmaY: normTheme.liquidBlur,
                  ),
                  child: Container(
                    width: 256,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(normTheme.cardRadius),
                      border: Border.all(
                        color: scheme.outline.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(normTheme.innerRadius),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserHeader(context),
                        const SizedBox(height: 8),
                        _buildDivider(context),
                        const SizedBox(height: 4),
                        _buildMenuItem(
                          context,
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF38BDF8),
                          label: 'Mi Perfil',
                          onTap: () {
                            _close();
                            ProfileModal.show(context,
                              userName: widget.userName,
                              userEmail: widget.userEmail,
                              avatarLetter: widget.avatarLetter,
                            );
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.palette_outlined,
                          iconColor: const Color(0xFF34D399),
                          label: 'Ajustes del Sistema (Temas)',
                          onTap: () {
                            _close();
                            showSettings(context);
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFFFBBF24),
                          label: 'Documentación',
                          onTap: () {
                            _close();
                            DocModal.show(context);
                          },
                        ),
                        const SizedBox(height: 4),
                        _buildDivider(context),
                        const SizedBox(height: 4),
                        _buildMenuItem(
                          context,
                          icon: Icons.logout,
                          iconColor: const Color(0xFFFB7185),
                          label: 'Cerrar Sesión',
                          isDestructive: true,
                          onTap: () {
                            _close();
                            LockScreen.show(context, onUnlock: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Sesión reanudada'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
            ),
          ),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withOpacity(0.15),
              border: Border.all(color: scheme.primary.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                widget.avatarLetter,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.userEmail,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 0.5,
      color: scheme.outline.withOpacity(0.4),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final normTheme = context.read<ThemeProvider>().theme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(normTheme.innerMostRadius),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? const Color(0xFFFB7185) : scheme.onSurface,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
