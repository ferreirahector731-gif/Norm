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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant, size: 20),
            tooltip: 'Más opciones',
            onSelected: (value) => _handleMenuAction(context, notifier, value),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'export', child: _MenuRow(Icons.file_upload_outlined, 'Exportar nota como MD')),
              const PopupMenuItem(value: 'import', child: _MenuRow(Icons.file_download_outlined, 'Importar archivos .md')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(
      BuildContext context, NotesNotifier notifier, String action) async {
    switch (action) {
      case 'export':
        final result = await notifier.exportCurrentNoteAsMarkdown();
        if (!mounted) return;
        if (result == null) {
          // usuario canceló
        } else if (result.startsWith('Error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nota exportada a:\n$result'),
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      case 'import':
        final count = await notifier.importMarkdownFiles();
        if (!mounted) return;
        if (count == null) {
          // usuario canceló
        } else if (count == -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al importar archivos. Revisa que sean .md válidos.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count nota(s) importada(s) correctamente.'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        }
    }
  }

  void _showNewNoteChooser(BuildContext context, NotesNotifier notifier) {
    final scheme = Theme.of(context).colorScheme;

    final modules = [
      _BentoModuleOption(Icons.article_outlined, const Color(0xFF34D399), 'NOTE',
          'Nota rápida', 'Texto enriquecido', () {
        Navigator.of(context).pop();
        notifier.createTextNote();
      }),
      _BentoModuleOption(Icons.checklist_rtl, const Color(0xFFFBBF24), 'TASK',
          'Tareas NLP', 'Gestión de tareas', () {
        Navigator.of(context).pop();
        _showComingSoon(context);
      }),
      _BentoModuleOption(Icons.description_outlined, const Color(0xFF818CF8), 'DOC',
          'Documento', 'Documentos largos', () {
        Navigator.of(context).pop();
        notifier.createTextNote();
      }),
      _BentoModuleOption(Icons.table_chart_outlined, const Color(0xFF38BDF8), 'SHEET',
          'Hoja de Datos', 'Datos estructurados', () {
        Navigator.of(context).pop();
        _showComingSoon(context);
      }),
      _BentoModuleOption(Icons.bar_chart_outlined, const Color(0xFFA78BFA), 'CHART',
          'Telemetría', 'Gráficos 60 FPS', () {
        Navigator.of(context).pop();
        _showComingSoon(context);
      }),
      _BentoModuleOption(Icons.draw_outlined, const Color(0xFFFB7185), 'CANVAS',
          'Pizarrón Infinito', 'Lienzo espacial', () {
        Navigator.of(context).pop();
        notifier.createWhiteboard();
      }),
      _BentoModuleOption(Icons.link_outlined, const Color(0xFFF472B6), 'LINK',
          'Enlace / Backlink', 'Conexiones semánticas', () {
        Navigator.of(context).pop();
        _showComingSoon(context);
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

  Widget _buildModuleOption(BuildContext context, _BentoModuleOption m) {
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

class _BentoModuleOption {
  final IconData icon;
  final Color color;
  final String code;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _BentoModuleOption(this.icon, this.color, this.code, this.title, this.subtitle, this.onTap);
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
