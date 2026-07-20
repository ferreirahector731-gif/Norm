import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/note_model.dart';

enum SortMode { updatedAt, title }
enum FilterMode { all, pendingSync }

class NoteBentoExplorer extends StatefulWidget {
  final List<NoteModel> notes;
  final NoteModel? activeNote;
  final ValueChanged<NoteModel> onNoteSelected;
  final VoidCallback onCreateNote;
  final bool isLoading;

  const NoteBentoExplorer({
    super.key,
    required this.notes,
    this.activeNote,
    required this.onNoteSelected,
    required this.onCreateNote,
    this.isLoading = false,
  });

  @override
  State<NoteBentoExplorer> createState() => _NoteBentoExplorerState();
}

class _NoteBentoExplorerState extends State<NoteBentoExplorer> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  SortMode _sortMode = SortMode.updatedAt;
  FilterMode _filterMode = FilterMode.all;

  List<NoteModel> get _filteredNotes {
    var result = widget.notes.toList();

    // Filtro por estado de sync
    if (_filterMode == FilterMode.pendingSync) {
      result = result.where((n) => n.isDirty).toList();
    }

    // Búsqueda en título y contenido
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.contentJson.toLowerCase().contains(query);
      }).toList();
    }

    // Orden
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
    final notes = _filteredNotes;

    return Column(
      children: [
        _buildHeader(context),
        _buildSearchBar(context),
        if (notes.isEmpty && _searchQuery.isEmpty && _filterMode == FilterMode.all && !widget.isLoading)
          const SizedBox(height: 24),
        _buildFilterChips(context),
        Expanded(
          child: widget.isLoading
              ? const ShimmerBentoGrid()
              : notes.isEmpty
                  ? _buildEmptyState(context)
                  : _buildBentoGrid(context, notes),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            onPressed: widget.onCreateNote,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: scheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar notas...',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: scheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18,
                            color: scheme.onSurfaceVariant),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _chip(
            context,
            label: 'Recientes',
            icon: Icons.schedule,
            active: _sortMode == SortMode.updatedAt,
            onTap: () => setState(() => _sortMode = SortMode.updatedAt),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'A-Z',
            icon: Icons.sort_by_alpha,
            active: _sortMode == SortMode.title,
            onTap: () => setState(() => _sortMode = SortMode.title),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Pendientes',
            icon: Icons.cloud_upload_outlined,
            active: _filterMode == FilterMode.pendingSync,
            onTap: () => setState(() {
              _filterMode = _filterMode == FilterMode.pendingSync
                  ? FilterMode.all
                  : FilterMode.pendingSync;
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? scheme.primary.withOpacity(0.15)
              : scheme.surfaceContainerHigh.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? scheme.primary.withOpacity(0.4)
                : scheme.outlineVariant.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasFilters = _searchQuery.isNotEmpty || _filterMode == FilterMode.pendingSync;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withOpacity(0.12),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasFilters
                          ? Icons.search_off_rounded
                          : Icons.edit_note_rounded,
                      size: 36,
                      color: scheme.primary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    hasFilters ? 'Sin resultados' : 'El lienzo está listo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasFilters
                        ? 'Intenta con otros términos o quita los filtros'
                        : 'Crea una nota para comenzar.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: scheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, List<NoteModel> notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final unitW = (constraints.maxWidth - gap) / 2;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(notes.length, (i) {
                final note = notes[i];
                // Patrón bento: filas alternan [ancho, angosto] / [angosto, ancho]
                final isWide = i % 4 == 0 || i % 4 == 3;
                final w = isWide ? unitW * 2 + gap : unitW;
                return AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _BentoCard(
                    note: note,
                    width: w,
                    isActive: note.id == widget.activeNote?.id,
                    onTap: () => widget.onNoteSelected(note),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final NoteModel note;
  final double width;
  final bool isActive;
  final VoidCallback onTap;

  const _BentoCard({
    required this.note,
    required this.width,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWhiteboard = note.contentJson == '[]';
    final isDirty = note.isDirty;

    return SizedBox(
      width: width,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Material(
          color: isActive
              ? scheme.primaryContainer.withOpacity(0.2)
              : scheme.surfaceContainerLow.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? scheme.primary.withOpacity(0.3)
                      : scheme.outlineVariant.withOpacity(0.12),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isWhiteboard ? Icons.draw_outlined : Icons.description_outlined,
                        size: 18,
                        color: isActive
                            ? scheme.primary
                            : scheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const Spacer(),
                      if (isDirty)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.tertiary,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.tertiary.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: isActive ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
