import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import '../providers/storage_provider.dart';

void _log(String msg) {
  if (kDebugMode) print(msg);
}

final socketServiceProvider = Provider<UserSocketService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return UserSocketService(storage);
});

class UserSocketService {
  io.Socket? _socket;
  final dynamic _storage;

  /// The ride room currently joined — re-joined automatically on reconnect.
  String? _currentRideId;

  // Stream controllers for ride events
  final _rideAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _rideStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _rideCompletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _destinationChangeResponseController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _rideMatchingProgressController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onRideAccepted =>
      _rideAcceptedController.stream;
  Stream<Map<String, dynamic>> get onDriverLocation =>
      _driverLocationController.stream;
  Stream<Map<String, dynamic>> get onRideStatusUpdate =>
      _rideStatusController.stream;
  Stream<Map<String, dynamic>> get onRideCompleted =>
      _rideCompletedController.stream;
  Stream<Map<String, dynamic>> get onChatMessage =>
      _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onDestinationChangeResponse =>
      _destinationChangeResponseController.stream;
  Stream<Map<String, dynamic>> get onRideMatchingProgress =>
      _rideMatchingProgressController.stream;

  bool get isConnected => _socket?.connected == true;

  UserSocketService(this._storage);

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await _storage.getAccessToken();
    if (token == null) return;

    final baseUrl = ApiConstants.baseUrl.replaceAll('/v1', '');

    _socket = io.io(
      '$baseUrl/rides',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(999999)
          .build(),
    );

    _socket!.onConnect((_) {
      _log('[Socket] Connected to /rides namespace');
      // Re-join ride room on every (re)connect so the server adds us back
      if (_currentRideId != null) {
        _log('[Socket] Re-joining ride room: $_currentRideId');
        _socket!.emit('ride:join', {'rideId': _currentRideId});
      }
    });

    _socket!.onDisconnect((_) {
      _log('[Socket] Disconnected');
    });

    _socket!.onConnectError((error) {
      _log('[Socket] Connection error: $error');
    });

    _socket!.onReconnect((_) {
      _log('[Socket] Reconnected to /rides namespace');
      // Re-join ride room after reconnection
      if (_currentRideId != null) {
        _log('[Socket] Re-joining ride room after reconnect: $_currentRideId');
        _socket!.emit('ride:join', {'rideId': _currentRideId});
      }
    });

    // Confirmation that we joined a ride room
    _socket!.on('ride:joined', (data) {
      _log('[Socket] Confirmed joined ride room: $data');
    });

    // Main status change handler — covers accepted, started, completed, cancelled
    _socket!.on('ride:status:changed', (data) {
      _log('[Socket] Status changed: $data');
      final map = _toMap(data);
      if (map == null) return;

      final status = map['status'] as String? ?? '';
      switch (status) {
        case 'ACCEPTED':
          _rideAcceptedController.add(map);
          break;
        case 'IN_PROGRESS':
          _rideStatusController.add(map);
          break;
        case 'COMPLETED':
          _rideCompletedController.add(map);
          break;
        case 'CANCELLED':
        case 'CANCELLED_BY_DRIVER':
          _rideStatusController.add({'status': 'CANCELLED', ...map});
          break;
        default:
          _rideStatusController.add(map);
      }
    });

    // Driver arrived at pickup — separate event
    _socket!.on('ride:arrived:pickup', (data) {
      _log('[Socket] Driver arrived at pickup');
      final map = _toMap(data);
      _rideStatusController.add({'status': 'DRIVER_ARRIVED', ...?map});
    });

    // Direct ride:accepted event from matching service
    _socket!.on('ride:accepted', (data) {
      _log('[Socket] Ride accepted: $data');
      final map = _toMap(data);
      if (map != null) {
        _rideAcceptedController.add(map);
      }
    });

    // Driver location updates
    _socket!.on('ride:driver:location', (data) {
      _log('[Socket] Driver location received: $data');
      final map = _toMap(data);
      if (map != null) {
        _driverLocationController.add(map);
      }
    });

    // No driver found
    _socket!.on('ride:no_driver', (data) {
      _log('[Socket] No driver found');
      final map = _toMap(data);
      _rideStatusController.add({'status': 'NO_DRIVER', ...?map});
    });

    // Chat messages
    _socket!.on('chat:message', (data) {
      _log('[Socket] Chat message received: $data');
      final map = _toMap(data);
      if (map != null) {
        _chatMessageController.add(map);
      }
    });

    // Destination change response from driver
    _socket!.on('ride:destination_change_response', (data) {
      _log('[Socket] Destination change response: $data');
      final map = _toMap(data);
      if (map != null) {
        _destinationChangeResponseController.add(map);
      }
    });

    // Ride matching progress (radius expansion)
    _socket!.on('ride:matching:progress', (data) {
      _log('[Socket] Ride matching progress: $data');
      final map = _toMap(data);
      if (map != null) {
        _rideMatchingProgressController.add(map);
      }
    });
  }

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  void joinRide(String rideId) {
    _currentRideId = rideId;
    _log('[Socket] joinRide called: rideId=$rideId, connected=$isConnected');
    _socket?.emit('ride:join', {'rideId': rideId});
  }

  void leaveRide(String rideId) {
    if (_currentRideId == rideId) _currentRideId = null;
    _socket?.emit('ride:leave', {'rideId': rideId});
  }

  void sendChatMessage(String rideId, String message) {
    _log('[Socket] Sending chat message: rideId=$rideId');
    _socket?.emit('chat:message', {
      'rideId': rideId,
      'message': message,
      'senderRole': 'USER',
    });
  }

  void disconnect() {
    _currentRideId = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _rideAcceptedController.close();
    _driverLocationController.close();
    _rideStatusController.close();
    _rideCompletedController.close();
    _chatMessageController.close();
    _destinationChangeResponseController.close();
    _rideMatchingProgressController.close();
  }
}
