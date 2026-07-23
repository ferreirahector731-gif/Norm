import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/sync_manager.dart';
import '../../../core/services/update_service.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/cloud_sync_status_widget.dart';
import '../../../core/widgets/update_dialog.dart';
import '../../../core/widgets/user_avatar_menu.dart';
import '../../ai/presentation/ai_assistant_panel.dart';
import '../../home/widgets/theme_selector.dart';
import '../../notes/domain/note_model.dart';
import '../../notes/presentation/widgets/editor_workspace.dart';
import '../../notes/presentation/widgets/note_bento_explorer.dart';
import '../../notes/presentation/widgets/whiteboard_canvas.dart';
import '../../notes/presentation/notifiers/notes_notifier.dart';
import '../../sheets/domain/sheet_block.dart';
import '../../charts/domain/chart_block.dart';
import '../../tasks/domain/task_block.dart';
import '../../links/domain/link_block.dart';
import '../../settings/presentation/settings_dialog.dart';
import '../../settings/presentation/settings_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  final NoteModel? initialNote;

  const WorkspaceScreen({super.key, this.initialNote});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _initNotifier();
    _checkUpdate();
  }

  Future<void> _initNotifier() async {
    final notifier = context.read<NotesNotifier>();
    await notifier.loadNotes(initialNote: widget.initialNote);
  }

  Future<void> _checkUpdate() async {
    final currentVer = await UpdateService.getCurrentVersion();
    if (currentVer == null || !mounted) return;

    final remote = await UpdateService.checkForUpdate();
    if (remote == null || !mounted) return;

    final hasUpdate = await UpdateService.hasUpdate(currentVer, remote.version);
    if (!hasUpdate) return;

    final skipped = await UpdateService.getSkippedVersion();
    if (skipped == remote.version) return;

    final url = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: remote),
    );

    if (url != null && mounted) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _selectNote(NoteModel note, {required bool persistCurrent}) async {
    final notifier = context.read<NotesNotifier>();
    if (_isWhiteboard(note)) {
      if (persistCurrent && notifier.activeNote != null) {
        await notifier.updateNote(notifier.activeNote!);
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WhiteboardCanvas(note: note)),
      );
      await notifier.loadNotes();
      return;
    }

    if (persistCurrent && notifier.activeNote != null) {
      await notifier.updateNote(notifier.activeNote!);
    }

    notifier.selectNote(note);
  }

  bool _isWhiteboard(NoteModel note) {
    final raw = note.contentJson.trim();
    return raw.isNotEmpty && raw.startsWith('[');
  }

  bool _isSheet(NoteModel note) {
    return SheetBlock.isSheet(note.contentJson);
  }

  bool _isChart(NoteModel note) {
    return ChartBlock.isChart(note.contentJson);
  }

  bool _isTask(NoteModel note) {
    return TaskBlock.isTask(note.contentJson);
  }

  bool _isLink(NoteModel note) {
    return LinkBlock.isLink(note.contentJson);
  }

  void _onNoteUpdated(NoteModel updatedNote) {
    context.read<NotesNotifier>().updateNote(updatedNote);
    _debouncedSave();
  }

  void _debouncedSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () async {
      final notifier = context.read<NotesNotifier>();
      final note = notifier.activeNote;
      if (note == null) return;
      await notifier.updateNote(note);
    });
  }

  Future<void> _deleteActiveNote() async {
    final notifier = context.read<NotesNotifier>();
    final active = notifier.activeNote;
    if (active == null || notifier.notes.length <= 1) return;

    await notifier.deleteNote(active.id);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(context),
      desktopBody: _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavSidebar(context),
          _buildNoteListPanel(context),
          Expanded(child: _buildEditorArea(context)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = context.watch<NotesNotifier>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildMobileAppBar(context),
      ),
      drawer: _buildMobileDrawer(context),
      body: EditorWorkspace(
        key: ValueKey(notifier.activeNote?.id),
        note: notifier.activeNote,
        isLoading: notifier.isLoading,
        onNoteUpdated: _onNoteUpdated,
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        onPressed: () => showAiAssistant(context, noteId: notifier.activeNote?.id),
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }

  Widget _buildMobileAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = context.watch<NotesNotifier>();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(Icons.menu, color: scheme.primary),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              Expanded(
                child: Text(
                  notifier.activeNote?.title ?? 'Nota',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const CloudSyncStatusWidget(),
              const SizedBox(width: 8),
              Icon(
                Icons.save_outlined,
                color: scheme.outline,
                size: 20,
              ),
              IconButton(
                tooltip: 'Eliminar nota',
                icon: Icon(Icons.delete_outline, color: scheme.outline),
                onPressed: notifier.notes.length > 1 ? _deleteActiveNote : null,
              ),
              IconButton(
                icon: Icon(Icons.auto_awesome, color: scheme.primary),
                tooltip: 'Asistente IA',
                onPressed: () => showAiAssistant(context, noteId: notifier.activeNote?.id),
              ),
              const SizedBox(width: 4),
              const UserAvatarMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notifier = context.watch<NotesNotifier>();

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            const Divider(height: 1),
            Expanded(
              child: _buildDrawerNoteList(context),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: ThemeSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notifier = context.read<NotesNotifier>();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_outline, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creative Thinker',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Personal Workspace',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showNewNoteChooser(context);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva nota'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewNoteChooser(BuildContext context) {
    final notifier = context.read<NotesNotifier>();
    final scheme = Theme.of(context).colorScheme;

    final modules = [
      _ModuleOption(Icons.article_outlined, const Color(0xFF34D399), 'NOTE',
          'Nota rápida', 'Texto enriquecido con AppFlowy', () {
        Navigator.of(context).pop();
        notifier.createTextNote();
      }),
      _ModuleOption(Icons.checklist_rtl, const Color(0xFFFBBF24), 'TASK',
          'Tareas NLP', 'Gestión de tareas con lenguaje natural', () {
        Navigator.of(context).pop();
        notifier.createTask();
      }),
      _ModuleOption(Icons.description_outlined, const Color(0xFF818CF8), 'DOC',
          'Documento', 'Editor de documentos largos', () {
        Navigator.of(context).pop();
        notifier.createTextNote();
      }),
      _ModuleOption(Icons.table_chart_outlined, const Color(0xFF38BDF8), 'SHEET',
          'Hoja de Datos', 'Datos estructurados con tabla', () {
        Navigator.of(context).pop();
        notifier.createSheet();
      }),
      _ModuleOption(Icons.bar_chart_outlined, const Color(0xFFA78BFA), 'CHART',
          'Telemetría', 'Gráficos y rendimiento a 60 FPS', () {
        Navigator.of(context).pop();
        notifier.createChart();
      }),
      _ModuleOption(Icons.draw_outlined, const Color(0xFFFB7185), 'CANVAS',
          'Pizarrón Infinito', 'Lienzo espacial con zoom y nodos', () {
        Navigator.of(context).pop();
        notifier.createWhiteboard();
      }),
      _ModuleOption(Icons.link_outlined, const Color(0xFFF472B6), 'LINK',
          'Enlace / Backlink', 'Conexiones semánticas', () {
        Navigator.of(context).pop();
        notifier.createLink();
      }),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outline.withOpacity(0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: scheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Crear Nuevo Elemento',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    ...modules.map((m) => _buildModuleOption(ctx, m)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  SnackBar _comingSoonSnackbar() {
    return SnackBar(
      content: const Text('Próximamente en v1.8.x'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildModuleOption(BuildContext context, _ModuleOption m) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: m.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m.icon, color: m.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(m.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: m.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(m.code, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: m.color, fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(m.subtitle, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerNoteList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = context.watch<NotesNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'NOTAS LOCALES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: scheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: notifier.notes.length,
            itemBuilder: (context, index) {
              final note = notifier.notes[index];
              final isSelected = note.id == notifier.activeNote?.id;
              return Material(
                color: isSelected
                    ? scheme.primaryContainer.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    _isLink(note) ? Icons.link_outlined :
                    _isTask(note) ? Icons.checklist_rtl :
                    _isChart(note) ? Icons.bar_chart_outlined :
                    _isSheet(note) ? Icons.table_chart_outlined :
                    _isWhiteboard(note) ? Icons.draw_outlined :
                    Icons.description_outlined,
                    size: 18,
                    color: isSelected ? scheme.primary : scheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  title: Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selectNote(note, persistCurrent: true);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 200,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person_outline, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Creative Thinker',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            Text(
                              'Personal',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: scheme.onSurfaceVariant, size: 18),
                        tooltip: 'Ajustes',
                        onPressed: () => SettingsDialog.show(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _navItem(context, Icons.description, 'All Pages', true, () {}),
                      _navItem(context, Icons.star, 'Favorites', false, () {}),
                      _navItem(context, Icons.history, 'Recents', false, () {}),
                      _navItem(context, Icons.edit_note, 'Editor', false, () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildTemplateButton(context),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showComingSoon(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.widgets_outlined, size: 16, color: const Color(0xFF34D399)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plantillas y Bóveda', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scheme.onSurface, fontFamily: 'monospace')),
                      Text('Cargar o Exportar Grids', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 14, color: scheme.onSurfaceVariant.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Próximamente en v1.8.x'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isActive ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteListPanel(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 320,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.white.withOpacity(0.02),
            child: const NoteBentoExplorer(),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorArea(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = context.watch<NotesNotifier>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildEditorAppBar(context),
          Expanded(
            child: EditorWorkspace(
              key: ValueKey(notifier.activeNote?.id),
              note: notifier.activeNote,
              isLoading: notifier.isLoading,
              onNoteUpdated: _onNoteUpdated,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notifier = context.watch<NotesNotifier>();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outline.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 14, color: scheme.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(fontSize: 12, color: scheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Buscar notas, tareas...',
                        hintStyle: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant.withOpacity(0.4)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: scheme.outline.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Ctrl+K',
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CloudSyncStatusWidget(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Eliminar nota',
            icon: Icon(Icons.delete_outline, color: scheme.outline),
            onPressed: notifier.notes.length > 1 ? _deleteActiveNote : null,
          ),
          IconButton(
            icon: Icon(Icons.auto_awesome, color: scheme.primary),
            tooltip: 'Asistente IA',
            onPressed: () => showAiAssistant(context, noteId: notifier.activeNote?.id),
          ),
          const SizedBox(width: 4),
          const UserAvatarMenu(),
        ],
      ),
    );
  }
}

class _ModuleOption {
  final IconData icon;
  final Color color;
  final String code;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ModuleOption(this.icon, this.color, this.code, this.title, this.subtitle, this.onTap);
}
