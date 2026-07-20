import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../services/sync_manager.dart';

class CloudSyncStatusWidget extends StatefulWidget {
  final double size;

  const CloudSyncStatusWidget({super.key, this.size = 20});

  @override
  State<CloudSyncStatusWidget> createState() => _CloudSyncStatusWidgetState();
}

class _CloudSyncStatusWidgetState extends State<CloudSyncStatusWidget>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _isOnline = results.any((result) => result != ConnectivityResult.none);
      });
      if (_isOnline) {
        SyncManager().syncPendingNotes();
      }
    });
    SyncManager().isSyncingNotifier.addListener(_onSyncChanged);
  }

  void _onSyncChanged() {
    if (SyncManager().isSyncingNotifier.value) {
      _spinController.repeat();
    } else {
      _spinController.stop();
      _spinController.reset();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _spinController.dispose();
    _connectivitySubscription.cancel();
    SyncManager().isSyncingNotifier.removeListener(_onSyncChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSyncing = SyncManager().isSyncingNotifier.value;

    return Tooltip(
      message: isSyncing
          ? 'Sincronizando...'
          : _isOnline
              ? 'Sincronizado'
              : 'Modo fuera de línea',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isSyncing
            ? RotationTransition(
                key: const ValueKey('syncing'),
                turns: _spinController,
                child: Icon(
                  Icons.sync_rounded,
                  color: theme.colorScheme.primary,
                  size: widget.size,
                ),
              )
            : _isOnline
                ? Icon(
                    Icons.cloud_done_rounded,
                    key: const ValueKey('online'),
                    color: theme.colorScheme.primary,
                    size: widget.size,
                  )
                : Icon(
                    Icons.cloud_off_rounded,
                    key: const ValueKey('offline'),
                    color: Colors.amber,
                    size: widget.size,
                  ),
      ),
    );
  }
}
