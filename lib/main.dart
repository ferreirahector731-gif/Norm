import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'core/services/sync_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/workspace/presentation/workspace_screen.dart';
import 'features/ai/domain/retention_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Iniciar limpieza programada de mensajes de chat
  RetentionService().start();

  await Supabase.initialize(
    url: 'https://rwwebuzczalzzuxkdlwc.supabase.co',
    publishableKey: 'sb_publishable_HzlyJuP_B4-q6gvFkchXFA_AWM_7knL',
  );

  // Iniciar escucha de conectividad para sincronización en segundo plano
  SyncManager().startListening();
  // Traer cambios remotos al arrancar si hay conexión
  SyncManager().fetchRemoteChanges();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );

  // ─── Banner Beta (solo primera vez) ──────────────────────────────────
  WidgetsBinding.instance.addPostFrameCallback((_) => _showBetaBannerIfFirstTime());

  // ─── Auto‑update (preparado para futura versión) ──────────────────────
  // if (false) {
  //   _checkForUpdates();
  // }
}

Future<void> _showBetaBannerIfFirstTime() async {
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('beta_banner_seen') ?? false;
  if (seen) return;
  await prefs.setBool('beta_banner_seen', true);
  if (!_navigatorKey.currentContext!.mounted) return;
  showDialog(
    context: _navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Beta'),
      content: const Text(
        'Estás usando Norm en fase Beta.\n\n'
        'Algunas funciones pueden cambiar o mejorar con el tiempo. '
        'Gracias por ayudarnos a construir la mejor experiencia.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

// ─── Auto‑update: consulta GitHub Releases ─────────────────────────────
// Future<void> _checkForUpdates() async {
//   try {
//     final pkg = await PackageInfo.fromPlatform();
//     final localVer = pkg.version;
//     final res = await http.get(
//       Uri.parse('https://api.github.com/repos/ferreirahector731-gif/Norm/releases/latest'),
//       headers: {'Accept': 'application/vnd.github.v3+json'},
//     );
//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body) as Map<String, dynamic>;
//       final latestTag = data['tag_name'] as String? ?? '';
//       final latestVer = latestTag.replaceAll(RegExp(r'^v'), '');
//       if (_compareVersions(latestVer, localVer) > 0) {
//         debugPrint('Nueva versión disponible: $latestVer');
//         // TODO: mostrar notificación al usuario
//       }
//     }
//   } catch (e) {
//     debugPrint('Error checking updates: $e');
//   }
// }
//
// int _compareVersions(String a, String b) {
//   final partsA = a.split('.').map(int.parse).toList();
//   final partsB = b.split('.').map(int.parse).toList();
//   for (int i = 0; i < 3; i++) {
//     final cmp = (partsA[i] ?? 0).compareTo(partsB[i] ?? 0);
//     if (cmp != 0) return cmp;
//   }
//   return 0;
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authService = context.read<AuthService>();

    return MaterialApp(
      title: 'nota_ia',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: StreamBuilder<AuthState>(
        stream: authService.authStateStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xff9d4edd)),
              ),
            );
          }

          final session = snapshot.data?.session;
          if (session != null) {
            return const WorkspaceScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
