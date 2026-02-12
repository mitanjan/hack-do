import 'dart:math';
import 'package:flutter/material.dart';
import '../models/task.dart';
import 'task_card.dart';

class TilingLayout extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onTap;
  final void Function(Task) onToggleComplete;
  final void Function(Task) onDelete;
  final void Function(Task)? onToggleOngoing;
  final void Function(Task)? onResetTimer;

  static const double _gap = 6.0;

  const TilingLayout({
    super.key,
    required this.tasks,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    this.onToggleOngoing,
    this.onResetTimer,
  });

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

        // Pick cols that makes cells closest to square while filling the screen.
        // For each candidate cols, rows = ceil(count/cols).
        // Cell aspect ratio = (w/cols) / (h/rows). Closest to 1.0 wins.
        int bestCols = 1;
        double bestRatioDiff = double.infinity;
        for (int cols = 1; cols <= count; cols++) {
          final rows = (count / cols).ceil();
          final cellW = (w - (cols + 1) * _gap) / cols;
          final cellH = (h - (rows + 1) * _gap) / rows;
          if (cellW <= 0 || cellH <= 0) continue;
          final diff = (cellW / cellH - 1.0).abs();
          if (diff < bestRatioDiff) {
            bestRatioDiff = diff;
            bestCols = cols;
          }
        }

        final bestRows = (count / bestCols).ceil();
        final cellW = (w - (bestCols + 1) * _gap) / bestCols;
        final cellH = (h - (bestRows + 1) * _gap) / bestRows;

        return Padding(
          padding: const EdgeInsets.all(_gap),
          child: Column(
            children: List.generate(bestRows, (row) {
              final startIdx = row * bestCols;
              final endIdx = min(startIdx + bestCols, count);
              final itemsInRow = endIdx - startIdx;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: row < bestRows - 1 ? _gap : 0),
                  child: Row(
                    children: List.generate(itemsInRow, (col) {
                      final task = tasks[startIdx + col];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: col < itemsInRow - 1 ? _gap : 0),
                          child: TaskCard(
                            task: task,
                            compact: cellW < 200 || cellH < 150,
                            onTap: () => onTap(task),
                            onToggleComplete: () => onToggleComplete(task),
                            onDelete: () => onDelete(task),
                            onToggleOngoing: onToggleOngoing != null
                                ? () => onToggleOngoing!(task)
                                : null,
                            onResetTimer: onResetTimer != null
                                ? () => onResetTimer!(task)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
