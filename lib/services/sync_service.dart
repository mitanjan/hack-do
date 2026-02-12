import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'task_service.dart';

class Peer {
  final String name;
  final String ip;
  final int port;
  DateTime lastSeen;

  Peer({
    required this.name,
    required this.ip,
    required this.port,
    required this.lastSeen,
  });
}

class SyncResult {
  final int added;
  final int updated;
  final String peerName;
  final bool success;
  final String? error;

  SyncResult({
    required this.added,
    required this.updated,
    required this.peerName,
    this.success = true,
    this.error,
  });

  SyncResult.failed({required this.peerName, required this.error})
      : added = 0,
        updated = 0,
        success = false;
}

class SyncService {
  final TaskService _taskService;
  final String deviceName;

  HttpServer? _httpServer;
  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  Timer? _pruneTimer;

  final Map<String, Peer> _peers = {};
  int _httpPort = 0;

  static const int _udpPort = 41234;
  static const Duration _broadcastInterval = Duration(seconds: 3);
  static const Duration _peerTimeout = Duration(seconds: 15);
  static const String _magicPrefix = 'HACKDO';

  void Function()? onPeersChanged;

  SyncService({required TaskService taskService, required this.deviceName})
      : _taskService = taskService;

  List<Peer> get peers => _peers.values.toList();

  int get httpPort => _httpPort;

  bool get isRunning => _httpServer != null;

  Future<void> start() async {
    await _cacheLocalIps();
    await _startHttpServer();
    await _startDiscovery();
  }

  Future<void> stop() async {
    _broadcastTimer?.cancel();
    _pruneTimer?.cancel();
    _udpSocket?.close();
    await _httpServer?.close();
    _httpServer = null;
    _udpSocket = null;
    _peers.clear();
  }

  // --- HTTP Server ---

  Future<void> _startHttpServer() async {
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _httpPort = _httpServer!.port;

    _httpServer!.listen((request) async {
      try {
        if (request.method == 'GET' && request.uri.path == '/tasks') {
          await _handleGetTasks(request);
        } else if (request.method == 'POST' && request.uri.path == '/sync') {
          await _handleSync(request);
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found');
          await request.response.close();
        }
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Error: $e');
        await request.response.close();
      }
    });
  }

  Future<void> _handleGetTasks(HttpRequest request) async {
    final payload = {
      'tasks': _taskService.getAllAsJson(),
      'deletedIds': _taskService.getDeletedIds().toList(),
      'deviceName': deviceName,
    };
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(payload));
    await request.response.close();
  }

  Future<void> _handleSync(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final remoteTasks = (data['tasks'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final remoteDeletedIds = (data['deletedIds'] as List)
        .map((e) => e as String)
        .toList();

    // Merge remote data into local
    final (added, updated) =
        await _taskService.mergeTasks(remoteTasks, remoteDeletedIds);

    // Respond with our local data so the sender can merge too
    final payload = {
      'tasks': _taskService.getAllAsJson(),
      'deletedIds': _taskService.getDeletedIds().toList(),
      'deviceName': deviceName,
      'added': added,
      'updated': updated,
    };
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(payload));
    await request.response.close();
  }

  // --- UDP Discovery ---

  Future<void> _startDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _udpPort,
        reuseAddress: true,
        reusePort: true,
      );
    } catch (_) {
      // reusePort not supported on some platforms, fall back
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _udpPort,
        reuseAddress: true,
      );
    }
    _udpSocket!.broadcastEnabled = true;

    _udpSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _udpSocket!.receive();
        if (datagram != null) {
          _handleDiscoveryPacket(datagram);
        }
      }
    });

    // Broadcast presence periodically
    _broadcastTimer = Timer.periodic(_broadcastInterval, (_) => _broadcast());
    _broadcast(); // Immediate first broadcast

    // Prune stale peers
    _pruneTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pruneStalePeers(),
    );
  }

  void _broadcast() {
    if (_udpSocket == null) return;
    final message = '$_magicPrefix:$_httpPort:$deviceName';
    final data = utf8.encode(message);
    _udpSocket!.send(
      data,
      InternetAddress('255.255.255.255'),
      _udpPort,
    );
  }

  void _handleDiscoveryPacket(Datagram datagram) {
    final message = utf8.decode(datagram.data);
    if (!message.startsWith('$_magicPrefix:')) return;

    final parts = message.split(':');
    if (parts.length < 3) return;

    final port = int.tryParse(parts[1]);
    if (port == null) return;

    final name = parts.sublist(2).join(':');
    final ip = datagram.address.address;

    // Ignore our own broadcasts
    if (port == _httpPort && _isOwnAddress(ip)) return;

    final key = '$ip:$port';
    final isNew = !_peers.containsKey(key);
    _peers[key] = Peer(
      name: name,
      ip: ip,
      port: port,
      lastSeen: DateTime.now(),
    );

    if (isNew) {
      onPeersChanged?.call();
    }
  }

  bool _isOwnAddress(String ip) {
    if (ip == '127.0.0.1') return true;
    return _localIps.contains(ip);
  }

  final Set<String> _localIps = {};

  Future<void> _cacheLocalIps() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: true,
        type: InternetAddressType.IPv4,
      );
      _localIps.clear();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          _localIps.add(addr.address);
        }
      }
    } catch (_) {}
  }

  void _pruneStalePeers() {
    final now = DateTime.now();
    final stale = _peers.entries
        .where((e) => now.difference(e.value.lastSeen) > _peerTimeout)
        .map((e) => e.key)
        .toList();
    if (stale.isNotEmpty) {
      for (final key in stale) {
        _peers.remove(key);
      }
      onPeersChanged?.call();
    }
  }

  // --- Sync Operations ---

  Future<SyncResult> syncWithPeer(Peer peer) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      // POST our tasks to the peer
      final request = await client.post(peer.ip, peer.port, '/sync');
      request.headers.contentType = ContentType.json;

      final payload = {
        'tasks': _taskService.getAllAsJson(),
        'deletedIds': _taskService.getDeletedIds().toList(),
      };
      request.write(jsonEncode(payload));

      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();

      if (response.statusCode != HttpStatus.ok) {
        return SyncResult.failed(
          peerName: peer.name,
          error: 'HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final remoteTasks = (data['tasks'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final remoteDeletedIds = (data['deletedIds'] as List)
          .map((e) => e as String)
          .toList();

      // Merge the response into our local store
      final (added, updated) =
          await _taskService.mergeTasks(remoteTasks, remoteDeletedIds);

      client.close();

      return SyncResult(
        added: added,
        updated: updated,
        peerName: peer.name,
      );
    } catch (e) {
      return SyncResult.failed(peerName: peer.name, error: e.toString());
    }
  }

  Future<List<SyncResult>> syncWithAll() async {
    final results = <SyncResult>[];
    for (final peer in _peers.values.toList()) {
      results.add(await syncWithPeer(peer));
    }
    return results;
  }
}
