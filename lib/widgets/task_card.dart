import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/matrix_theme.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback? onToggleOngoing;
  final VoidCallback? onResetTimer;
  final bool compact;
  final double scale;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    this.onToggleOngoing,
    this.onResetTimer,
    this.compact = false,
    this.scale = 1.0,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isOngoing != oldWidget.task.isOngoing) {
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (widget.task.isOngoing) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {});
      });
    }
  }

  Color get _cardColor =>
      MatrixTheme.cardColors[widget.task.colorIndex % MatrixTheme.cardColors.length];

  String get _priorityLabel {
    switch (widget.task.priority) {
      case Priority.low:
        return 'LOW';
      case Priority.medium:
        return 'MED';
      case Priority.high:
        return 'HIGH';
    }
  }

  Color get _priorityColor {
    switch (widget.task.priority) {
      case Priority.low:
        return MatrixTheme.dimGreen;
      case Priority.medium:
        return MatrixTheme.primaryGreen;
      case Priority.high:
        return const Color(0xFFFF4136);
    }
  }

  String _formatTime(int totalSeconds) {
    final weeks = totalSeconds ~/ 604800;
    final days = (totalSeconds % 604800) ~/ 86400;
    final h = (totalSeconds % 86400) ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final hms = '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
    if (weeks > 0) return '${weeks}w ${days}d $hms';
    if (days > 0) return '${days}d $hms';
    return hms;
  }

  // Scale helper: returns value scaled by widget.scale, with compact override
  double _s(double normal, [double? compactVal]) {
    if (widget.compact && compactVal != null) return compactVal * widget.scale;
    return normal * widget.scale;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final compact = widget.compact;
    final totalSeconds = task.totalElapsedSeconds;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(_s(12, 10)),
          border: Border.all(
            color: task.isOngoing
                ? MatrixTheme.primaryGreen.withValues(alpha: 0.5)
                : MatrixTheme.primaryGreen.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: task.isOngoing
                  ? MatrixTheme.primaryGreen.withValues(alpha: 0.25)
                  : MatrixTheme.primaryGreen.withValues(alpha: 0.05),
              blurRadius: task.isOngoing ? _s(16, 12) : _s(10, 6),
              spreadRadius: task.isOngoing ? _s(2) : _s(1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(_s(12, 8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        color: MatrixTheme.primaryGreen,
                        fontSize: _s(14, 12),
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: MatrixTheme.primaryGreen,
                        shadows: MatrixTheme.glowShadow(blurRadius: _s(5, 3)),
                      ),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onToggleComplete,
                    child: Container(
                      width: _s(20, 16),
                      height: _s(20, 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MatrixTheme.primaryGreen,
                          width: _s(2, 1.5),
                        ),
                        color: task.isCompleted
                            ? MatrixTheme.primaryGreen
                            : Colors.transparent,
                      ),
                      child: task.isCompleted
                          ? Icon(Icons.check,
                              size: _s(13, 10),
                              color: MatrixTheme.background)
                          : null,
                    ),
                  ),
                  SizedBox(width: _s(8, 4)),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Icon(
                      Icons.close,
                      size: _s(16, 14),
                      color: const Color(0xFFFF4136).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty && !compact) ...[
                SizedBox(height: _s(8)),
                Text(
                  task.description,
                  style: TextStyle(
                    color: MatrixTheme.primaryGreen.withValues(alpha: 0.7),
                    fontSize: _s(11),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!compact) SizedBox(height: _s(8)),
              if (compact) SizedBox(height: _s(4)),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _s(8, 4),
                      vertical: _s(2, 1),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: _priorityColor),
                      borderRadius: BorderRadius.circular(_s(8, 4)),
                    ),
                    child: Text(
                      _priorityLabel,
                      style: TextStyle(
                        color: _priorityColor,
                        fontSize: _s(9, 7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    SizedBox(width: _s(8, 4)),
                    Icon(Icons.schedule,
                        size: _s(12, 10),
                        color:
                            MatrixTheme.primaryGreen.withValues(alpha: 0.6)),
                    SizedBox(width: _s(4)),
                    if (!compact)
                      Text(
                        '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                        style: TextStyle(
                          color:
                              MatrixTheme.primaryGreen.withValues(alpha: 0.6),
                          fontSize: _s(9),
                        ),
                      ),
                  ],
                ],
              ),
              if (widget.onToggleOngoing != null) ...[
                const Spacer(),
                if (totalSeconds > 0 || task.isOngoing) ...[
                  Center(
                    child: Text(
                      _formatTime(totalSeconds),
                      style: TextStyle(
                        color: task.isOngoing
                            ? MatrixTheme.primaryGreen
                            : MatrixTheme.primaryGreen.withValues(alpha: 0.6),
                        fontSize: _s(12, 10),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        shadows: task.isOngoing
                            ? MatrixTheme.glowShadow(blurRadius: _s(6))
                            : null,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: _s(8, 4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onToggleOngoing,
                      child: Container(
                        width: _s(30, 24),
                        height: _s(30, 24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MatrixTheme.primaryGreen,
                            width: _s(2, 1.5),
                          ),
                          color: task.isOngoing
                              ? MatrixTheme.primaryGreen.withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                        child: Icon(
                          task.isOngoing ? Icons.pause : Icons.play_arrow,
                          size: _s(16, 14),
                          color: MatrixTheme.primaryGreen,
                        ),
                      ),
                    ),
                    if (totalSeconds > 0 && widget.onResetTimer != null) ...[
                      SizedBox(width: _s(12, 8)),
                      GestureDetector(
                        onTap: widget.onResetTimer,
                        child: Container(
                          width: _s(22, 20),
                          height: _s(22, 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MatrixTheme.primaryGreen.withValues(alpha: 0.5),
                              width: _s(1.5, 1),
                            ),
                          ),
                          child: Icon(
                            Icons.replay,
                            size: _s(13, 12),
                            color: MatrixTheme.primaryGreen.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
