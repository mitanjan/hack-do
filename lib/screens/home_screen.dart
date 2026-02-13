import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/sync_service.dart';
import '../theme/matrix_theme.dart';
import '../widgets/diagonal_layout.dart';
import '../widgets/tiling_layout.dart';
import '../widgets/task_input_dialog.dart';
import 'sync_screen.dart';

enum TaskFilter { all, ongoing, done }

extension TaskFilterInfo on TaskFilter {
  String get label => switch (this) {
        TaskFilter.all => 'ALL',
        TaskFilter.ongoing => 'ONGOING',
        TaskFilter.done => 'DONE',
      };

  IconData get icon => switch (this) {
        TaskFilter.all => Icons.all_inclusive,
        TaskFilter.ongoing => Icons.play_circle_outline,
        TaskFilter.done => Icons.check_circle_outline,
      };
}

class HomeScreen extends StatefulWidget {
  final TaskService taskService;
  final SyncService syncService;

  const HomeScreen({
    super.key,
    required this.taskService,
    required this.syncService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDiagonalLayout = true;
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  final _random = Random();

  // Cached filtered list — recomputed only when _tasks or _filter changes
  List<Task> _cachedFiltered = [];
  List<Task>? _cachedFilterSource;
  TaskFilter? _cachedFilterType;

  // Single global tick stream for all timer displays
  late final StreamController<void> _tickController;
  late final Stream<void> _tickStream;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickController = StreamController<void>.broadcast();
    _tickStream = _tickController.stream;
    _loadTasks();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _tickController.close();
    super.dispose();
  }

  void _syncTickTimer() {
    final hasOngoing = _tasks.any((t) => t.isOngoing);
    if (hasOngoing && _tickTimer == null) {
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _tickController.add(null);
      });
    } else if (!hasOngoing && _tickTimer != null) {
      _tickTimer!.cancel();
      _tickTimer = null;
    }
  }

  void _openSyncScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SyncScreen(
          syncService: widget.syncService,
          onSyncComplete: _loadTasks,
        ),
      ),
    ).then((_) {
      _loadTasks();
    });
  }

  void _loadTasks() {
    setState(() {
      _tasks = widget.taskService.getAll()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      // Invalidate filter cache
      _cachedFilterSource = null;
    });
    _syncTickTimer();
  }

  List<Task> get _filteredTasks {
    if (identical(_cachedFilterSource, _tasks) && _cachedFilterType == _filter) {
      return _cachedFiltered;
    }
    _cachedFilterSource = _tasks;
    _cachedFilterType = _filter;
    switch (_filter) {
      case TaskFilter.ongoing:
        _cachedFiltered = _tasks.where((t) => t.isOngoing).toList();
      case TaskFilter.done:
        _cachedFiltered = _tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        _cachedFiltered = _tasks;
    }
    return _cachedFiltered;
  }

  Future<void> _showTaskDialog({Task? task}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskInputDialog(existingTask: task),
    );

    if (result == null) return;

    if (task != null) {
      task.title = result['title'];
      task.description = result['description'];
      task.priority = result['priority'];
      task.dueDate = result['dueDate'];
      task.progress = result['progress'] ?? '';
      await widget.taskService.update(task);
    } else {
      await widget.taskService.add(
        title: result['title'],
        description: result['description'],
        priority: result['priority'],
        dueDate: result['dueDate'],
        colorIndex: _random.nextInt(MatrixTheme.cardColors.length),
        progress: result['progress'] ?? '',
      );
    }
    _loadTasks();
  }

  Future<void> _confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '> CONFIRM DELETE_',
          style: TextStyle(
            color: MatrixTheme.primaryGreen,
            shadows: MatrixTheme.glowShadow(blurRadius: 6),
          ),
        ),
        content: Text(
          'Delete "${task.title}"?',
          style: const TextStyle(color: MatrixTheme.primaryGreen),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE',
                style: TextStyle(color: MatrixTheme.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.taskService.delete(task.id);
      _loadTasks();
    }
  }

  Future<void> _toggleComplete(Task task) async {
    await widget.taskService.toggleComplete(task.id);
    _loadTasks();
  }

  Future<void> _toggleOngoing(Task task) async {
    await widget.taskService.toggleOngoing(task.id);
    _loadTasks();
  }

  Future<void> _resetTimer(Task task) async {
    await widget.taskService.resetTimer(task.id);
    _loadTasks();
  }

  void _cycleFilter() {
    setState(() {
      _filter = TaskFilter.values[(_filter.index + 1) % TaskFilter.values.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: _cycleFilter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _filter == TaskFilter.all
                    ? MatrixTheme.primaryGreen.withValues(alpha: 0.3)
                    : MatrixTheme.primaryGreen,
              ),
              color: _filter == TaskFilter.all
                  ? Colors.transparent
                  : MatrixTheme.primaryGreen.withValues(alpha: 0.15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_filter.icon, size: 16, color: MatrixTheme.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  _filter.label,
                  style: TextStyle(
                    color: MatrixTheme.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    shadows: _filter != TaskFilter.all
                        ? MatrixTheme.glowShadow(blurRadius: 6)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          _SyncButton(
            syncService: widget.syncService,
            onPressed: _openSyncScreen,
          ),
          IconButton(
            icon: Icon(
              _isDiagonalLayout ? Icons.grid_view_rounded : Icons.layers,
            ),
            tooltip:
                _isDiagonalLayout ? 'Switch to tiling' : 'Switch to diagonal',
            onPressed: () {
              setState(() => _isDiagonalLayout = !_isDiagonalLayout);
            },
          ),
        ],
      ),
      body: _isDiagonalLayout
          ? DiagonalLayout(
              tasks: filtered,
              tickStream: _tickStream,
              onTap: (t) => _showTaskDialog(task: t),
              onToggleComplete: _toggleComplete,
              onDelete: _confirmDelete,
              onToggleOngoing: _toggleOngoing,
              onResetTimer: _resetTimer,
            )
          : TilingLayout(
              tasks: filtered,
              tickStream: _tickStream,
              onTap: (t) => _showTaskDialog(task: t),
              onToggleComplete: _toggleComplete,
              onDelete: _confirmDelete,
              onToggleOngoing: _toggleOngoing,
              onResetTimer: _resetTimer,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// Isolated widget that subscribes to peer changes independently,
/// avoiding full HomeScreen rebuilds when peer count changes.
class _SyncButton extends StatefulWidget {
  final SyncService syncService;
  final VoidCallback onPressed;

  const _SyncButton({
    required this.syncService,
    required this.onPressed,
  });

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> {
  int _peerCount = 0;

  @override
  void initState() {
    super.initState();
    _peerCount = widget.syncService.peers.length;
    widget.syncService.addListener(_onPeersChanged);
  }

  @override
  void dispose() {
    widget.syncService.removeListener(_onPeersChanged);
    super.dispose();
  }

  void _onPeersChanged() {
    if (mounted) {
      setState(() {
        _peerCount = widget.syncService.peers.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.sync),
          tooltip: 'Sync with nearby devices',
          onPressed: widget.onPressed,
        ),
        if (_peerCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: MatrixTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_peerCount',
                style: const TextStyle(
                  color: MatrixTheme.background,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
