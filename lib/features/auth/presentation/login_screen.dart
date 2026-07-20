import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/data/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
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
              const SizedBox(height: 48),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _signInWithGoogle(context),
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 22,
                      width: 22,
                    ),
                    label: const Text('Continuar con Google'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DATA ISOLATION POLICY: El flujo de autenticación conecta directamente
  // el dispositivo con Supabase + Google mediante OAuth2 oficial.
  // No existe servidor intermediario ni filtrado de datos de terceros.
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      await context.read<AuthService>().signInWithGoogle();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
