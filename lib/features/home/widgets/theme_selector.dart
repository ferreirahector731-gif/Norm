import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/theme/custom_theme_service.dart';

const _curatedTypes = [
  NormThemeType.proDark,
  NormThemeType.nordicWoods,
  NormThemeType.classicSlate,
  NormThemeType.matchaZen,
];

const _presetColors = [
  Color(0xFF080710),
  Color(0xFF0D1117),
  Color(0xFF12111A),
  Color(0xFF1A1A2E),
  Color(0xFF1E293B),
  Color(0xFF2E3440),
  Color(0xFF334155),
  Color(0xFF3B4252),
  Color(0xFF151211),
  Color(0xFF1E1A18),
  Color(0xFFF3F4F0),
  Color(0xFFFFFFFF),
  Color(0xFFF8FAFC),
  Color(0xFFECEFF4),
  Color(0xFF5E6AD2),
  Color(0xFF88C0D0),
  Color(0xFF38BDF8),
  Color(0xFF238636),
  Color(0xFF52796F),
  Color(0xFFD4A373),
  Color(0xFF34D399),
  Color(0xFF3B82F6),
];

class ThemeSelector extends StatefulWidget {
  const ThemeSelector({super.key});

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  List<CustomNormTheme> _customThemes = [];
  String? _importError;

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    await CustomThemeService.loadAll();
    if (!mounted) return;
    setState(() {
      _customThemes = List.from(CustomThemeService.current);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'INTERFAZ Y TEMAS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _curatedTypes.map((type) {
              final t = type.theme;
              return _buildCircle(
                color: t.accent,
                bgColor: t.canvasBg,
                isSelected: themeProvider.activeCustomTheme == null && themeProvider.currentTheme == type,
                label: type.displayName,
                onTap: () => themeProvider.setTheme(type),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'TUS TEMAS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Crear', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
              ),
            ],
          ),
        ),
        if (_customThemes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Aún no has creado temas personalizados.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          ..._customThemes.map((ct) => _buildCustomThemeTile(themeProvider, ct)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Divider(height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'IMPORTAR',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showImportDialog,
                icon: const Icon(Icons.file_upload_outlined, size: 14),
                label: const Text('Pegar JSON', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
              ),
            ],
          ),
        ),
        if (_importError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _importError!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
            ),
          ),
        if (themeProvider.activeCustomTheme != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _exportTheme(themeProvider.activeCustomTheme!),
                icon: const Icon(Icons.file_download_outlined, size: 14),
                label: const Text('Exportar tema activo', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCircle({
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
                  : [],
            ),
            child: Center(
              child: isSelected
                  ? Icon(Icons.check, size: 18, color: color)
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomThemeTile(ThemeProvider themeProvider, CustomNormTheme ct) {
    final isActive = themeProvider.activeCustomTheme?.id == ct.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => themeProvider.setCustomTheme(ct),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ct.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? ct.accent : Colors.grey.withOpacity(0.3),
                  width: isActive ? 2.5 : 1,
                ),
                boxShadow: isActive
                    ? [BoxShadow(color: ct.accent.withOpacity(0.4), blurRadius: 8)]
                    : [],
              ),
              child: Center(
                child: isActive
                    ? Icon(Icons.check, size: 14, color: ct.accent)
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ct.accent,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => themeProvider.setCustomTheme(ct),
              child: Text(
                ct.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? ct.accent : const Color(0xFFF8FAFC),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _exportTheme(ct),
            icon: const Icon(Icons.file_download_outlined, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            color: const Color(0xFF94A3B8),
            tooltip: 'Exportar JSON',
          ),
          IconButton(
            onPressed: () => _deleteTheme(ct.id),
            icon: const Icon(Icons.delete_outline, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            color: const Color(0xFFEF4444).withOpacity(0.7),
            tooltip: 'Eliminar tema',
          ),
        ],
      ),
    );
  }

  void _exportTheme(CustomNormTheme theme) {
    final json = CustomThemeService.exportTheme(theme);
    Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteTheme(String id) async {
    await CustomThemeService.delete(id);
    if (!mounted) return;
    final themeProvider = context.read<ThemeProvider>();
    if (themeProvider.activeCustomTheme?.id == id) {
      themeProvider.clearCustomTheme();
    }
    await _loadThemes();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => _ThemeCreateDialog(
        onSaved: (theme) async {
          await CustomThemeService.save(theme);
          if (!mounted) return;
          context.read<ThemeProvider>().setCustomTheme(theme);
          await _loadThemes();
        },
      ),
    );
  }

  void _showImportDialog() {
    _importError = null;
    showDialog(
      context: context,
      builder: (_) => _ThemeImportDialog(
        onImport: (jsonString) async {
          try {
            final theme = CustomThemeService.importTheme(jsonString);
            await CustomThemeService.save(theme);
            if (!mounted) return;
            context.read<ThemeProvider>().setCustomTheme(theme);
            await _loadThemes();
            setState(() => _importError = null);
          } on FormatException catch (e) {
            setState(() => _importError = e.message);
          } catch (e) {
            setState(() => _importError = 'Error al importar: $e');
          }
        },
      ),
    );
  }
}

class _ThemeCreateDialog extends StatefulWidget {
  final ValueChanged<CustomNormTheme> onSaved;
  const _ThemeCreateDialog({required this.onSaved});

  @override
  State<_ThemeCreateDialog> createState() => _ThemeCreateDialogState();
}

class _ThemeCreateDialogState extends State<_ThemeCreateDialog> {
  final _nameCtrl = TextEditingController();
  Color _background = const Color(0xFF080710);
  Color _surface = const Color(0xFF12111A);
  Color _card = const Color(0xFF1E293B);
  Color _textMain = const Color(0xFFF4F4F8);
  Color _accent = const Color(0xFF5E6AD2);

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF12111A) : const Color(0xFFFFFFFF);
    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Crear tema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Nombre del tema',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            _buildColorField('Fondo', _background, (c) => _background = c),
            _buildColorField('Superficie', _surface, (c) => _surface = c),
            _buildColorField('Tarjeta', _card, (c) => _card = c),
            _buildColorField('Texto', _textMain, (c) => _textMain = c),
            _buildColorField('Acento', _accent, (c) => _accent = c),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final id = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
            widget.onSaved(CustomNormTheme(
              id: id,
              name: name,
              background: _background,
              surface: _surface,
              card: _card,
              textMain: _textMain,
              accent: _accent,
            ));
            Navigator.of(context).pop();
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildColorField(String label, Color current, ValueChanged<Color> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _presetColors.map((c) {
              final selected = c.value == current.value;
              return GestureDetector(
                onTap: () => setState(() => onChanged(c)),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.grey.withOpacity(0.4),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: selected
                      ? const Center(
                          child: Icon(Icons.check, size: 12, color: Colors.white),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeImportDialog extends StatefulWidget {
  final ValueChanged<String> onImport;
  const _ThemeImportDialog({required this.onImport});

  @override
  State<_ThemeImportDialog> createState() => _ThemeImportDialogState();
}

class _ThemeImportDialogState extends State<_ThemeImportDialog> {
  final _jsonCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _jsonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF12111A) : const Color(0xFFFFFFFF);
    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Importar tema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _jsonCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Pega el JSON del tema aquí...',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final text = _jsonCtrl.text.trim();
            if (text.isEmpty) return;
            try {
              CustomThemeService.importTheme(text);
              widget.onImport(text);
              Navigator.of(context).pop();
            } on FormatException catch (e) {
              setState(() => _error = e.message);
            } catch (e) {
              setState(() => _error = 'Error: $e');
            }
          },
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
