import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

/// A move message sent between devices
class NetworkMove {
  final int tileId;
  final int sideA;
  final int sideB;
  final String side; // 'left' | 'right'
  final String type; // 'place' | 'draw' | 'pass'

  const NetworkMove({
    required this.tileId,
    required this.sideA,
    required this.sideB,
    required this.side,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'tile': [sideA, sideB],
        'tileId': tileId,
        'side': side,
        'type': type,
      };

  factory NetworkMove.fromJson(Map<String, dynamic> j) => NetworkMove(
        tileId: j['tileId'] ?? -1,
        sideA: (j['tile'] as List)[0],
        sideB: (j['tile'] as List)[1],
        side: j['side'] ?? 'right',
        type: j['type'] ?? 'place',
      );

  factory NetworkMove.place(int id, int a, int b, String side) =>
      NetworkMove(tileId: id, sideA: a, sideB: b, side: side, type: 'place');

  factory NetworkMove.draw() =>
      NetworkMove(tileId: -1, sideA: 0, sideB: 0, side: 'right', type: 'draw');

  factory NetworkMove.pass() =>
      NetworkMove(tileId: -1, sideA: 0, sideB: 0, side: 'right', type: 'pass');
}

/// Wraps the nearby_connections plugin for domino P2P multiplayer.
///
/// Both devices:
///  1. Call [startAdvertising] or [startDiscovery]
///  2. On connection → call [acceptConnection]
///  3. Exchange moves via [sendMove]
///  4. Receive moves via [onMoveReceived]
class NearbyService extends ChangeNotifier {
  static const _serviceId = 'com.domino.lwa3rin';
  static const _strategy = Strategy.P2P_POINT_TO_POINT;

  final Nearby _nearby = Nearby();

  String? _connectedEndpointId;
  String? _connectedEndpointName;

  bool _isAdvertising = false;
  bool _isDiscovering = false;
  bool get isConnected => _connectedEndpointId != null;
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;
  String? get connectedEndpointName => _connectedEndpointName;

  final List<DiscoveredEndpoint> discoveredEndpoints = [];

  /// Called when a move arrives from the remote peer
  void Function(NetworkMove move)? onMoveReceived;

  /// Called when a peer connects or disconnects
  void Function(bool connected, String endpointName)? onConnectionChanged;

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  /// Host: advertise so others can find you
  Future<void> startAdvertising(String deviceName) async {
    try {
      await _nearby.startAdvertising(
        deviceName,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      _isAdvertising = true;
      notifyListeners();
    } catch (e) {
      debugPrint('startAdvertising error: $e');
    }
  }

  /// Guest: scan for hosts
  Future<void> startDiscovery() async {
    try {
      discoveredEndpoints.clear();
      await _nearby.startDiscovery(
        'Guest',
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          discoveredEndpoints.add(DiscoveredEndpoint(id: id, name: name));
          notifyListeners();
        },
        onEndpointLost: (id) {
          discoveredEndpoints.removeWhere((e) => e.id == id);
          notifyListeners();
        },
        serviceId: _serviceId,
      );
      _isDiscovering = true;
      notifyListeners();
    } catch (e) {
      debugPrint('startDiscovery error: $e');
    }
  }

  Future<void> requestConnection(String endpointId, String deviceName) async {
    await _nearby.requestConnection(
      deviceName,
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (id, update) {},
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpointId = id;
      _connectedEndpointName = discoveredEndpoints
          .firstWhere((e) => e.id == id, orElse: () => DiscoveredEndpoint(id: id, name: 'Player 2'))
          .name;
      onConnectionChanged?.call(true, _connectedEndpointName!);
      notifyListeners();
    }
  }

  void _onDisconnected(String id) {
    if (_connectedEndpointId == id) {
      final name = _connectedEndpointName ?? 'Opponent';
      _connectedEndpointId = null;
      _connectedEndpointName = null;
      onConnectionChanged?.call(false, name);
      notifyListeners();
    }
  }

  void _onPayloadReceived(String id, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      final json = jsonDecode(String.fromCharCodes(payload.bytes!));
      final move = NetworkMove.fromJson(json);
      onMoveReceived?.call(move);
    }
  }

  /// Send a move to the connected peer
  Future<void> sendMove(NetworkMove move) async {
    if (_connectedEndpointId == null) return;
    final bytes = utf8.encode(jsonEncode(move.toJson()));
    await _nearby.sendBytesPayload(_connectedEndpointId!, Uint8List.fromList(bytes));
  }

  Future<void> stop() async {
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    _isAdvertising = false;
    _isDiscovering = false;
    _connectedEndpointId = null;
    _connectedEndpointName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

class DiscoveredEndpoint {
  final String id;
  final String name;
  const DiscoveredEndpoint({required this.id, required this.name});
}
