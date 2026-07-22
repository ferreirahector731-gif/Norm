import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps the app with global keyboard shortcuts.
class ShortcutsWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onOpenCommandMenu;
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewNote;

  const ShortcutsWrapper({
    super.key,
    required this.child,
    required this.onOpenCommandMenu,
    required this.onToggleSidebar,
    required this.onNewNote,
  });

  @override
  Widget build(BuildContext context) {
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;

    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: {
          SingleActivator(
            LogicalKeyboardKey.keyK,
            control: !isMacOS,
            meta: isMacOS,
          ): onOpenCommandMenu,
          SingleActivator(
            LogicalKeyboardKey.keyB,
            control: !isMacOS,
            meta: isMacOS,
          ): onToggleSidebar,
          SingleActivator(
            LogicalKeyboardKey.keyN,
            control: !isMacOS,
            meta: isMacOS,
          ): onNewNote,
        },
        child: child,
      ),
    );
  }
}
