import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/platform_info.dart' as platform_info;
import 'task_card.dart';

class DiagonalLayout extends StatefulWidget {
  final List<Task> tasks;
  final Stream<void>? tickStream;
  final void Function(Task) onTap;
  final void Function(Task) onToggleComplete;
  final void Function(Task) onDelete;
  final void Function(Task)? onToggleOngoing;
  final void Function(Task)? onResetTimer;

  const DiagonalLayout({
    super.key,
    required this.tasks,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    this.tickStream,
    this.onToggleOngoing,
    this.onResetTimer,
  });

  @override
  State<DiagonalLayout> createState() => _DiagonalLayoutState();
}

class _DiagonalLayoutState extends State<DiagonalLayout>
    with SingleTickerProviderStateMixin {
  // _position = current front layer (float).
  // activeLayer = _position.floor(), frac = _position - activeLayer.
  double _position = 0.0;
  late AnimationController _animController;
  late Animation<double> _animation;
  String? _revealedTaskId;

  // Reference dimensions (tuned for ~1500×800 window)
  static const double _refWidth = 1500.0;
  static const double _refHeight = 800.0;
  static const double _refCardWidth = 240.0;
  static const double _refCardHeight = 300.0;
  static const double _refPeekAmount = 60.0;
  static const double _refPeekUp = 50.0;
  static const double _refGapX = 115.0;
  static const double _refGapY = 145.0;

  static const double _swipeThreshold = 60.0;
  double _dragAccumulator = 0.0;

  // Direction signs: Q0(-1,-1), Q1(+1,-1), Q2(-1,+1), Q3(+1,+1)
  static const List<int> _dxSign = [-1, 1, -1, 1];
  static const List<int> _dySign = [-1, -1, 1, 1];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _position = _animation.value);
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onScroll(double delta) {
    final count = widget.tasks.length;
    if (count <= 1) return;
    final numLayers = (count / 4).ceil();
    if (numLayers <= 1) return;

    final target = (delta > 0)
        ? (_position + 1).clamp(0.0, numLayers - 1.0)
        : (_position - 1).clamp(0.0, numLayers - 1.0);

    final snapped = target.roundToDouble();

    _animation = Tween<double>(begin: _position, end: snapped).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _position = _animation.value);
      });
    _animController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return const Center(
        child: Text(
          '> NO TASKS. THE MATRIX IS EMPTY._',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final count = widget.tasks.length;

    final activeLayer = _position.floor().clamp(0, ((count / 4).ceil() - 1).clamp(0, count));
    final frac = _position - activeLayer;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use mobile-tuned reference on narrow screens
        final isMobile = constraints.maxWidth < 600;
        final refW = isMobile ? 480.0 : _refWidth;
        final refH = isMobile ? 900.0 : _refHeight;
        final scale = min(
          constraints.maxWidth / refW,
          constraints.maxHeight / refH,
        ).clamp(isMobile ? 0.6 : 0.4, isMobile ? 1.0 : 0.85);

        // Mobile uses smaller base card to fit the screen
        final baseCardW = isMobile ? 180.0 : _refCardWidth;
        final baseCardH = isMobile ? 230.0 : _refCardHeight;
        final basePeekH = isMobile ? 55.0 : _refPeekAmount;
        final basePeekV = isMobile ? 45.0 : _refPeekUp;
        final baseGapX = isMobile ? 95.0 : _refGapX;
        final baseGapY = isMobile ? 120.0 : _refGapY;

        final cardW = baseCardW * scale;
        final cardH = baseCardH * scale;
        final peekH = basePeekH * scale;
        final peekV = basePeekV * scale;
        final gapX = max(cardW / 2 + 10, baseGapX * scale);
        final gapY = max(cardH / 2 + 10, baseGapY * scale);

        final centerX = (constraints.maxWidth - cardW) / 2;
        final centerY = (constraints.maxHeight - cardH) / 2;

        final dims = _Dims(
          cardW: cardW, cardH: cardH,
          peekH: peekH, peekV: peekV,
          gapX: gapX, gapY: gapY,
          scale: scale,
        );

        return GestureDetector(
          onTap: () {
            if (_revealedTaskId != null) {
              setState(() => _revealedTaskId = null);
            }
          },
          onHorizontalDragStart: (_) {
            _dragAccumulator = 0.0;
          },
          onHorizontalDragUpdate: (details) {
            _dragAccumulator += details.delta.dx;
            if (_dragAccumulator < -_swipeThreshold) {
              _dragAccumulator = 0.0;
              _onScroll(-1);
            } else if (_dragAccumulator > _swipeThreshold) {
              _dragAccumulator = 0.0;
              _onScroll(1);
            }
          },
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _onScroll(event.scrollDelta.dy);
              }
            },
            child: Container(
              color: Colors.transparent,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: _buildCards(widget.tasks, count, activeLayer, frac,
                    centerX, centerY, dims),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCards(
    List<Task> tasks,
    int count,
    int activeLayer,
    double frac,
    double centerX,
    double centerY,
    _Dims d,
  ) {
    // Special case: 1 card → show at center
    if (count == 1) {
      final task = tasks[0];
      return [
        Positioned(
          key: ValueKey(task.id),
          left: centerX,
          top: centerY,
          width: d.cardW,
          height: d.cardH,
          child: _taskCardWidget(task, d.scale),
        ),
      ];
    }

    final widgets = <_CardEntry>[];
    final numLayers = (count / 4).ceil();

    // Iterate in reverse order (newest first) without allocating a new list
    for (int ri = 0; ri < count; ri++) {
      final i = count - 1 - ri;
      final task = tasks[i];
      final quadrant = ri % 4;
      final layer = ri ~/ 4;
      final isLowerQuadrant = quadrant >= 2;

      double left;
      double top;
      int zOrder;

      if (!isLowerQuadrant) {
        // ── UPPER QUADRANTS: peel from front (closest to center) ──
        final relativeLayer = layer - activeLayer;
        if (relativeLayer < 0) continue;

        if (relativeLayer == 0) {
          final qLeft = _quadrantLeft(quadrant, 0, centerX, d);
          final qTop = _quadrantTop(quadrant, 0, centerY, d);
          left = qLeft + (centerX - qLeft) * frac;
          top = qTop + (centerY - qTop) * frac;
          zOrder = numLayers * 4 + (4 - quadrant);
        } else {
          final curLeft = _quadrantLeft(quadrant, relativeLayer, centerX, d);
          final curTop = _quadrantTop(quadrant, relativeLayer, centerY, d);
          final tgtLeft = _quadrantLeft(quadrant, relativeLayer - 1, centerX, d);
          final tgtTop = _quadrantTop(quadrant, relativeLayer - 1, centerY, d);
          left = curLeft + (tgtLeft - curLeft) * frac;
          top = curTop + (tgtTop - curTop) * frac;
          zOrder = (numLayers - relativeLayer) * 4 + (4 - quadrant);
        }
      } else {
        // ── LOWER QUADRANTS: peel from top (deepest visible card) ──
        final maxLayerQ = (count - 1 - quadrant) ~/ 4;
        final topVisibleLayer = maxLayerQ - activeLayer;

        if (topVisibleLayer < 0 || layer > topVisibleLayer) continue;

        final posDepth = layer;

        if (layer == topVisibleLayer) {
          final qLeft = _quadrantLeft(quadrant, posDepth, centerX, d);
          final qTop = _quadrantTop(quadrant, posDepth, centerY, d);
          left = qLeft + (centerX - qLeft) * frac;
          top = qTop + (centerY - qTop) * frac;
          zOrder = numLayers * 4 + (4 - quadrant);
        } else {
          left = _quadrantLeft(quadrant, posDepth, centerX, d);
          top = _quadrantTop(quadrant, posDepth, centerY, d);
          zOrder = posDepth * 4 + (4 - quadrant);
        }
      }

      final isRevealed = task.id == _revealedTaskId;

      widgets.add(_CardEntry(
        zOrder: isRevealed ? numLayers * 4 + 10 : zOrder,
        widget: Positioned(
          key: ValueKey(task.id),
          left: isRevealed ? centerX : left,
          top: isRevealed ? centerY : top,
          width: d.cardW,
          height: d.cardH,
          child: _taskCardWidget(task, d.scale),
        ),
      ));
    }

    widgets.sort((a, b) => a.zOrder.compareTo(b.zOrder));
    return widgets.map((e) => e.widget).toList();
  }

  double _quadrantLeft(int quadrant, int depth, double centerX, _Dims d) {
    return centerX + _dxSign[quadrant] * (d.gapX + depth * d.peekH);
  }

  double _quadrantTop(int quadrant, int depth, double centerY, _Dims d) {
    return centerY + _dySign[quadrant] * (d.gapY + depth * d.peekV);
  }

  void _toggleReveal(Task task) {
    setState(() {
      _revealedTaskId = _revealedTaskId == task.id ? null : task.id;
    });
  }

  Widget _taskCardWidget(Task task, double scale) {
    return GestureDetector(
      onSecondaryTap: () => _toggleReveal(task),
      onDoubleTap: () => _toggleReveal(task),
      child: TaskCard(
        task: task,
        scale: scale,
        compact: platform_info.isAndroid,
        tickStream: widget.tickStream,
        onTap: () {
          setState(() => _revealedTaskId = task.id);
          widget.onTap(task);
        },
        onToggleComplete: () => widget.onToggleComplete(task),
        onDelete: () => widget.onDelete(task),
        onToggleOngoing: widget.onToggleOngoing != null
            ? () => widget.onToggleOngoing!(task)
            : null,
        onResetTimer: widget.onResetTimer != null
            ? () => widget.onResetTimer!(task)
            : null,
      ),
    );
  }
}

class _Dims {
  final double cardW, cardH, peekH, peekV, gapX, gapY, scale;
  const _Dims({
    required this.cardW, required this.cardH,
    required this.peekH, required this.peekV,
    required this.gapX, required this.gapY,
    required this.scale,
  });
}

class _CardEntry {
  final int zOrder;
  final Widget widget;
  const _CardEntry({required this.zOrder, required this.widget});
}
