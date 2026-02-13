import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../theme/matrix_theme.dart';
import '../utils/platform_info.dart' as platform_info;

double _scaled(double normal, double? compactVal, bool compact, double scale) {
  if (compact && compactVal != null) return compactVal * scale;
  return normal * scale;
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback? onToggleOngoing;
  final VoidCallback? onResetTimer;
  final bool compact;
  final bool showDescription;
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
    this.showDescription = true,
    this.scale = 1.0,
    this.tickStream,
  });

  static List<BoxShadow> _shadow({required bool ongoing, required bool compact}) {
    return [
      BoxShadow(
        color: MatrixTheme.primaryGreen.withValues(alpha: ongoing ? 0.25 : 0.05),
        blurRadius: ongoing ? (compact ? 12 : 16) : (compact ? 6 : 10),
        spreadRadius: ongoing ? 2 : 1,
      ),
    ];
  }

  Color get _cardColor =>
      MatrixTheme.cardColors[task.colorIndex % MatrixTheme.cardColors.length];

  double _s(double normal, [double? compactVal]) =>
      _scaled(normal, compactVal, compact, scale);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(_s(14, 10)),
          border: Border.all(
            color: task.isOngoing
                ? MatrixTheme.primaryGreen.withValues(alpha: 0.5)
                : MatrixTheme.primaryGreen.withValues(alpha: 0.15),
          ),
          boxShadow: _shadow(ongoing: task.isOngoing, compact: compact),
        ),
        child: Padding(
          padding: EdgeInsets.all(_s(16, 10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: GoogleFonts.shareTechMono(
                        color: MatrixTheme.primaryGreen,
                        fontSize: _s(18, 14),
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: MatrixTheme.primaryGreen,
                        shadows: MatrixTheme.glowShadow(blurRadius: _s(6, 4)),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggleComplete,
                    child: Container(
                      width: _s(26, 20),
                      height: _s(26, 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MatrixTheme.primaryGreen,
                          width: _s(2.5, 2),
                        ),
                        color: task.isCompleted
                            ? MatrixTheme.primaryGreen
                            : Colors.transparent,
                      ),
                      child: task.isCompleted
                          ? Icon(Icons.check,
                              size: _s(17, 13),
                              color: MatrixTheme.background)
                          : null,
                    ),
                  ),
                  if (!platform_info.isAndroid) ...[
                    SizedBox(width: _s(10, 4)),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        Icons.close,
                        size: _s(20, 14),
                        color: MatrixTheme.errorRed.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
              if (task.description.isNotEmpty && showDescription) ...[
                SizedBox(height: _s(10)),
                Text(
                  task.description,
                  style: GoogleFonts.shareTechMono(
                    color: MatrixTheme.primaryGreen.withValues(alpha: 0.7),
                    fontSize: _s(14),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!compact) SizedBox(height: _s(10)),
              if (compact) SizedBox(height: _s(4)),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _s(10, 6),
                      vertical: _s(3, 2),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: task.priority.color),
                      borderRadius: BorderRadius.circular(_s(10, 6)),
                    ),
                    child: Text(
                      task.priority.label,
                      style: GoogleFonts.shareTechMono(
                        color: task.priority.color,
                        fontSize: _s(11, 9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const Spacer(),
                    Icon(Icons.schedule,
                        size: _s(15, 12),
                        color:
                            MatrixTheme.primaryGreen.withValues(alpha: 0.6)),
                    SizedBox(width: _s(5, 3)),
                    Text(
                      '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                      style: GoogleFonts.shareTechMono(
                        color:
                            MatrixTheme.primaryGreen.withValues(alpha: 0.6),
                        fontSize: _s(12, 10),
                      ),
                    ),
                  ],
                ],
              ),
              if (onToggleOngoing != null)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (task.totalElapsedSeconds > 0 || task.isOngoing)
                        Center(
                          child: _TimerDisplay(
                            task: task,
                            tickStream: tickStream,
                            scale: scale,
                            compact: compact,
                          ),
                        ),
                      SizedBox(height: _s(10, 4)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: onToggleOngoing,
                            child: Container(
                              width: _s(38, 30),
                              height: _s(38, 30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: MatrixTheme.primaryGreen,
                                  width: _s(2.5, 1.5),
                                ),
                                color: task.isOngoing
                                    ? MatrixTheme.primaryGreen.withValues(alpha: 0.2)
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                task.isOngoing ? Icons.pause : Icons.play_arrow,
                                size: _s(20, 17),
                                color: MatrixTheme.primaryGreen,
                              ),
                            ),
                          ),
                          if (task.totalElapsedSeconds > 0 && onResetTimer != null) ...[
                            SizedBox(width: _s(14, 8)),
                            GestureDetector(
                              onTap: onResetTimer,
                              child: Container(
                                width: _s(28, 24),
                                height: _s(28, 24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: MatrixTheme.primaryGreen.withValues(alpha: 0.5),
                                    width: _s(1.5, 1),
                                  ),
                                ),
                                child: Icon(
                                  Icons.replay,
                                  size: _s(16, 14),
                                  color: MatrixTheme.primaryGreen.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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

  double _s(double normal, [double? compactVal]) =>
      _scaled(normal, compactVal, widget.compact, widget.scale);

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
      style: GoogleFonts.shareTechMono(
        color: task.isOngoing
            ? MatrixTheme.primaryGreen
            : MatrixTheme.primaryGreen.withValues(alpha: 0.6),
        fontSize: _s(16, 13),
        fontWeight: FontWeight.bold,
        shadows: task.isOngoing
            ? MatrixTheme.glowShadow(blurRadius: _s(8))
            : null,
      ),
    );
  }
}
