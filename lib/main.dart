import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/keyboard_shortcuts.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/workspace/presentation/workspace_screen.dart';
import 'features/ai/domain/retention_service.dart';
import 'features/settings/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool cloudOk = false;

  try {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ).timeout(const Duration(seconds: 3));
      cloudOk = true;
    }
  } catch (e) {
    debugPrint(
        'Advertencia: Supabase no se pudo inicializar ($e). '
        'La app arrancará en modo local.');
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0B0B0F),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Algo salió mal.\nReinicia la app o contacta a soporte.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ),
    );
  };

  await SettingsService.init();
  RetentionService().start();
  _syncRetentionAtStartup();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => AuthService(isCloudEnabled: cloudOk)),
      ],
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => _showBetaBannerIfFirstTime());
}

void _syncRetentionAtStartup() {
  final retention = SettingsService.memoryRetention;
  final map = <MemoryRetention, RetentionPeriod>{
    MemoryRetention.oneWeek: RetentionPeriod.week,
    MemoryRetention.oneMonth: RetentionPeriod.month,
    MemoryRetention.threeMonths: RetentionPeriod.threeMonths,
    MemoryRetention.forever: RetentionPeriod.never,
  };
  RetentionService().updatePeriod(map[retention] ?? RetentionPeriod.month);
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

    Widget home;
    if (!authService.isCloudEnabled) {
      home = const WorkspaceScreen();
    } else {
      home = StreamBuilder<User?>(
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
      );
    }

    return ShortcutsWrapper(
      onCommandPalette: () => debugPrint('Cmd+K: comando global'),
      onToggleSidebar: () => debugPrint('Cmd+B: toggle barra lateral'),
      onNewNote: () => debugPrint('Cmd+N: nueva nota'),
      child: MaterialApp(
        title: 'Norm',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: themeProvider.themeData,
        home: home,
      ),
    );
  }
}
