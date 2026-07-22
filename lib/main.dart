import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/workspace/presentation/workspace_screen.dart';
import 'features/ai/domain/retention_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    } catch (e) {
      debugPrint('Error al inicializar Supabase: $e');
    }
  } else {
    debugPrint('⚠️ SUPABASE_URL o SUPABASE_ANON_KEY no definidas — auth desactivado');
  }

  RetentionService().start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => _showBetaBannerIfFirstTime());
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authService = context.read<AuthService>();

    return MaterialApp(
      title: 'Norm',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: StreamBuilder<User?>(
        stream: authService.authStateStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xff9d4edd)),
              ),
            );
          }

          final user = snapshot.data;
          if (user != null) {
            return const WorkspaceScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
