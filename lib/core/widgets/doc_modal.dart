import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';

class DocModal extends StatelessWidget {
  const DocModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const DocModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normTheme = context.read<ThemeProvider>().theme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(normTheme.cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: normTheme.liquidBlur, sigmaY: normTheme.liquidBlur),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 600),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer.withOpacity(0.95),
              borderRadius: BorderRadius.circular(normTheme.cardRadius),
              border: Border.all(color: scheme.outline.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 32, spreadRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, 'Atajos de Teclado y Gestos Espaciales'),
                        const SizedBox(height: 12),
                        _buildShortcutGrid(context),
                        const SizedBox(height: 20),
                        _buildArchitecture(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFBBF24),
            boxShadow: [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.6), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Documentación & Manual de Comandos Rápido (v1.8.0)',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: const Color(0xFFFBBF24),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.close, size: 16, color: scheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        const Icon(Icons.keyboard, size: 14, color: Color(0xFFFBBF24)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFBBF24),
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutGrid(BuildContext context) {
    final normTheme = context.read<ThemeProvider>().theme;

    final shortcuts = [
      ('Captura NLP Rápida', 'Ctrl + K', 'Ingresa tareas con lenguaje natural.', const Color(0xFF34D399)),
      ('Crear Nodo Libre', 'Doble Clic', 'Haz doble clic en el Lienzo Espacial.', const Color(0xFF38BDF8)),
      ('Elevación Eje Z', 'Arrastrar', 'Arrastrar tarjetas incrementa sombra en Z.', const Color(0xFFA78BFA)),
      ('Pan / Zoom', 'Rueda / Drag', 'Rueda para zoom reactivo a 60 FPS.', const Color(0xFFFBBF24)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: shortcuts.length,
      itemBuilder: (_, i) => _buildShortcutCard(context, shortcuts[i].$1, shortcuts[i].$2, shortcuts[i].$3, shortcuts[i].$4, normTheme),
    );
  }

  Widget _buildShortcutCard(BuildContext context, String title, String key, String desc, Color color, NormTheme normTheme) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(normTheme.innerRadius),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scheme.onSurface, fontFamily: 'monospace')),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: scheme.outline.withOpacity(0.3)),
                ),
                child: Text(key, style: TextStyle(fontSize: 9, color: color, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          Text(desc, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildArchitecture(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normTheme = context.read<ThemeProvider>().theme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(normTheme.innerRadius),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, size: 14, color: Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              Text('Motor de Persistencia y Agente Autónomo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scheme.onSurface, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'NORM v1.8.0 combina un motor de base de datos Local-First (Isar) optimizado para responder en <1.2ms con el modelo local Gemma (Ollama). Todas las notas, tareas y canvas se guardan de forma segura en el dispositivo con opción de replicación remota a Supabase.',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFBBF24),
          foregroundColor: const Color(0xFF090A0C),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        child: const Text('Entendido'),
      ),
    );
  }
}
