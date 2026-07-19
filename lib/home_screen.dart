import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late EditorState _editorState;

  @override
  void initState() {
    super.initState();
    // Inicializar el editor con un documento en blanco
    _editorState = EditorState.empty();
  }

  @override
  void dispose() {
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota IA - Editor Base'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'Activar IA Local (Próximamente)',
            onPressed: () {
              // Aquí conectaremos la IA local más adelante
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppFlowyEditor(
            editorState: _editorState,
          ),
        ),
      ),
    );
  }
}
