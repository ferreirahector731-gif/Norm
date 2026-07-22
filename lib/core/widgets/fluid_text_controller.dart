import 'package:flutter/material.dart';

class FluidTextController extends TextEditingController {
  final VoidCallback? onSlashTrigger;

  FluidTextController({String? text, this.onSlashTrigger}) : super(text: text);

  @override
  void setText(String newText) {
    super.setText(newText);
  }

  void handleInputChange() {
    final text = super.text;
    if (text.isEmpty) return;

    final lastChar = text[text.length - 1];

    // Trigger command menu on '/'
    if (lastChar == '/' && onSlashTrigger != null) {
      onSlashTrigger!();
    }

    // Auto-convert patterns on space
    if (lastChar == ' ') {
      _convertPatterns();
    }
  }

  void _convertPatterns() {
    final text = super.text;
    if (text.length < 2) return;

    final beforeSpace = text.substring(0, text.length - 1);

    // '- ' → '• '
    if (beforeSpace.endsWith('-')) {
      final newText = beforeSpace.substring(0, beforeSpace.length - 1) + '• ';
      super.text = newText;
      selection = TextSelection.collapsed(offset: newText.length);
      return;
    }

    // '[] ' → '☐ '
    if (beforeSpace.endsWith('[]')) {
      final newText = beforeSpace.substring(0, beforeSpace.length - 2) + '☐ ';
      super.text = newText;
      selection = TextSelection.collapsed(offset: newText.length);
      return;
    }
  }

  /// Extracts the query after the last '/' in the current text.
  String? get slashQuery {
    final text = super.text;
    final slashIndex = text.lastIndexOf('/');
    if (slashIndex == -1) return null;
    return text.substring(slashIndex + 1);
  }
}
