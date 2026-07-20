import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authService = context.read<AuthService>();

    return MaterialApp(
      title: 'nota_ia',
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
