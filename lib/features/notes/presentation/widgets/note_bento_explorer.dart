import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/note_model.dart';
import '../notifiers/notes_notifier.dart';

enum SortMode { updatedAt, title }
enum FilterMode { all, pendingSync }

class NoteBentoExplorer extends StatefulWidget {
  const NoteBentoExplorer({super.key});

  @override
  State<NoteBentoExplorer> createState() => _NoteBentoExplorerState();
}

class _NoteBentoExplorerState extends State<NoteBentoExplorer> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  SortMode _sortMode = SortMode.updatedAt;
  FilterMode _filterMode = FilterMode.all;

  List<NoteModel> _filteredNotes(List<NoteModel> notes) {
    var result = notes.toList();

    if (_filterMode == FilterMode.pendingSync) {
      result = result.where((n) => n.isDirty).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((n) {
        return n.title.toLowerCase().contains(query);
      }).toList();
    }

    switch (_sortMode) {
      case SortMode.updatedAt:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortMode.title:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _searchQuery = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NotesNotifier>();
    final notes = _filteredNotes(notifier.notes);

    return Column(
      children: [
        _buildHeader(context, notifier),
        _buildSearchBar(context),
        if (notes.isEmpty && _searchQuery.isEmpty && _filterMode == FilterMode.all && !notifier.isLoading)
          const SizedBox(height: 24),
        _buildFilterChips(context),
        Expanded(
          child: notifier.isLoading
              ? const ShimmerBentoGrid()
              : notes.isEmpty
                  ? _buildEmptyState(context)
                  : _buildBentoGrid(context, notes, notifier),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, NotesNotifier notifier) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.grid_view_rounded, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Explorar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_rounded, color: scheme.primary, size: 22),
            tooltip: 'Nueva nota',
            onPressed: () => _showNewNoteChooser(context, notifier),
          ),
        ],
      ),
    );
  }

  void _showNewNoteChooser(BuildContext context, NotesNotifier notifier) {
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
                  notifier.createTextNote();
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
                  notifier.createWhiteboard();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.2)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(color: scheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar notas...',
            hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.4), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: scheme.outline, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: scheme.outline, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _chip(context, 'Recientes', _sortMode == SortMode.updatedAt, () {
            setState(() => _sortMode = SortMode.updatedAt);
          }),
          const SizedBox(width: 8),
          _chip(context, 'A-Z', _sortMode == SortMode.title, () {
            setState(() => _sortMode = SortMode.title);
          }),
          const SizedBox(width: 8),
          _chip(context, 'Pendientes', _filterMode == FilterMode.pendingSync, () {
            setState(() {
              _filterMode = _filterMode == FilterMode.pendingSync
                  ? FilterMode.all
                  : FilterMode.pendingSync;
            });
          }),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary.withOpacity(0.4) : scheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: scheme.outline.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _filterMode == FilterMode.pendingSync
                            ? 'Sin resultados'
                            : 'El lienzo está listo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty || _filterMode == FilterMode.pendingSync
                            ? 'Intenta con otros términos o filtros.'
                            : 'Presiona + para crear tu primera nota.',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, List<NoteModel> notes, NotesNotifier notifier) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(notes.length, (i) {
              final note = notes[i];
              final isWide = i % 4 == 0 || i % 4 == 3;
              final isActive = note.id == notifier.activeNote?.id;

              return _BentoCard(
                width: isWide ? cardWidth * 2 + 12 : cardWidth,
                note: note,
                isActive: isActive,
                onTap: () => notifier.selectNote(note),
              );
            }),
          ),
        );
      },
    );
  }
}

class _BentoCard extends StatelessWidget {
  final double width;
  final NoteModel note;
  final bool isActive;
  final VoidCallback onTap;

  const _BentoCard({
    required this.width,
    required this.note,
    required this.isActive,
    required this.onTap,
  });

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${diff.inDays ~/ 7}sem';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWhiteboard = note.contentJson.trim().isNotEmpty && note.contentJson.trim().startsWith('[');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? scheme.primary.withOpacity(0.12) : scheme.surfaceContainerLow.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? scheme.primary.withOpacity(0.5)
                : scheme.outlineVariant.withOpacity(0.1),
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isWhiteboard ? const Color(0xff9d4edd) : scheme.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isWhiteboard ? Icons.draw_outlined : Icons.description_outlined,
                    size: 14,
                    color: isWhiteboard ? const Color(0xff9d4edd) : scheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.isDirty)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _relativeDate(note.updatedAt),
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
