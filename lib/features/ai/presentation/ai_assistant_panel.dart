import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/database/database_service.dart';
import '../domain/ai_config.dart';
import '../domain/ai_service.dart';
import '../domain/chat_message_model.dart';

class AiAssistantPanel extends StatefulWidget {
  final int? noteId;

  const AiAssistantPanel({super.key, this.noteId});

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  AIReasoningMode _reasoningMode = AIReasoningMode.quick;
  AIProvider _selectedProvider = AIProvider.ollamaLocal;
  bool _dismissedBanner = false;

  @override
  void initState() {
    super.initState();
    _selectedProvider = AIConfigService.current.provider;
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final msgs = await DatabaseService.getChatMessages(
        noteId: widget.noteId,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _messages = msgs.reversed.toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();

    final userMsg = ChatMessage.create(
      noteId: widget.noteId,
      role: MessageRole.user,
      content: text,
      provider: _selectedProvider.name,
      model: _selectedProvider == AIProvider.ollamaLocal
          ? 'llama3.2'
          : AIConfigService.current.externalModel ?? 'gpt-4o-mini',
    );

    setState(() {
      _messages.add(userMsg);
      _isSending = true;
    });
    _scrollToBottom();

    await DatabaseService.saveChatMessage(userMsg);

    final buffer = StringBuffer();
    try {
      await for (final chunk in _aiService.chat(
        history: _messages.where((m) => m.id != userMsg.id).toList(),
        newMessage: text,
        providerOverride: _selectedProvider,
        mode: _reasoningMode,
      )) {
        if (!mounted) return;
        buffer.write(chunk);
        // Actualizar el último mensaje (asistente) en tiempo real
        setState(() {
          if (_messages.isNotEmpty &&
              _messages.last.role == MessageRole.assistant) {
            _messages.last.content = buffer.toString();
          } else {
            _messages.add(ChatMessage.create(
              noteId: widget.noteId,
              role: MessageRole.assistant,
              content: buffer.toString(),
              provider: _selectedProvider.name,
            ));
          }
        });
        _scrollToBottom();
      }

      // Guardar mensaje del asistente completo
      if (buffer.isNotEmpty && mounted) {
        final assistantMsg = ChatMessage.create(
          noteId: widget.noteId,
          role: MessageRole.assistant,
          content: buffer.toString(),
          provider: _selectedProvider.name,
        );
        await DatabaseService.saveChatMessage(assistantMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.create(
          noteId: widget.noteId,
          role: MessageRole.assistant,
          content: 'Error: $e',
          provider: _selectedProvider.name,
        ));
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          _buildHeader(context),
          if (!_dismissedBanner) _buildRetentionBanner(context),
          Expanded(child: _buildMessageList(context)),
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
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isReasoning = _reasoningMode == AIReasoningMode.reasoningX2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Asistente IA',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Selector de modelo
          _buildModelDropdown(context),
          const SizedBox(width: 8),
          // Alternar modo razonamiento
          _buildReasoningToggle(context),
        ],
      ),
    );
  }

  Widget _buildModelDropdown(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AIProvider>(
          value: _selectedProvider,
          isDense: true,
          icon: Icon(Icons.expand_more, size: 16, color: scheme.primary),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
          items: [
            _dropdownItem(AIProvider.ollamaLocal, 'Ollama', Icons.sd_storage),
            _dropdownItem(AIProvider.externalAPI, 'Nube', Icons.cloud),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedProvider = value);
          },
        ),
      ),
    );
  }

  DropdownMenuItem<AIProvider> _dropdownItem(
    AIProvider provider,
    String label,
    IconData icon,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownMenuItem(
      value: provider,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildReasoningToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReasoning = _reasoningMode == AIReasoningMode.reasoningX2;

    return GestureDetector(
      onTap: () {
        setState(() {
          _reasoningMode = isReasoning
              ? AIReasoningMode.quick
              : AIReasoningMode.reasoningX2;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isReasoning
              ? scheme.tertiary.withValues(alpha: 0.15)
              : scheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isReasoning
                ? scheme.tertiary.withValues(alpha: 0.4)
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReasoning ? Icons.psychology : Icons.bolt,
              size: 14,
              color: isReasoning ? scheme.tertiary : scheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              isReasoning ? 'Razonamiento' : 'Rápida',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isReasoning ? scheme.tertiary : scheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionBanner(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.15),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: scheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los chats se eliminan automáticamente tras 30 días. '
                    'Puedes ajustar este plazo en Ajustes.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _dismissedBanner = true),
                  child: Icon(Icons.close,
                      size: 16, color: scheme.outline.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  size: 40, color: scheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'Hola. ¿En qué puedo ayudarte?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg.role == MessageRole.user;
        final isLastAssistant =
            !isUser && index == _messages.length - 1 && _isSending;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _chatAvatar(context, isUser),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? scheme.primary.withValues(alpha: 0.12)
                        : scheme.surfaceContainerLow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft:
                          isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight:
                          isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? scheme.primary.withValues(alpha: 0.15)
                          : scheme.outlineVariant.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.content +
                            (isLastAssistant ? ' ▎' : ''),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(msg.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser) _chatAvatar(context, isUser),
            ],
          ),
        );
      },
    );
  }

  Widget _chatAvatar(BuildContext context, bool isUser) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isUser
            ? scheme.primary.withValues(alpha: 0.15)
            : scheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 14,
        color: isUser
            ? scheme.primary
            : scheme.onSecondaryContainer.withValues(alpha: 0.6),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isSending
                      ? scheme.primary.withValues(alpha: 0.3)
                      : scheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      enabled: !_isSending,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isSending
                            ? 'Generando...'
                            : 'Pregúntale a la IA...',
                        hintStyle: TextStyle(
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : Icon(Icons.send_rounded, color: scheme.primary),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showAiAssistant(BuildContext context, {int? noteId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (_) => AiAssistantPanel(noteId: noteId),
  );
}
