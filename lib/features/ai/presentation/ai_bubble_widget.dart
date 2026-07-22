import 'dart:async';

import 'package:flutter/material.dart';

class AIBubbleWidget extends StatefulWidget {
  final Stream<String> aiStream;

  const AIBubbleWidget({super.key, required this.aiStream});

  @override
  State<AIBubbleWidget> createState() => _AIBubbleWidgetState();
}

class _AIBubbleWidgetState extends State<AIBubbleWidget> {
  final StringBuffer _buffer = StringBuffer();
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.aiStream.listen(
      (token) => setState(() => _buffer.write(token)),
      onError: (e) => setState(() => _buffer.write('\n[Error: $e]')),
    );
  }

  @override
  void didUpdateWidget(AIBubbleWidget old) {
    super.didUpdateWidget(old);
    if (old.aiStream != widget.aiStream) {
      _subscription?.cancel();
      _buffer.clear();
      _subscription = widget.aiStream.listen(
        (token) => setState(() => _buffer.write(token)),
        onError: (e) => setState(() => _buffer.write('\n[Error: $e]')),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _buffer.toString();

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 14),
              ),
              const SizedBox(width: 8),
              const Text(
                'IA',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (text.isEmpty) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text.isEmpty ? 'Pensando...' : text,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 14,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
