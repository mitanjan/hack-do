import 'dart:math';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/platform_info.dart' as platform_info;
import 'task_card.dart';

class TilingLayout extends StatelessWidget {
  final List<Task> tasks;
  final Stream<void>? tickStream;
  final void Function(Task) onTap;
  final void Function(Task) onToggleComplete;
  final void Function(Task) onDelete;
  final void Function(Task)? onToggleOngoing;
  final void Function(Task)? onResetTimer;

  static const double _gap = 6.0;
  static const double _minCardWidth = 200.0;
  static const double _minCardHeight = 240.0;
  static const double _maxCardWidth = 200.0;
  static const double _maxCardHeight = 240.0;

  const TilingLayout({
    super.key,
    required this.tasks,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    this.tickStream,
    this.onToggleOngoing,
    this.onResetTimer,
  });

  Widget _buildCard(Task task, bool compact, double cellH, double scale) {
    return TaskCard(
      task: task,
      compact: compact,
      scale: scale,
      showDescription: cellH >= 150,
      tickStream: tickStream,
      onTap: () => onTap(task),
      onToggleComplete: () => onToggleComplete(task),
      onDelete: () => onDelete(task),
      onToggleOngoing: onToggleOngoing != null
          ? () => onToggleOngoing!(task)
          : null,
      onResetTimer: onResetTimer != null
          ? () => onResetTimer!(task)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          '> NO TASKS. THE MATRIX IS EMPTY._',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final count = tasks.length;

        // On Android, size for 2 cols × 3 rows (6 cards per screen)
        final minW = platform_info.isAndroid
            ? (w - 3 * _gap) / 2
            : _minCardWidth;
        final minH = platform_info.isAndroid
            ? (h - 4 * _gap) / 3
            : _minCardHeight;

        final cols = max(1, ((w - _gap) / (minW + _gap)).floor());
        final cellW = min((w - (cols + 1) * _gap) / cols, _maxCardWidth);
        final cellH = min(max(minH, cellW), _maxCardHeight);
        final compact = cellW < 200;
        final tileScale = platform_info.isAndroid
            ? 1.0
            : (cellH / 300).clamp(0.9, 1.25);

        return GridView.builder(
          padding: const EdgeInsets.all(_gap),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: _gap,
            mainAxisSpacing: _gap,
            childAspectRatio: cellW / cellH,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            return _buildCard(tasks[index], compact, cellH, tileScale);
          },
        );
      },
    );
  }
}
