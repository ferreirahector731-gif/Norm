import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../ai/domain/ai_config.dart';
import '../../../core/services/sync_manager.dart';
import '../services/settings_service.dart';
import '../../ai/domain/retention_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AIProvider _aiProvider;
  late TextEditingController _apiKeyController;
  bool _showApiKey = false;
  String _syncStatus = 'Inactivo';
  late AnimationController _syncSpinController;
  String _appVersion = '';
  String _buildNumber = '';
  MemoryRetention _memoryRetention = MemoryRetention.oneMonth;

  @override
  void initState() {
    super.initState();
    _syncSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _apiKeyController = TextEditingController();
    _loadConfig();
    _loadVersion();
    _loadMemoryRetention();
    SyncManager().isSyncingNotifier.addListener(_onSyncChanged);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (_) {
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  void _onSyncChanged() {
    final isSyncing = SyncManager().isSyncingNotifier.value;
    if (isSyncing) {
      _syncSpinController.repeat();
      setState(() => _syncStatus = 'Sincronizando...');
    } else {
      _syncSpinController.stop();
      _syncSpinController.reset();
      if (mounted) setState(() => _syncStatus = '');
    }
  }

  Future<void> _loadConfig() async {
    final config = await AIConfigService.load();
    setState(() {
      _aiProvider = config.provider;
      _apiKeyController.text = config.externalApiKey ?? '';
    });
  }

  @override
  void dispose() {
    _syncSpinController.dispose();
    _apiKeyController.dispose();
    SyncManager().isSyncingNotifier.removeListener(_onSyncChanged);
    super.dispose();
  }

  Future<void> _loadMemoryRetention() async {
    setState(() {
      _memoryRetention = SettingsService.memoryRetention;
    });
  }

  Future<void> _onMemoryRetentionChanged(MemoryRetention value) async {
    setState(() => _memoryRetention = value);
    await SettingsService.setMemoryRetention(value);
    _syncRetentionToCleanup(value);
  }

  void _syncRetentionToCleanup(MemoryRetention value) {
    final map = <MemoryRetention, RetentionPeriod>{
      MemoryRetention.oneWeek: RetentionPeriod.week,
      MemoryRetention.oneMonth: RetentionPeriod.month,
      MemoryRetention.threeMonths: RetentionPeriod.threeMonths,
      MemoryRetention.forever: RetentionPeriod.never,
    };
    final period = map[value] ?? RetentionPeriod.month;
    RetentionService().updatePeriod(period);
  }

  Future<void> _saveConfig() async {
    await AIConfigService.save(
      AIConfig(
        provider: _aiProvider,
        externalApiKey: _apiKeyController.text.isNotEmpty
            ? _apiKeyController.text
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo semitransparente
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.black38),
          ),
          // Panel deslizante
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(28)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.88),
                      border: Border(
                        right: BorderSide(
                          color: scheme.outlineVariant.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildThemeSection(context),
                                const SizedBox(height: 32),
                                _buildAISection(context),
                                const SizedBox(height: 32),
                                _buildMemorySection(context),
                                const SizedBox(height: 32),
                                _buildSyncSection(context),
                                const SizedBox(height: 32),
                                _buildVersionInfo(context),
                                const SizedBox(height: 48),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 24,
        right: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Ajustes',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: scheme.outline),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Tema ───────────────────────────────────────

  Widget _buildThemeSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'INTERFAZ Y TEMA',
      icon: Icons.palette_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _themeCircle(context, ThemeModeType.dark, const Color(0xff0B0B0F)),
            _themeCircle(context, ThemeModeType.light, const Color(0xffF5F5F0)),
            _themeCircle(context, ThemeModeType.sepia, const Color(0xffF4ECD8)),
          ],
        ),
      ),
    );
  }

  Widget _themeCircle(BuildContext context, ThemeModeType type, Color color) {
    final provider = context.watch<ThemeProvider>();
    final isSelected = provider.currentTheme == type;

    return GestureDetector(
      onTap: () => provider.setTheme(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : color == const Color(0xff0B0B0F)
                    ? Colors.white24
                    : Colors.black12,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? Icon(Icons.check,
                size: 22,
                color: type == ThemeModeType.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary)
            : null,
      ),
    );
  }

  // ── IA ──────────────────────────────────────────

  Widget _buildAISection(BuildContext context) {
    return _buildSection(
      context,
      title: 'MOTOR DE IA',
      icon: Icons.auto_awesome_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildProviderSelector(context),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _aiProvider == AIProvider.externalAPI
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildApiKeyField(context),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _providerOption(AIProvider.localEmbedded, 'Local'),
          _providerOption(AIProvider.ollamaLocal, 'Ollama'),
          _providerOption(AIProvider.externalAPI, 'API'),
        ],
      ),
    );
  }

  Widget _providerOption(AIProvider provider, String label) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _aiProvider == provider;

    return Expanded(
      child: GestureDetector(
        onTap: () {
        setState(() => _aiProvider = provider);
        _saveConfig();
      },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyField(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'API Key',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showApiKey = !_showApiKey),
                child: Icon(
                  _showApiKey ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: scheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: !_showApiKey,
            onChanged: (_) => _saveConfig(),
            decoration: InputDecoration(
              hintText: 'sk-...',
              hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.4)),
              filled: true,
              fillColor: scheme.surfaceContainerHigh.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: TextStyle(color: scheme.onSurface, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Memoria IA ──────────────────────────────────

  Widget _buildMemorySection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _buildSection(
      context,
      title: 'MEMORIA DE IA',
      icon: Icons.memory_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          ...MemoryRetention.values.map((r) => _retentionOption(r)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.primary.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 14, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Todo el contexto se almacena localmente en tu dispositivo. '
                    'Ningún dato de conversación sale de tu máquina a menos que '
                    'actives explícitamente el modo de búsqueda enriquecida.',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _retentionOption(MemoryRetention retention) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _memoryRetention == retention;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () => _onMemoryRetentionChanged(retention),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? scheme.primary.withOpacity(0.4)
                  : scheme.outlineVariant.withOpacity(0.15),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: isSelected ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 12),
              Text(
                retention.label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sync ────────────────────────────────────────

  Widget _buildSyncSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _buildSection(
      context,
      title: 'SINCRONIZACIÓN',
      icon: Icons.cloud_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: SyncManager().isSyncingNotifier.value
                      ? RotationTransition(
                          key: const ValueKey('spin'),
                          turns: _syncSpinController,
                          child: Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                        )
                      : Container(
                          key: const ValueKey('dot'),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sincronización',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  _syncStatus,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withOpacity(0.9),
                      scheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _forceSync,
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Forzar sincronización'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forceSync() async {
    SyncManager().syncPendingNotes();
    SyncManager().fetchRemoteChanges();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted && !SyncManager().isSyncingNotifier.value) {
      setState(() => _syncStatus = 'Completado');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _syncStatus = '');
    }
  }

  // ── Versión ────────────────────────────────────

  Widget _buildVersionInfo(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: scheme.outline),
              const SizedBox(width: 8),
              Text(
                'v$_appVersion+$_buildNumber',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant.withOpacity(0.5),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Norm — Escritura con IA local',
          style: TextStyle(
            fontSize: 10,
            color: scheme.onSurfaceVariant.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  // ── Util ────────────────────────────────────────

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: scheme.outline),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.outline,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

void showSettings(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
      opaque: false,
      barrierDismissible: true,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
