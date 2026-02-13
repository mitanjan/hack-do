import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/matrix_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback? onToggleOngoing;
  final VoidCallback? onResetTimer;
  final bool compact;
  final double scale;
  final Stream<void>? tickStream;

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
    this.tickStream,
  });

  static final _ongoingShadow = [
    BoxShadow(
      color: MatrixTheme.primaryGreen.withValues(alpha: 0.25),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  static final _idleShadow = [
    BoxShadow(
      color: MatrixTheme.primaryGreen.withValues(alpha: 0.05),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  static final _ongoingShadowCompact = [
    BoxShadow(
      color: MatrixTheme.primaryGreen.withValues(alpha: 0.25),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  static final _idleShadowCompact = [
    BoxShadow(
      color: MatrixTheme.primaryGreen.withValues(alpha: 0.05),
      blurRadius: 6,
      spreadRadius: 1,
    ),
  ];

  Color get _cardColor =>
      MatrixTheme.cardColors[task.colorIndex % MatrixTheme.cardColors.length];

  String get _priorityLabel {
    switch (task.priority) {
      case Priority.low:
        return 'LOW';
      case Priority.medium:
        return 'MED';
      case Priority.high:
        return 'HIGH';
    }
  }

  Color get _priorityColor {
    switch (task.priority) {
      case Priority.low:
        return MatrixTheme.dimGreen;
      case Priority.medium:
        return MatrixTheme.primaryGreen;
      case Priority.high:
        return const Color(0xFFFF4136);
    }
  }

  // Scale helper: returns value scaled by scale, with compact override
  double _s(double normal, [double? compactVal]) {
    if (compact && compactVal != null) return compactVal * scale;
    return normal * scale;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(_s(12, 10)),
          border: Border.all(
            color: task.isOngoing
                ? MatrixTheme.primaryGreen.withValues(alpha: 0.5)
                : MatrixTheme.primaryGreen.withValues(alpha: 0.15),
          ),
          boxShadow: task.isOngoing
              ? (compact ? _ongoingShadowCompact : _ongoingShadow)
              : (compact ? _idleShadowCompact : _idleShadow),
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
                    onTap: onToggleComplete,
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
                    onTap: onDelete,
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
              if (onToggleOngoing != null) ...[
                const Spacer(),
                if (task.totalElapsedSeconds > 0 || task.isOngoing) ...[
                  Center(
                    child: _TimerDisplay(
                      task: task,
                      tickStream: tickStream,
                      scale: scale,
                      compact: compact,
                    ),
                  ),
                ],
                SizedBox(height: _s(8, 4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onToggleOngoing,
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
                    if (task.totalElapsedSeconds > 0 && onResetTimer != null) ...[
                      SizedBox(width: _s(12, 8)),
                      GestureDetector(
                        onTap: onResetTimer,
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

/// Tiny StatefulWidget that only rebuilds the timer text when the tick stream fires.
class _TimerDisplay extends StatefulWidget {
  final Task task;
  final Stream<void>? tickStream;
  final double scale;
  final bool compact;

  const _TimerDisplay({
    required this.task,
    required this.tickStream,
    required this.scale,
    required this.compact,
  });

  @override
  State<_TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<_TimerDisplay> {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant _TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tickStream != oldWidget.tickStream ||
        widget.task.isOngoing != oldWidget.task.isOngoing) {
      _sub?.cancel();
      _sub = null;
      _subscribe();
    }
  }

  void _subscribe() {
    if (widget.task.isOngoing && widget.tickStream != null) {
      _sub = widget.tickStream!.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  double _s(double normal, [double? compactVal]) {
    if (widget.compact && compactVal != null) return compactVal * widget.scale;
    return normal * widget.scale;
  }

  static String _formatTime(int totalSeconds) {
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

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final totalSeconds = task.totalElapsedSeconds;
    return Text(
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
    );
  }
}
