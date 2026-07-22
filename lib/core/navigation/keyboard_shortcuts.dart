import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ShortcutsWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onCommandPalette;
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewNote;

  const ShortcutsWrapper({
    super.key,
    required this.child,
    required this.onCommandPalette,
    required this.onToggleSidebar,
    required this.onNewNote,
  });

  @override
  Widget build(BuildContext context) {
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.keyK, meta: isMacOS, control: !isMacOS): onCommandPalette,
        SingleActivator(LogicalKeyboardKey.keyB, meta: isMacOS, control: !isMacOS): onToggleSidebar,
        SingleActivator(LogicalKeyboardKey.keyN, meta: isMacOS, control: !isMacOS): onNewNote,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
