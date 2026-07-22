import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/auth_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded, size: 80, color: scheme.primary),
              const SizedBox(height: 24),
              Text(
                'Norm',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tus notas con inteligencia local',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 56),
              SizedBox(
                width: 280,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _signInWithGoogle(context),
                  icon: Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 20,
                    width: 20,
                  ),
                  label: const Text('Continuar con Google'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 280,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showEmailDialog(context, isRegister: false),
                  icon: const Icon(Icons.email_outlined, size: 20),
                  label: const Text('Iniciar sesión'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 280,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showEmailDialog(context, isRegister: true),
                  icon: const Icon(Icons.person_add_outlined, size: 20),
                  label: const Text('Registrarse'),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Expanded(child: Divider(color: scheme.outlineVariant.withOpacity(0.4))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: scheme.outlineVariant.withOpacity(0.4))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                height: 48,
                child: TextButton.icon(
                  onPressed: () => _continueAsGuest(context),
                  icon: Icon(Icons.person_outline, size: 20, color: scheme.onSurfaceVariant),
                  label: Text(
                    'Continuar como Invitado',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final authService = context.read<AuthService>();
    final error = await authService.signInWithGoogle();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _continueAsGuest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Modo Invitado',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Atención: En modo invitado, tus notas y pizarrones se guardan '
          'exclusivamente en la memoria local de este dispositivo. Si '
          'desinstalas la app o cambias de equipo, no podrás recuperar '
          'tus datos. Para sincronización en la nube, inicia sesión.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Entendido, continuar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthService>().setGuestMode();
    }
  }

  Future<void> _showEmailDialog(BuildContext context, {required bool isRegister}) async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isRegister ? 'Crear cuenta' : 'Iniciar sesión',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: Text(isRegister ? 'Registrarse' : 'Iniciar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authService = context.read<AuthService>();
      try {
        if (isRegister) {
          await authService.signUpWithEmail(emailCtrl.text, passCtrl.text);
        } else {
          await authService.signInWithEmail(emailCtrl.text, passCtrl.text);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }

    emailCtrl.dispose();
    passCtrl.dispose();
  }
}
