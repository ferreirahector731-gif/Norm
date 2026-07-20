import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ai/domain/ai_config.dart';
import '../../../ai/presentation/widgets/ai_approval_bar.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/note_document_codec.dart';
import '../../domain/note_model.dart';
import '../editor_blocks/audio_block.dart';
import '../editor_blocks/custom_block_keys.dart';
import '../editor_blocks/placeholder_block.dart';
import '../editor_blocks/whiteboard_block.dart';
import 'whiteboard_canvas.dart';

class EditorWorkspace extends StatefulWidget {
  final NoteModel? note;
  final ValueChanged<NoteModel> onNoteUpdated;
  final VoidCallback? onRequestAiAssist;
  final bool isLoading;

  const EditorWorkspace({
    super.key,
    this.note,
    required this.onNoteUpdated,
    this.onRequestAiAssist,
    this.isLoading = false,
  });

  @override
  State<EditorWorkspace> createState() => _EditorWorkspaceState();
}

class _EditorWorkspaceState extends State<EditorWorkspace> {
  late EditorState _editorState;
  final TextEditingController _titleController = TextEditingController();

  bool _isRecording = false;
  bool _showAIApproval = false;
  String _aiGeneratedContent = '';
  String _aiExplanation = '';
  Node? _pendingAINode;
  bool _isLoadingAI = false;
  bool _aiGenerationCancelled = false;
  String? _documentSnapshot;
  int _loadingDotCount = 0;
  Timer? _loadingTimer;

  Timer? _saveDebounce;
  StreamSubscription<EditorTransactionValue>? _editorSubscription;

  @override
  void initState() {
    super.initState();
    _editorState = EditorState.blank(withInitialText: true);
    _setupEditor();
    AIConfigService.load();
  }

  @override
  void didUpdateWidget(EditorWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note?.id != oldWidget.note?.id) {
      _cancelAIGeneration();
      _loadNote(widget.note);
    }
  }

  @override
  void dispose() {
    _cancelAIGeneration();
    _editorSubscription?.cancel();
    _editorState.dispose();
    _titleController.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _setupEditor() {
    _editorState.selectionMenuItems = [
      ...standardSelectionMenuItems,
      _whiteboardSlashItem(),
      _imageSlashItem(),
      _videoSlashItem(),
      _audioSlashItem(),
      _aiSlashItem(),
    ];
    _bindEditorListener();
  }

  void _bindEditorListener() {
    _editorSubscription?.cancel();
    _editorSubscription = _editorState.transactionStream.listen((_) {
      _scheduleSave();
    });
  }

  void _cancelAIGeneration() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    _isLoadingAI = false;
    _aiGenerationCancelled = true;
    _showAIApproval = false;
    _pendingAINode = null;
    _documentSnapshot = null;
    _aiGeneratedContent = '';
    _aiExplanation = '';
  }

  void _loadNote(NoteModel? note) {
    if (note == null) return;
    _editorSubscription?.cancel();
    _editorState.dispose();

    final document = NoteDocumentCodec.decode(note.contentJson);
    _editorState = EditorState(document: document);
    _setupEditor();

    setState(() {});

    _titleController.text = note.title;
    _titleController.selection = TextSelection.collapsed(
      offset: note.title.length,
    );
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final note = widget.note;
    if (note == null) return;

    note.title = _titleController.text.isNotEmpty
        ? _titleController.text
        : 'Sin título';
    note.contentJson = NoteDocumentCodec.encode(_editorState.document);
    note.updatedAt = DateTime.now();
    note.isDirty = true;

    widget.onNoteUpdated(note);
  }

  // ── Build ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.isLoading) {
      return Container(
        color: scheme.surface,
        child: const ShimmerEditor(),
      );
    }

    final isWhiteboard = widget.note != null &&
        widget.note!.contentJson.trim().startsWith('[');

    if (widget.note == null) {
      return Container(
        color: scheme.surface,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 36,
                        color: scheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Selecciona una nota',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explora tus notas en el panel lateral.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
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

    if (isWhiteboard) {
      return WhiteboardCanvas(note: widget.note!);
    }

    return Container(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(context),
          const SizedBox(height: 8),
          _buildFloatingToolbar(context),
          const SizedBox(height: 12),
          Expanded(
            child: _buildEditor(context),
          ),
          if (_showAIApproval)
            AIApprovalBar(
              message: _aiExplanation,
              onAccept: _isLoadingAI ? null : _acceptAIContent,
              onRegenerate: _isLoadingAI ? null : _regenerateAIContent,
              onCancel: _cancelAIContent,
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 56, top: 24),
      child: TextField(
        controller: _titleController,
        style: theme.textTheme.headlineLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Título de la nota...',
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
          ),
        ),
        onChanged: (_) => _scheduleSave(),
      ),
    );
  }

  Widget _buildFloatingToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _toolBtn(Icons.format_bold, 'Negrita',
                      BuiltInAttributeKey.bold, null),
                  _toolBtn(Icons.format_italic, 'Cursiva',
                      BuiltInAttributeKey.italic, null),
                  _toolBtn(Icons.format_underline, 'Subrayado',
                      BuiltInAttributeKey.underline, null),
                  _divider(),
                  _toolBtn(
                      Icons.code, 'Código', BuiltInAttributeKey.code, null),
                  _toolBtn(Icons.format_list_bulleted, 'Lista', null,
                      'bulleted'),
                  _toolBtn(Icons.format_list_numbered, 'Numerada', null,
                      'numbered'),
                  _toolBtn(Icons.check_box_outlined, 'Tareas', null,
                      'checkbox'),
                  _divider(),
                  _toolBtn(Icons.title, 'H1', null, 'h1'),
                  _toolBtn(Icons.looks_two, 'H2', null, 'h2'),
                  _toolBtn(Icons.looks_3, 'H3', null, 'h3'),
                  _divider(),
                  _toolBtn(
                      Icons.draw_outlined, 'Pizarrón', null, 'whiteboard'),
                  _toolBtn(
                      Icons.image_outlined, 'Imagen', null, 'image'),
                  _toolBtn(
                      Icons.videocam_outlined, 'Video', null, 'video'),
                  _divider(),
                  _toolBtn(
                    _isRecording
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    _isRecording ? 'Detener' : 'Audio',
                    null,
                    'audio',
                    isActiveOverride: _isRecording,
                  ),
                  _divider(),
                  _toolBtn(Icons.auto_awesome, 'IA', null, 'ai',
                      isActiveOverride: _showAIApproval),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _toolBtn(IconData icon, String tooltip, String? attribute,
      String? blockAction,
      {bool? isActiveOverride}) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = isActiveOverride ??
        (attribute != null ? _formatActive(attribute) : false);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? scheme.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _handleToolAction(blockAction, attribute),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  void _handleToolAction(String? blockAction, String? attribute) {
    if (attribute != null) {
      _editorState.toggleAttribute(attribute);
      return;
    }
    switch (blockAction) {
      case 'bulleted':
        _wrapInBlock('bulleted_list');
      case 'numbered':
        _wrapInBlock('numbered_list');
      case 'checkbox':
        _toggleCheckbox();
      case 'h1':
        _wrapInBlock('heading', {'heading': '1'});
      case 'h2':
        _wrapInBlock('heading', {'heading': '2'});
      case 'h3':
        _wrapInBlock('heading', {'heading': '3'});
      case 'whiteboard':
        _insertNodeAfterSelection(whiteboardNode());
      case 'image':
        _insertNodeAfterSelection(imagePlaceholderNode());
      case 'video':
        _insertNodeAfterSelection(videoPlaceholderNode());
      case 'audio':
        _toggleRecording();
      case 'ai':
        _requestAIAssist();
    }
  }

  Future<void> _wrapInBlock(String type,
      [Map<String, dynamic>? attrs]) async {
    final selection = _editorState.selection;
    if (selection == null) return;
    await _editorState.formatNode(selection, (node) {
      return node.copyWith(
        type: type,
        attributes: {...node.attributes, ...?attrs},
      );
    });
  }

  bool _formatActive(String key) {
    final selection = _editorState.selection;
    if (selection == null || selection.isCollapsed) return false;
    final nodes = _editorState.getNodesInSelection(selection);
    if (nodes.isEmpty) return false;
    return nodes.allSatisfyInSelection(selection, (delta) {
      return delta.everyAttributes((attributes) => attributes[key] == true);
    });
  }

  Future<void> _toggleCheckbox() async {
    final selection = _editorState.selection;
    if (selection == null) return;
    final nodes = _editorState.getNodesInSelection(selection);
    if (nodes.isEmpty) return;
    final isChecked =
        nodes.first.attributes[BuiltInAttributeKey.checkbox] == true;
    await _editorState.formatNode(
      selection,
      (node) => node.copyWith(
        attributes: {
          ...node.attributes,
          BuiltInAttributeKey.checkbox: !isChecked,
        },
      ),
    );
  }

  void _insertNodeAfterSelection(Node newNode) {
    final selection = _editorState.selection;
    final path = selection?.start.path;
    if (path == null) return;
    final transaction = _editorState.transaction;
    transaction.insertNode(path.next, newNode);
    _editorState.apply(transaction);
  }

  void _handleFileDrop(String path) {
    final type = FileUtils.detectMediaType(path);
    switch (type) {
      case 'image':
        _insertNodeAfterSelection(imagePlaceholderNode(path: path));
      case 'video':
        _insertNodeAfterSelection(videoPlaceholderNode(path: path));
      case 'audio':
        _insertNodeAfterSelection(audioBlockNode(path: path));
    }
  }

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      final text = clipboardData.text!;
      if (text.startsWith('/') ||
          text.startsWith(r'\') ||
          RegExp(r'^[A-Z]:\\').hasMatch(text)) {
        if (File(text).existsSync()) {
          _handleFileDrop(text);
          return;
        }
      }
    }
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    if (!_isRecording) {
      _insertNodeAfterSelection(audioBlockNode(
        path: 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
        caption: 'Nota de voz',
      ));
    }
  }

  // ── Slash menu items ───────────────────────────────

  SelectionMenuItem _whiteboardSlashItem() => SelectionMenuItem.node(
        getName: () => 'Pizarrón',
        keywords: ['pizarron', 'dibujo', 'whiteboard', 'draw'],
        iconBuilder: (_, onSelected, style) => Icon(
          Icons.draw_outlined,
          size: 16,
          color: onSelected ? const Color(0xff7B2CBF) : null,
        ),
        nodeBuilder: (state, context) => whiteboardNode(),
      );

  SelectionMenuItem _imageSlashItem() => SelectionMenuItem.node(
        getName: () => 'Imagen',
        keywords: ['imagen', 'image', 'foto', 'photo'],
        iconBuilder: (_, onSelected, style) => Icon(
          Icons.image_outlined,
          size: 16,
          color: onSelected ? const Color(0xff7B2CBF) : null,
        ),
        nodeBuilder: (state, context) => imagePlaceholderNode(),
      );

  SelectionMenuItem _videoSlashItem() => SelectionMenuItem.node(
        getName: () => 'Video',
        keywords: ['video', 'vid'],
        iconBuilder: (_, onSelected, style) => Icon(
          Icons.videocam_outlined,
          size: 16,
          color: onSelected ? const Color(0xff7B2CBF) : null,
        ),
        nodeBuilder: (state, context) => videoPlaceholderNode(),
      );

  SelectionMenuItem _audioSlashItem() => SelectionMenuItem.node(
        getName: () => 'Audio',
        keywords: ['audio', 'sonido', 'voz', 'record'],
        iconBuilder: (_, onSelected, style) => Icon(
          Icons.mic_outlined,
          size: 16,
          color: onSelected ? const Color(0xff7B2CBF) : null,
        ),
        nodeBuilder: (state, context) => audioBlockNode(),
      );

  SelectionMenuItem _aiSlashItem() => SelectionMenuItem(
        getName: () => 'Asistente IA',
        keywords: ['ai', 'ia', 'asistente', 'helper', 'escribir'],
        icon: (_, onSelected, style) => Icon(
          Icons.auto_awesome,
          size: 16,
          color: onSelected ? const Color(0xff7B2CBF) : null,
        ),
        handler: (editorState, menuService, context) {
          menuService.dismiss();
          _requestAIAssist();
        },
      );

  // ── AI consent flow ────────────────────────────────

  void _requestAIAssist() {
    final selection = _editorState.selection;
    if (selection == null) return;

    final node = _editorState.getNodeAtPath(selection.start.path);
    final contextText =
        node?.delta != null ? node!.delta!.toPlainText() : '';

    _documentSnapshot = NoteDocumentCodec.encode(_editorState.document);

    final aiNode = paragraphNode(
      text: 'Generando',
      attributes: {'_ai_pending': true, '_ai_loading': true},
    );

    final path = selection.start.path;
    final transaction = _editorState.transaction;
    transaction.insertNode(path.next, aiNode);
    _editorState.apply(transaction);

    setState(() {
      _isLoadingAI = true;
      _showAIApproval = true;
      _aiGeneratedContent = '';
      _aiExplanation = 'La IA está generando contenido...';
      _pendingAINode = aiNode;
    });

    _loadingDotCount = 0;
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || !_isLoadingAI) {
        _loadingTimer?.cancel();
        return;
      }
      _loadingDotCount = (_loadingDotCount + 1) % 4;
      _updateLoadingNodeText();
    });

    _callAIEngine(contextText);
  }

  void _updateLoadingNodeText() {
    if (_pendingAINode == null || !_isLoadingAI) return;
    final dots = '.' * _loadingDotCount;
    final transaction = _editorState.transaction;
    transaction.updateNode(
      _pendingAINode!,
      paragraphNode(
        text: 'Generando$dots',
        attributes: {'_ai_pending': true, '_ai_loading': true},
      ).attributes,
    );
    _editorState.apply(transaction);
  }

  Future<void> _callAIEngine(String contextText) async {
    _aiGenerationCancelled = false;
    final engine = AIEngineService();
    final buffer = StringBuffer();
    var hasFirstChunk = false;

    try {
      await for (final chunk in engine.sendPromptStreaming(contextText)) {
        if (!mounted || _aiGenerationCancelled) return;
        buffer.write(chunk);
        _aiGeneratedContent = buffer.toString();

        if (!hasFirstChunk && buffer.toString().trim().isNotEmpty) {
          hasFirstChunk = true;
          setState(() {
            _aiExplanation = 'Generando contenido...';
          });
        }

        if (_pendingAINode != null) {
          final transaction = _editorState.transaction;
          transaction.updateNode(
            _pendingAINode!,
            paragraphNode(
              text: buffer.toString(),
              attributes: {'_ai_pending': true},
            ).attributes,
          );
          _editorState.apply(transaction);
        }
      }

      if (!mounted || _aiGenerationCancelled) return;
      _loadingTimer?.cancel();
      setState(() {
        _isLoadingAI = false;
        _aiExplanation = _aiGeneratedContent.isNotEmpty
            ? 'La IA ha generado contenido. Revisa el resultado antes de aceptarlo.'
            : 'La IA no generó contenido.';
      });
    } catch (e) {
      _loadingTimer?.cancel();
      if (!mounted) return;
      final errorMsg = 'Error: $e';
      setState(() {
        _isLoadingAI = false;
        _aiGeneratedContent = errorMsg;
        _aiExplanation = 'Ocurrió un error al generar contenido.';
      });
      if (_pendingAINode != null) {
        final transaction = _editorState.transaction;
        transaction.updateNode(
          _pendingAINode!,
          paragraphNode(
            text: errorMsg,
            attributes: {'_ai_pending': true},
          ).attributes,
        );
        _editorState.apply(transaction);
      }
    }
  }

  void _acceptAIContent() {
    _loadingTimer?.cancel();
    _aiGenerationCancelled = true;
    if (_pendingAINode == null) return;

    if (_aiGeneratedContent.isNotEmpty) {
      final transaction = _editorState.transaction;
      transaction.updateNode(
        _pendingAINode!,
        paragraphNode(text: _aiGeneratedContent).attributes,
      );
      _editorState.apply(transaction);
    }

    setState(() {
      _showAIApproval = false;
      _aiGeneratedContent = '';
      _aiExplanation = '';
      _pendingAINode = null;
      _isLoadingAI = false;
      _documentSnapshot = null;
    });

    _scheduleSave();
  }

  void _regenerateAIContent() {
    _aiGenerationCancelled = true;
    _documentSnapshot = NoteDocumentCodec.encode(_editorState.document);
    _loadingTimer?.cancel();

    if (_pendingAINode != null) {
      final transaction = _editorState.transaction;
      transaction.updateNode(
        _pendingAINode!,
        paragraphNode(
          text: 'Generando',
          attributes: {'_ai_pending': true, '_ai_loading': true},
        ).attributes,
      );
      _editorState.apply(transaction);
    }

    _loadingDotCount = 0;
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || !_isLoadingAI) {
        _loadingTimer?.cancel();
        return;
      }
      _loadingDotCount = (_loadingDotCount + 1) % 4;
      _updateLoadingNodeText();
    });

    setState(() {
      _isLoadingAI = true;
      _aiGeneratedContent = '';
      _aiExplanation = 'Regenerando...';
    });
    _callAIEngine('');
  }

  void _cancelAIContent() {
    _loadingTimer?.cancel();
    _aiGenerationCancelled = true;

    if (_documentSnapshot != null && _pendingAINode != null) {
      final document = NoteDocumentCodec.decode(_documentSnapshot!);
      _editorSubscription?.cancel();
      _editorState.dispose();
      _editorState = EditorState(document: document);
      _setupEditor();
    } else if (_pendingAINode != null) {
      final transaction = _editorState.transaction;
      transaction.deleteNode(_pendingAINode!);
      _editorState.apply(transaction);
    }

    setState(() {
      _showAIApproval = false;
      _aiGeneratedContent = '';
      _aiExplanation = '';
      _pendingAINode = null;
      _isLoadingAI = false;
      _documentSnapshot = null;
    });
  }

  Widget _buildEditor(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 56, bottom: 24),
      child: DragTarget<String>(
        onAcceptWithDetails: (details) {
          _handleFileDrop(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          return Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (HardwareKeyboard.instance.isControlPressed ||
                      HardwareKeyboard.instance.isMetaPressed) &&
                  event.logicalKey == LogicalKeyboardKey.keyV) {
                _handlePaste();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Container(
              decoration: candidateData.isNotEmpty
                  ? BoxDecoration(
                      border: Border.all(
                        color: const Color(0xff7B2CBF),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: AppFlowyEditor(
                key: ValueKey(widget.note?.id),
                editorState: _editorState,
                blockComponentBuilders: {
                  ...standardBlockComponentBuilderMap,
                  WhiteboardBlockKeys.type:
                      WhiteboardBlockComponentBuilder(),
                  ImagePlaceholderKeys.type:
                      PlaceholderBlockComponentBuilder(
                    blockType: ImagePlaceholderKeys.type,
                    iconData: Icons.image_outlined,
                    label: 'Imagen',
                  ),
                  VideoPlaceholderKeys.type:
                      PlaceholderBlockComponentBuilder(
                    blockType: VideoPlaceholderKeys.type,
                    iconData: Icons.videocam_outlined,
                    label: 'Video',
                  ),
                  AudioBlockKeys.type:
                      AudioBlockComponentBuilder(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
