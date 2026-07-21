import 'package:flutter/material.dart';

class NotionImportScreen extends StatelessWidget {
  const NotionImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Importar desde Notion')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.integration_instructions, size: 64, color: scheme.primary),
              const SizedBox(height: 24),
              Text(
                'Importar desde Notion',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Conecta tu cuenta de Notion para importar tus notas.\n'
                'Necesitarás crear una integración en Notion y\n'
                'compartir las páginas que quieras migrar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Integración con Notion próximamente')),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Conectar con Notion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
