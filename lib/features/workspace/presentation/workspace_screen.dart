import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/sync_manager.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/cloud_sync_status_widget.dart';
import '../../ai/presentation/ai_assistant_panel.dart';
import '../../home/widgets/theme_selector.dart';
import '../../notes/domain/note_model.dart';
import '../../notes/presentation/widgets/editor_workspace.dart';
import '../../notes/presentation/widgets/note_bento_explorer.dart';
import '../../notes/presentation/widgets/whiteboard_canvas.dart';
import '../../settings/presentation/settings_screen.dart';

class WorkspaceScreen extends StatefulWidget {
  final NoteModel? initialNote;

  const WorkspaceScreen({super.key, this.initialNote});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  List<NoteModel> _notes = [];
  NoteModel? _activeNote;
  bool _isLoading = true;

  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await DatabaseService.getAllNotes();
    if (!mounted) return;

    NoteModel? targetNote;

    if (widget.initialNote != null) {
      targetNote = notes.cast<NoteModel?>().firstWhere(
        (n) => n!.id == widget.initialNote!.id,
        orElse: () => null,
      );
    }

    if (targetNote == null && notes.isNotEmpty) {
      targetNote = notes.first;
    }

    if (targetNote == null) {
      final welcomeNote = NoteModel.create(
        title: 'Bienvenido a Norm',
        contentJson: '[]',
      );
      await DatabaseService.saveNote(welcomeNote);
      SyncManager.scheduleSync();
      notes.add(welcomeNote);
      targetNote = welcomeNote;
    }

    setState(() {
      _notes = notes;
      _isLoading = false;
    });

    if (targetNote != null) {
      if (_isWhiteboard(targetNote)) {
        setState(() {
          _activeNote = targetNote;
          _isLoading = false;
        });
      } else {
        await _selectNote(targetNote, persistCurrent: false);
      }
    }
  }

  Future<void> _selectNote(NoteModel note, {required bool persistCurrent}) async {
    if (_isWhiteboard(note)) {
      if (persistCurrent) await _saveActiveNote();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WhiteboardCanvas(note: note)),
      );
      await _loadNotes();
      return;
    }

    if (persistCurrent) await _saveActiveNote();

    setState(() => _activeNote = note);
  }

  bool _isWhiteboard(NoteModel note) {
    final raw = note.contentJson.trim();
    return raw.isNotEmpty && raw.startsWith('[');
  }

  void _showNewNoteChooser() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nueva nota',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.article_outlined, color: Theme.of(ctx).colorScheme.primary),
                ),
                title: const Text('Documento de Texto'),
                subtitle: const Text('Editor enriquecido con AppFlowy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _createTextNote();
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xff9d4edd).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.draw_outlined, color: Color(0xff9d4edd)),
                ),
                title: const Text('Pizarrón Blanco'),
                subtitle: const Text('Dibujo vectorial con lápiz y colores'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _createWhiteboard();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createTextNote() async {
    await _saveActiveNote();

    final note = NoteModel.create(
      title: 'Nota sin título',
      contentJson: '[]',
    );
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();

    final notes = await DatabaseService.getAllNotes();
    if (!mounted) return;

    setState(() => _notes = notes);
    await _selectNote(note, persistCurrent: false);
  }

  Future<void> _createWhiteboard() async {
    await _saveActiveNote();

    final note = NoteModel.create(
      title: 'Pizarrón sin título',
      contentJson: '[]',
    );
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();

    final notes = await DatabaseService.getAllNotes();
    if (!mounted) return;

    setState(() => _notes = notes);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhiteboardCanvas(note: note),
      ),
    );
    await _loadNotes();
  }

  Future<void> _deleteActiveNote() async {
    final active = _activeNote;
    if (active == null || _notes.length <= 1) return;

    await DatabaseService.deleteNote(active.id);
    final notes = await DatabaseService.getAllNotes();
    if (!mounted || notes.isEmpty) return;

    setState(() => _notes = notes);
    await _selectNote(notes.first, persistCurrent: false);
  }

  void _onNoteUpdated(NoteModel updatedNote) {
    setState(() {
      _activeNote = updatedNote;
      final idx = _notes.indexWhere((n) => n.id == updatedNote.id);
      if (idx >= 0) _notes[idx] = updatedNote;
    });
    _debouncedSave();
  }

  void _debouncedSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () async {
      final note = _activeNote;
      if (note == null) return;
      await DatabaseService.saveNote(note);
      SyncManager.scheduleSync();
      final notes = await DatabaseService.getAllNotes();
      if (!mounted) return;
      setState(() => _notes = notes);
    });
  }

  Future<void> _saveActiveNote() async {
    final active = _activeNote;
    if (active == null) return;
    await DatabaseService.saveNote(active);
    SyncManager.scheduleSync();
    final notes = await DatabaseService.getAllNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _activeNote = notes.firstWhere(
        (note) => note.id == active.id,
        orElse: () => active,
      );
    });
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

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildMobileAppBar(context),
      ),
      drawer: _buildMobileDrawer(context),
      body: EditorWorkspace(
        key: ValueKey(_activeNote?.id),
        note: _activeNote,
        isLoading: _isLoading,
        onNoteUpdated: _onNoteUpdated,
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        onPressed: () => showAiAssistant(context, noteId: _activeNote?.id),
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }

  Widget _buildMobileAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
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
                  _activeNote?.title ?? 'Nota',
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
                onPressed: _notes.length > 1 ? _deleteActiveNote : null,
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: scheme.outline),
                tooltip: 'Ajustes',
                onPressed: () => showSettings(context),
              ),
              IconButton(
                icon: Icon(Icons.auto_awesome, color: scheme.primary),
                tooltip: 'Asistente IA',
                onPressed: () => showAiAssistant(context, noteId: _activeNote?.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
              _showNewNoteChooser();
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

  Widget _buildDrawerNoteList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              final isSelected = note.id == _activeNote?.id;
              return Material(
                color: isSelected
                    ? scheme.primaryContainer.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    _isWhiteboard(note) ? Icons.draw_outlined : Icons.description_outlined,
                    size: 18,
                    color: isSelected ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.6),
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
              color: Colors.white.withValues(alpha: 0.04),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ThemeSelector(),
                ),
              ],
            ),
          ),
        ),
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
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.white.withValues(alpha: 0.02),
            child: NoteBentoExplorer(
              notes: _notes,
              activeNote: _activeNote,
              isLoading: _isLoading,
              onNoteSelected: (note) => _selectNote(note, persistCurrent: true),
              onCreateNote: _showNewNoteChooser,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorArea(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildEditorAppBar(context),
          Expanded(
            child: EditorWorkspace(
              key: ValueKey(_activeNote?.id),
              note: _activeNote,
              isLoading: _isLoading,
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

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              _activeNote?.title ?? 'Nota',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const CloudSyncStatusWidget(),
          const SizedBox(width: 8),
          Icon(
            Icons.save_outlined,
            color: scheme.outline,
            size: 20,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: scheme.outline),
            tooltip: 'Ajustes',
            onPressed: () => showSettings(context),
          ),
          IconButton(
            tooltip: 'Eliminar nota',
            icon: Icon(Icons.delete_outline, color: scheme.outline),
            onPressed: _notes.length > 1 ? _deleteActiveNote : null,
          ),
          IconButton(
            icon: Icon(Icons.auto_awesome, color: scheme.primary),
            tooltip: 'Asistente IA',
            onPressed: () => showAiAssistant(context, noteId: _activeNote?.id),
          ),
        ],
      ),
    );
  }

} // _WorkspaceScreenState
