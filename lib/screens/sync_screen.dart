import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../theme/matrix_theme.dart';

class SyncScreen extends StatefulWidget {
  final SyncService syncService;
  final VoidCallback onSyncComplete;

  const SyncScreen({
    super.key,
    required this.syncService,
    required this.onSyncComplete,
  });

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> with TickerProviderStateMixin {
  List<Peer> _peers = [];
  final Map<String, _PeerSyncState> _peerStates = {};
  bool _isSyncingAll = false;
  late AnimationController _radarController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _peers = widget.syncService.peers;
    widget.syncService.onPeersChanged = _onPeersChanged;
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    widget.syncService.onPeersChanged = null;
    super.dispose();
  }

  void _onPeersChanged() {
    if (mounted) {
      setState(() {
        _peers = widget.syncService.peers;
      });
    }
  }

  Future<void> _syncWithPeer(Peer peer) async {
    final key = '${peer.ip}:${peer.port}';
    setState(() {
      _peerStates[key] = _PeerSyncState.syncing;
    });

    final result = await widget.syncService.syncWithPeer(peer);

    if (mounted) {
      setState(() {
        _peerStates[key] =
            result.success ? _PeerSyncState.done : _PeerSyncState.error;
      });

      if (result.success) {
        widget.onSyncComplete();
        _showResultSnackBar(result);
      } else {
        _showErrorSnackBar(result);
      }

      // Reset state after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _peerStates[key] = _PeerSyncState.idle;
          });
        }
      });
    }
  }

  Future<void> _syncWithAll() async {
    if (_peers.isEmpty || _isSyncingAll) return;

    setState(() => _isSyncingAll = true);

    final results = await widget.syncService.syncWithAll();
    widget.onSyncComplete();

    if (mounted) {
      setState(() => _isSyncingAll = false);

      final successes = results.where((r) => r.success).toList();
      final totalAdded = successes.fold<int>(0, (s, r) => s + r.added);
      final totalUpdated = successes.fold<int>(0, (s, r) => s + r.updated);
      final failures = results.where((r) => !r.success).length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MatrixTheme.surfaceColor,
          content: Text(
            failures == 0
                ? 'SYNC COMPLETE: +$totalAdded new, ~$totalUpdated updated'
                : 'SYNC: +$totalAdded new, ~$totalUpdated updated, $failures failed',
            style: TextStyle(
              color: failures == 0
                  ? MatrixTheme.primaryGreen
                  : const Color(0xFFFF4136),
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }
  }

  void _showResultSnackBar(SyncResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MatrixTheme.surfaceColor,
        duration: const Duration(seconds: 2),
        content: Text(
          'SYNCED ${result.peerName}: +${result.added} new, ~${result.updated} updated',
          style: const TextStyle(
            color: MatrixTheme.primaryGreen,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(SyncResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MatrixTheme.surfaceColor,
        duration: const Duration(seconds: 3),
        content: Text(
          'SYNC FAILED ${result.peerName}: ${result.error}',
          style: const TextStyle(
            color: Color(0xFFFF4136),
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MatrixTheme.background,
      appBar: AppBar(
        title: Text(
          'NEARBY DEVICES',
          style: TextStyle(
            fontSize: 18,
            shadows: MatrixTheme.glowShadow(blurRadius: 10),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_peers.isNotEmpty)
            TextButton.icon(
              onPressed: _isSyncingAll ? null : _syncWithAll,
              icon: _isSyncingAll
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MatrixTheme.primaryGreen.withValues(alpha: 0.5),
                      ),
                    )
                  : const Icon(Icons.sync, size: 16),
              label: const Text('SYNC ALL', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Radar / scanning animation area
          Expanded(
            flex: 2,
            child: _buildRadarArea(),
          ),
          // Device list
          Expanded(
            flex: 3,
            child: _peers.isEmpty ? _buildEmptyState() : _buildPeerGrid(),
          ),
          // Footer info
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildRadarArea() {
    return Center(
      child: AnimatedBuilder(
        animation: _radarController,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(200, 200),
            painter: _RadarPainter(
              sweep: _radarController.value * 2 * pi,
              peerCount: _peers.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final opacity = 0.4 + _pulseController.value * 0.6;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.radar,
                size: 48,
                color: MatrixTheme.primaryGreen.withValues(alpha: opacity),
              ),
              const SizedBox(height: 16),
              Text(
                'SCANNING LOCAL NETWORK...',
                style: TextStyle(
                  color: MatrixTheme.dimGreen.withValues(alpha: opacity),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for other hack-do instances',
                style: TextStyle(
                  color: MatrixTheme.dimGreen.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _peers.length,
      itemBuilder: (context, index) {
        final peer = _peers[index];
        return _buildPeerCard(peer);
      },
    );
  }

  Widget _buildPeerCard(Peer peer) {
    final key = '${peer.ip}:${peer.port}';
    final state = _peerStates[key] ?? _PeerSyncState.idle;
    final isSyncing = state == _PeerSyncState.syncing;
    final isDone = state == _PeerSyncState.done;
    final isError = state == _PeerSyncState.error;

    final borderColor = isDone
        ? MatrixTheme.primaryGreen
        : isError
            ? const Color(0xFFFF4136)
            : isSyncing
                ? MatrixTheme.primaryGreen.withValues(alpha: 0.6)
                : MatrixTheme.primaryGreen.withValues(alpha: 0.2);

    final glowColor = isDone
        ? MatrixTheme.primaryGreen.withValues(alpha: 0.3)
        : isError
            ? const Color(0xFFFF4136).withValues(alpha: 0.2)
            : Colors.transparent;

    return GestureDetector(
      onTap: isSyncing ? null : () => _syncWithPeer(peer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: MatrixTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isDone ? 1.5 : 1),
          boxShadow: [
            if (glowColor != Colors.transparent)
              BoxShadow(color: glowColor, blurRadius: 12, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status icon
            _buildPeerIcon(state),
            const SizedBox(height: 12),
            // Device name
            Text(
              peer.name.toUpperCase(),
              style: TextStyle(
                color: MatrixTheme.primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                shadows: isDone
                    ? MatrixTheme.glowShadow(blurRadius: 6)
                    : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // IP address
            Text(
              peer.ip,
              style: TextStyle(
                color: MatrixTheme.dimGreen.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            // Tap to sync hint
            if (!isSyncing && !isDone && !isError)
              Text(
                'TAP TO SYNC',
                style: TextStyle(
                  color: MatrixTheme.dimGreen.withValues(alpha: 0.5),
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerIcon(_PeerSyncState state) {
    switch (state) {
      case _PeerSyncState.syncing:
        return SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: MatrixTheme.primaryGreen.withValues(alpha: 0.7),
          ),
        );
      case _PeerSyncState.done:
        return Icon(
          Icons.check_circle,
          size: 36,
          color: MatrixTheme.primaryGreen,
          shadows: MatrixTheme.glowShadow(blurRadius: 10),
        );
      case _PeerSyncState.error:
        return const Icon(
          Icons.error_outline,
          size: 36,
          color: Color(0xFFFF4136),
        );
      case _PeerSyncState.idle:
        return Icon(
          Icons.devices,
          size: 36,
          color: MatrixTheme.primaryGreen.withValues(alpha: 0.7),
        );
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi,
            size: 14,
            color: MatrixTheme.dimGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            'PORT ${widget.syncService.httpPort}  ·  ${_peers.length} DEVICE${_peers.length == 1 ? '' : 'S'} FOUND',
            style: TextStyle(
              color: MatrixTheme.dimGreen.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PeerSyncState { idle, syncing, done, error }

class _RadarPainter extends CustomPainter {
  final double sweep;
  final int peerCount;

  _RadarPainter({required this.sweep, required this.peerCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Concentric rings
    for (int i = 1; i <= 3; i++) {
      final r = maxRadius * i / 3;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = MatrixTheme.primaryGreen.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Cross lines
    final crossPaint = Paint()
      ..color = MatrixTheme.primaryGreen.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crossPaint,
    );

    // Sweep arc
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweep - 0.8,
        endAngle: sweep,
        colors: [
          Colors.transparent,
          MatrixTheme.primaryGreen.withValues(alpha: 0.15),
        ],
        stops: const [0.0, 1.0],
        transform: GradientRotation(sweep - 0.8),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Sweep line
    final lineEnd = Offset(
      center.dx + maxRadius * cos(sweep),
      center.dy + maxRadius * sin(sweep),
    );
    canvas.drawLine(
      center,
      lineEnd,
      Paint()
        ..color = MatrixTheme.primaryGreen.withValues(alpha: 0.3)
        ..strokeWidth = 1.5,
    );

    // Center dot
    canvas.drawCircle(
      center,
      4,
      Paint()..color = MatrixTheme.primaryGreen.withValues(alpha: 0.8),
    );

    // Peer dots placed around the radar
    if (peerCount > 0) {
      final rng = Random(42); // fixed seed for stable positions
      for (int i = 0; i < peerCount; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final dist = maxRadius * (0.3 + rng.nextDouble() * 0.5);
        final pos = Offset(
          center.dx + dist * cos(angle),
          center.dy + dist * sin(angle),
        );

        // Glow
        canvas.drawCircle(
          pos,
          8,
          Paint()
            ..color = MatrixTheme.primaryGreen.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        // Dot
        canvas.drawCircle(
          pos,
          3,
          Paint()..color = MatrixTheme.primaryGreen.withValues(alpha: 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
