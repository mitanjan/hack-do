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
  int _peerCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    widget.syncService.onPeersChanged = _onPeersChanged;
  }

  @override
  void dispose() {
    widget.syncService.onPeersChanged = null;
    super.dispose();
  }

  void _onPeersChanged() {
    if (mounted) {
      setState(() {
        _peerCount = widget.syncService.peers.length;
      });
    }
  }

  void _openSyncScreen() {
    // Detach our listener while sync screen is active
    widget.syncService.onPeersChanged = null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SyncScreen(
          syncService: widget.syncService,
          onSyncComplete: _loadTasks,
        ),
      ),
    ).then((_) {
      // Re-attach our listener
      widget.syncService.onPeersChanged = _onPeersChanged;
      _onPeersChanged();
      _loadTasks();
    });
  }

  void _loadTasks() {
    setState(() {
      _tasks = widget.taskService.getAll()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case TaskFilter.ongoing:
        return _tasks.where((t) => t.isOngoing).toList();
      case TaskFilter.done:
        return _tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        return _tasks;
    }
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
                style: TextStyle(color: Color(0xFFFF4136))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.taskService.delete(task.id);
      _loadTasks();
    }
  }

  void _toggleComplete(Task task) async {
    await widget.taskService.toggleComplete(task.id);
    _loadTasks();
  }

  void _toggleOngoing(Task task) {
    widget.taskService.toggleOngoing(task.id);
    _loadTasks();
  }

  void _resetTimer(Task task) {
    widget.taskService.resetTimer(task.id);
    _loadTasks();
  }

  void _cycleFilter() {
    setState(() {
      switch (_filter) {
        case TaskFilter.all:
          _filter = TaskFilter.ongoing;
        case TaskFilter.ongoing:
          _filter = TaskFilter.done;
        case TaskFilter.done:
          _filter = TaskFilter.all;
      }
    });
  }

  String get _filterLabel {
    switch (_filter) {
      case TaskFilter.all:
        return 'ALL';
      case TaskFilter.ongoing:
        return 'ONGOING';
      case TaskFilter.done:
        return 'DONE';
    }
  }

  IconData get _filterIcon {
    switch (_filter) {
      case TaskFilter.all:
        return Icons.all_inclusive;
      case TaskFilter.ongoing:
        return Icons.play_circle_outline;
      case TaskFilter.done:
        return Icons.check_circle_outline;
    }
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
                Icon(_filterIcon, size: 16, color: MatrixTheme.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  _filterLabel,
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync with nearby devices',
                onPressed: _openSyncScreen,
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
              onTap: (t) => _showTaskDialog(task: t),
              onToggleComplete: _toggleComplete,
              onDelete: _confirmDelete,
              onToggleOngoing: _toggleOngoing,
              onResetTimer: _resetTimer,
            )
          : TilingLayout(
              tasks: filtered,
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
