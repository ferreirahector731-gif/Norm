import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String avatarLetter;
  final VoidCallback? onUnlock;

  const LockScreen({
    super.key,
    this.userName = 'Usuario Pro',
    this.userEmail = 'usuario@norm.ai',
    this.avatarLetter = 'U',
    this.onUnlock,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onUnlock}) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (_) => LockScreen(onUnlock: onUnlock),
    );
  }

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordController = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _tryUnlock() {
    if (_passwordController.text.isNotEmpty) {
      Navigator.of(context).pop();
      widget.onUnlock?.call();
    } else {
      setState(() => _showError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normTheme = context.read<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: scheme.surface.withOpacity(0.92),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(context),
                    const SizedBox(height: 24),
                    _buildTitle(context),
                    const SizedBox(height: 24),
                    _buildPasswordField(context, normTheme),
                    const SizedBox(height: 16),
                    _buildUnlockButton(context, normTheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary.withOpacity(0.6), width: 2),
            boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 4)],
          ),
          child: Center(
            child: Text(
              widget.avatarLetter,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEF4444),
            ),
            child: const Center(child: Text('🔒', style: TextStyle(fontSize: 14))),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'Sesión Bloqueada',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Norm v1.8.0 • Local-First Workspace',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withOpacity(0.3)),
          ),
          child: Text(
            widget.userEmail,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context, NormTheme normTheme) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 280,
      child: TextField(
        controller: _passwordController,
        obscureText: true,
        autofocus: true,
        onSubmitted: (_) => _tryUnlock(),
        decoration: InputDecoration(
          hintText: 'Contraseña',
          hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.4)),
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(normTheme.innerRadius),
            borderSide: BorderSide(
              color: _showError ? const Color(0xFFEF4444) : scheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(normTheme.innerRadius),
            borderSide: BorderSide(color: scheme.primary),
          ),
          prefixIcon: Icon(Icons.lock_outline, size: 18, color: scheme.onSurfaceVariant),
          errorText: _showError ? 'Ingresa una contraseña' : null,
        ),
        style: TextStyle(color: scheme.onSurface, fontSize: 14),
      ),
    );
  }

  Widget _buildUnlockButton(BuildContext context, NormTheme normTheme) {
    return SizedBox(
      width: 280,
      child: FilledButton(
        onPressed: _tryUnlock,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF34D399),
          foregroundColor: const Color(0xFF090A0C),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(normTheme.innerRadius)),
          textStyle: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        child: const Text('Desbloquear'),
      ),
    );
  }
}
