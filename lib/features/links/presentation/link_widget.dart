import 'package:flutter/material.dart';

import '../domain/link_block.dart';
import '../../notes/domain/note_model.dart';
import '../../sheets/domain/sheet_block.dart';
import '../../charts/domain/chart_block.dart';
import '../../tasks/domain/task_block.dart';
import '../../../core/widgets/concentric_card.dart';

class LinkWidget extends StatefulWidget {
  final LinkBlock block;
  final ValueChanged<LinkBlock> onChanged;
  final List<NoteModel> allNotes;
  final NoteModel? currentNote;
  final void Function(NoteModel note)? onNavigateToNote;

  const LinkWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.allNotes,
    this.currentNote,
    this.onNavigateToNote,
  });

  @override
  State<LinkWidget> createState() => _LinkWidgetState();
}

class _LinkWidgetState extends State<LinkWidget> {
  late LinkBlock _block;
  late List<NoteWithLink> _backlinks;
  late List<NoteWithLink> _mentions;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _block = widget.block;
    _computeBacklinks();
  }

  @override
  void didUpdateWidget(LinkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block || oldWidget.allNotes != widget.allNotes) {
      _block = widget.block;
      _computeBacklinks();
    }
  }

  void _computeBacklinks() {
    if (widget.currentNote != null) {
      _backlinks = LinkBlock.findBacklinks(widget.currentNote!, widget.allNotes);
      _mentions = LinkBlock.findMentions(widget.currentNote!, widget.allNotes);
    } else {
      _backlinks = [];
      _mentions = [];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged(_block);
  }

  IconData _iconForNote(NoteModel note) {
    if (SheetBlock.isSheet(note.contentJson)) return Icons.table_chart_outlined;
    if (ChartBlock.isChart(note.contentJson)) return Icons.bar_chart_outlined;
    if (TaskBlock.isTask(note.contentJson)) return Icons.checklist_rtl;
    if (LinkBlock.isLink(note.contentJson)) return Icons.link_outlined;
    if (note.contentJson.trim().startsWith('[')) return Icons.draw_outlined;
    return Icons.description_outlined;
  }

  Color _colorForNote(NoteModel note) {
    if (SheetBlock.isSheet(note.contentJson)) return const Color(0xFF38BDF8);
    if (ChartBlock.isChart(note.contentJson)) return const Color(0xFFA78BFA);
    if (TaskBlock.isTask(note.contentJson)) return const Color(0xFFFBBF24);
    if (LinkBlock.isLink(note.contentJson)) return const Color(0xFFF472B6);
    if (note.contentJson.trim().startsWith('[')) return const Color(0xff9d4edd);
    return const Color(0xFF34D399);
  }

  void _showAddLinkDialog() {
    final available = widget.allNotes
        .where((n) =>
            n.id != widget.currentNote?.id && !_block.hasLinkTo(n.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = _searchController.text.toLowerCase();
          final filtered = query.isEmpty
              ? available
              : available
                  .where((n) => n.title.toLowerCase().contains(query))
                  .toList();

          return AlertDialog(
            title: const Text('Añadir Enlace'),
            content: SizedBox(
              width: 360,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar nota para enlazar...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              query.isEmpty
                                  ? 'No hay notas disponibles'
                                  : 'Sin resultados',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.4),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final note = filtered[i];
                              final color = _colorForNote(note);
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_iconForNote(note),
                                      size: 16, color: color),
                                ),
                                title: Text(note.title,
                                    style: const TextStyle(fontSize: 13)),
                                subtitle: Text(_noteTypeLabel(note),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.5))),
                                onTap: () {
                                  _block.addLink(note.id, label: note.title);
                                  _notifyChanged();
                                  Navigator.of(ctx).pop();
                                  setState(() {});
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _noteTypeLabel(NoteModel note) {
    if (SheetBlock.isSheet(note.contentJson)) return 'Hoja de Datos';
    if (ChartBlock.isChart(note.contentJson)) return 'Gráfico';
    if (TaskBlock.isTask(note.contentJson)) return 'Tareas';
    if (LinkBlock.isLink(note.contentJson)) return 'Conexiones';
    if (note.contentJson.trim().startsWith('[')) return 'Pizarrón';
    return 'Nota';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConcentricCard(
      level: ConcentricLevel.outer,
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildOutgoingSection(context),
          _buildBacklinksSection(context),
          if (_mentions.isNotEmpty) _buildMentionsSection(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(Icons.link_outlined, size: 16, color: const Color(0xFFF472B6)),
          const SizedBox(width: 8),
          Text(
            'Conexiones',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
          ),
          const Spacer(),
          Text(
            '${_block.outgoingCount} salientes · ${_backlinks.length} entrantes',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Enlaces Salientes',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showAddLinkDialog,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: const Color(0xFFF472B6)),
                        const SizedBox(width: 2),
                        Text('Añadir',
                            style: TextStyle(
                                fontSize: 10, color: const Color(0xFFF472B6))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _block.outgoingLinks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Sin enlaces. Pulsa "Añadir" para conectar notas.',
                      style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant.withOpacity(0.35)),
                    ),
                  ),
                )
              : ConcentricCard(
                  level: ConcentricLevel.inner,
                  padding: const EdgeInsets.all(0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _block.outgoingLinks.map((link) {
                        final targetNote = widget.allNotes
                            .where((n) => n.id == link.targetNoteId)
                            .firstOrNull;
                        return _buildLinkTile(context, link, targetNote,
                            isOutgoing: true);
                      }).toList(),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBacklinksSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final combined = [..._backlinks];

    if (combined.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Retroenlaces',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          ConcentricCard(
            level: ConcentricLevel.inner,
            padding: const EdgeInsets.all(0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: combined.map((nwl) {
                  return _buildBacklinkTile(context, nwl);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Menciones Textuales',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          ConcentricCard(
            level: ConcentricLevel.inner,
            padding: const EdgeInsets.all(0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _mentions.map((nwl) {
                  return _buildBacklinkTile(context, nwl);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, LinkEntry link,
      NoteModel? targetNote,
      {bool isOutgoing = true}) {
    final scheme = Theme.of(context).colorScheme;
    final color = targetNote != null
        ? _colorForNote(targetNote)
        : scheme.onSurfaceVariant;
    final icon = targetNote != null
        ? _iconForNote(targetNote)
        : Icons.link_off;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outline.withOpacity(0.06)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: targetNote != null && widget.onNavigateToNote != null
              ? () => widget.onNavigateToNote!(targetNote)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetNote?.title ?? 'Nota eliminada',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: targetNote != null
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant.withOpacity(0.4),
                        ),
                      ),
                      if (link.description != null)
                        Text(
                          link.description!,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF472B6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOutgoing ? 'SALIDA' : 'ENTRADA',
                    style: TextStyle(
                      fontSize: 7,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF472B6),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    _block.removeLink(link.id);
                    _notifyChanged();
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close,
                        size: 12,
                        color: scheme.onSurfaceVariant.withOpacity(0.25)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBacklinkTile(BuildContext context, NoteWithLink nwl) {
    final scheme = Theme.of(context).colorScheme;
    final color = _colorForNote(nwl.note);
    final icon = _iconForNote(nwl.note);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outline.withOpacity(0.06)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onNavigateToNote != null
              ? () => widget.onNavigateToNote!(nwl.note)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nwl.note.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (nwl.description != null)
                        Text(
                          nwl.description!,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    nwl.matchType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 7,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
