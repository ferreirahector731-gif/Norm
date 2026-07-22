import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class CommandOption {
  final String keyword;
  final String label;
  final IconData icon;
  final VoidCallback action;

  const CommandOption({
    required this.keyword,
    required this.label,
    required this.icon,
    required this.action,
  });
}

class CommandMenuOverlay extends StatefulWidget {
  final List<CommandOption> options;
  final Widget child;
  final ValueChanged<String>? onQueryChanged;

  const CommandMenuOverlay({
    super.key,
    required this.options,
    required this.child,
    this.onQueryChanged,
  });

  @override
  State<CommandMenuOverlay> createState() => _CommandMenuOverlayState();
}

class _CommandMenuOverlayState extends State<CommandMenuOverlay> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  bool _isOpen = false;
  String _query = '';
  int _selectedIndex = 0;

  List<CommandOption> get _filtered {
    if (_query.isEmpty) return widget.options;
    return widget.options
        .where((o) =>
            o.keyword.contains(_query.toLowerCase()) ||
            o.label.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void open([String initialQuery = '']) {
    if (_isOpen) return;
    _query = initialQuery;
    _selectedIndex = 0;
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
    _isOpen = true;
  }

  void close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void updateQuery(String query) {
    if (!_isOpen) return;
    _query = query;
    _selectedIndex = 0;
    _overlayEntry?.markNeedsBuild();
  }

  bool get isOpen => _isOpen;

  void _execute(CommandOption option) {
    close();
    option.action();
  }

  @override
  void dispose() {
    close();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildOverlay() {
    final filtered = _filtered;
    return Stack(
      children: [
        GestureDetector(onTap: close, child: const SizedBox.expand()),
        CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 48),
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.topLeft,
          child: filtered.isEmpty
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320, maxHeight: 280),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(6),
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.white.withOpacity(0.04),
                            height: 1,
                            indent: 12,
                            endIndent: 12,
                          ),
                          itemBuilder: (context, index) {
                            final option = filtered[index];
                            final isSelected = index == _selectedIndex;
                            return InkWell(
                              onTap: () => _execute(option),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF3B82F6).withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(option.icon, size: 18, color: const Color(0xFF3B82F6)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFFF8FAFC)
                                              : const Color(0xFF94A3B8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '/${option.keyword}',
                                      style: const TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.child,
    );
  }
}
