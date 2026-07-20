import 'package:flutter/material.dart';

class AiAssistantPanel extends StatefulWidget {
  const AiAssistantPanel({super.key});

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  bool _isCloudMode = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          _buildHeader(context),
          Expanded(child: _buildContent(context)),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            'Asistente IA',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildToggle(context),
        ],
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isCloudMode = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isCloudMode ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud, size: 14, color: _isCloudMode ? scheme.onPrimary : scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Cloud',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: _isCloudMode ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isCloudMode = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !_isCloudMode ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sd_storage, size: 14, color: !_isCloudMode ? scheme.onPrimary : scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Local',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: !_isCloudMode ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola. ¿En qué puedo ayudarte con tus notas hoy?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ACCIONES RÁPIDAS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.outline,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: Icons.summarize,
            title: 'Resumir mis notas',
            subtitle: 'Extrae los puntos clave de tus documentos recientes',
            color: scheme.secondary,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            context,
            icon: Icons.calendar_month,
            title: 'Planificar mi día',
            subtitle: 'Organiza tareas basadas en tus notas de Estrategia',
            color: scheme.tertiary,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            context,
            icon: Icons.travel_explore,
            title: 'Investigar tema',
            subtitle: 'Busca información adicional sobre tus ideas',
            color: scheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 18,
                color: scheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.auto_awesome, size: 18, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Pregúntale a la IA...',
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: scheme.primary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

void showAiAssistant(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (_) => const AiAssistantPanel(),
  );
}
