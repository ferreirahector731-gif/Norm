import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/database/database_service.dart';
import '../../../core/widgets/glass_bento_card.dart';
import '../../auth/data/auth_service.dart';
import '../../notes/domain/note_model.dart';
import '../../notes/presentation/widgets/editor_workspace.dart';
import '../../canvas/presentation/infinite_canvas_screen.dart';
import '../../ai/presentation/ai_assistant_panel.dart';
import '../../ai/presentation/ai_bubble_widget.dart';
import '../../ai/services/ollama_ai_service.dart';
import '../../settings/presentation/settings_screen.dart';

enum _NavTab { home, notes, whiteboard, settings }

class BentoDashboardScreen extends StatefulWidget {
  const BentoDashboardScreen({super.key});

  @override
  State<BentoDashboardScreen> createState() => _BentoDashboardScreenState();
}

class _BentoDashboardScreenState extends State<BentoDashboardScreen> {
  List<NoteModel> _recentNotes = [];
  String _appVersion = '1.6.6';
  _NavTab _selectedTab = _NavTab.home;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final notes = await DatabaseService.getAllNotes();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recent = notes.take(5).toList();

    String version = '1.6.6';
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _recentNotes = recent;
      _appVersion = version;
    });
  }

  void _openNote(NoteModel note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorWorkspace(
          note: note,
          isLoading: false,
          onNoteUpdated: (_) {},
        ),
      ),
    );
  }

  Future<void> _openWhiteboard() async {
    final note = NoteModel.create(
      title: 'Lienzo ${DateTime.now().toString().substring(0, 16)}',
      contentJson: '{"blocks":[]}',
    );
    await DatabaseService.saveNote(note);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InfiniteCanvasScreen(note: note),
      ),
    );
  }

  void _openAiQuickQuery() {
    final service = OllamaAIService();
    final promptCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Stream<String>? stream;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16, right: 16, top: 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Consulta rápida IA',
                      style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (stream != null)
                      AIBubbleWidget(aiStream: stream)
                    else
                      TextField(
                        controller: promptCtrl,
                        style: const TextStyle(color: Color(0xFFF8FAFC)),
                        decoration: InputDecoration(
                          hintText: 'Escribe tu consulta...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFF131B2E).withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF3B82F6)),
                            onPressed: () {
                              final text = promptCtrl.text.trim();
                              if (text.isEmpty) return;
                              setSheetState(() {
                                stream = service.generateTextStream(prompt: text);
                              });
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onNavChanged(int index) {
    setState(() {
      _navIndex = index;
      _selectedTab = _NavTab.values[index];
    });
    switch (_selectedTab) {
      case _NavTab.whiteboard:
        _openWhiteboard();
        break;
      case _NavTab.notes:
        break;
      case _NavTab.settings:
        showSettings(context);
        break;
      default:
        break;
    }
  }

  void _openAiAssistant() => showAiAssistant(context);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 900;
      final isTablet = constraints.maxWidth > 600;

      if (isDesktop) {
        return _buildDesktopLayout();
      } else if (isTablet) {
        return _buildTabletLayout();
      }
      return _buildMobileLayout();
    });
  }

  // ─── DESKTOP (>900) ──────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(child: _buildStaggeredGrid(4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TABLET (600–900) ───────────────────────────────────────────────
  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(child: _buildStaggeredGrid(3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE (<600) ─────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildStaggeredGrid(2)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onNavChanged,
        backgroundColor: const Color(0xFF090D16),
        indicatorColor: const Color(0xFF3B82F6).withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Notas'),
          NavigationDestination(icon: Icon(Icons.draw_outlined), label: 'Pizarrón'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
        ],
      ),
    );
  }

  // ─── NAVIGATION RAIL ───────────────────────────────────────────────
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _navIndex,
      onDestinationSelected: _onNavChanged,
      backgroundColor: const Color(0xFF090D16),
      indicatorColor: const Color(0xFF3B82F6).withOpacity(0.15),
      labelType: NavigationRailLabelType.all,
      minExtendedWidth: 180,
      extended: true,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Norm',
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Inicio'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: Text('Notas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.draw_outlined),
          selectedIcon: Icon(Icons.draw),
          label: Text('Pizarrón'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Ajustes'),
        ),
      ],
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Mis espacios',
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6)),
            tooltip: 'Asistente IA',
            onPressed: _openAiAssistant,
          ),
        ],
      ),
    );
  }

  // ─── STAGGERED BENTO GRID ──────────────────────────────────────────
  Widget _buildStaggeredGrid(int cols) {
    final tiles = <StaggeredTile>[];
    final cards = <Widget>[];

    // Recent notes
    tiles.add(StaggeredTile.extent(cols > 2 ? 2 : cols, 320));
    cards.add(_buildRecentNotesCard());

    // Whiteboard shortcut
    tiles.add(StaggeredTile.extent(1, 170));
    cards.add(_buildWhiteboardCard());

    // AI Status
    tiles.add(StaggeredTile.extent(1, 170));
    cards.add(_buildAiCard());

    // Sync + Version
    tiles.add(StaggeredTile.extent(cols > 2 ? cols : cols, 130));
    cards.add(_buildStatusCard());

    return SingleChildScrollView(
      child: StaggeredGrid.extent(
        maxCrossAxisExtent: cols > 2 ? 280 : 320,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (int i = 0; i < tiles.length; i++)
            StaggeredGridTile.extent(
              crossAxisCellCount: tiles[i].crossAxisCellCount,
              mainAxisExtent: tiles[i].mainAxisExtent,
              child: cards[i],
            ),
        ],
      ),
    );
  }

  // ─── MODULES ───────────────────────────────────────────────────────

  Widget _buildRecentNotesCard() {
    return GlassBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history, color: Color(0xFF3B82F6), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notas recientes',
                style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _recentNotes.isEmpty
                ? const Center(
                    child: Text(
                      'Crea tu primera nota',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: _recentNotes.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04), height: 1),
                    itemBuilder: (context, index) {
                      final note = _recentNotes[index];
                      return InkWell(
                        onTap: () => _openNote(note),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(Icons.article_outlined, size: 16, color: const Color(0xFF94A3B8)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 14),
                                ),
                              ),
                              Text(
                                _formatDate(note.updatedAt),
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteboardCard() {
    return GlassBentoCard(
      onTap: _openWhiteboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.draw_outlined, color: Color(0xFF38BDF8), size: 18),
          ),
          const Spacer(),
          const Text(
            'Pizarrón',
            style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Infinito',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCard() {
    return GlassBentoCard(
      onTap: _openAiQuickQuery,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 18),
          ),
          const Spacer(),
          const Text(
            'IA Local',
            style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 12),
              const SizedBox(width: 6),
              const Text(
                'Ollama disponible',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final authService = context.read<AuthService>();
    final cloudLabel = authService.isCloudEnabled ? 'Conectado' : 'Modo local';
    final cloudColor = authService.isCloudEnabled
        ? const Color(0xFF22C55E)
        : const Color(0xFF94A3B8);

    return GlassBentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cloudColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.cloud_outlined, color: cloudColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sincronización',
                  style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  cloudLabel,
                  style: TextStyle(color: cloudColor, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'v$_appVersion',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────────
  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
