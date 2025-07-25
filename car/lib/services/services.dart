import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'dart:typed_data';

class CarCommunicationService {
  static const String espIp = '192.168.4.1';
  static const int espPort = 444;

  static int commandNumber = 0;
  static Socket? _socket;
  static bool _isConnected = false;
  static bool _isConnecting = false;

  static final _statusController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final _connectionController = StreamController<bool>.broadcast();

  static Timer? _reconnectTimer;
  static Timer? _pingTimer;

  static Stream<Map<String, dynamic>> get statusStream =>
      _statusController.stream;
  static Stream<bool> get connectionStream => _connectionController.stream;
  static bool get isConnected => _isConnected;

  static bool _emergencyLightsOn = false;
  static bool get emergencyLightsOn => _emergencyLightsOn;

  static Future<bool> toggleEmergencyLights() async {
    if (!_isConnected) {
      developer.log('❌ Not connected');
      return false;
    }

    _emergencyLightsOn = !_emergencyLightsOn;

    _send({
      'type': 'emergency_lights',
      'state': _emergencyLightsOn ? 'on' : 'off',
    });

    //print('🚨 Emergency lights ${_emergencyLightsOn ? 'ON' : 'OFF'}');
    return true;
  }

  static Future<bool> setEmergencyLights(bool enabled) async {
    if (!_isConnected) {
      developer.log('❌ Not connected');
      return false;
    }

    _emergencyLightsOn = enabled;

    _send({'type': 'emergency_lights', 'state': enabled ? 'on' : 'off'});

    developer.log('🚨 Emergency lights ${enabled ? 'ON' : 'OFF'}');
    return true;
  }

  static Future<bool> park() async {
    if (!_isConnected) {
      developer.log('❌ Not connected');
      return false;
    }

    _send({'type': 'park'});

    developer.log('✅ Car parked successfully');
    return true;
  } 

  static Future<bool> mode(String mode) async {
    if (!_isConnected) { 
      developer.log('❌ Not connected');
      return false;
    }

    _send({'type': 'mode', 'mode': mode});

    developer.log('✅ Mode set to $mode');
    return true;
  }

  static Future<bool> connect() async {
    if (_isConnected || _isConnecting) return _isConnected;
    _isConnecting = true;

    try {
      developer.log('🔄 Connecting to ESP32 at $espIp:$espPort');
      _socket = await Socket.connect(
        espIp,
        espPort,
        timeout: Duration(seconds: 5),
      );
      _isConnected = true;
      _connectionController.add(true);

      _socket!.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      _startPingTimer();
      print('✅ Connected to ESP32');
    } catch (e) {
      print('❌ Failed to connect to ESP32: $e');
      _isConnected = false;
      _connectionController.add(false);
      _startReconnectTimer();
    }

    _isConnecting = false;
    return _isConnected;
  }

  static void _handleMessage(Uint8List data) {
    try {
      final raw = utf8.decode(data);
      final messages = raw.split('\n');

      for (final msg in messages) {
        if (msg.trim().isEmpty) continue;

        final json = jsonDecode(msg);
        final type = json['type'];

        switch (type) {
          case 'connection':
            _isConnected = true;
            _connectionController.add(true);
            break;
          case 'status':
            _statusController.add({
              'connected': true,
              'speed': json['speed']?.toDouble() ?? 0.0,
              'pwm': json['pwm']?.toDouble() ?? 0.0,
              'battery': json['battery']?.toDouble() ?? 3.9,
            });
            break;
          case 'pong':
            break;
          default:
            developer.log('📥 Unknown type: $type');
        }
      }
    } catch (e) {
      developer.log('❌ Error parsing message: $e');
    }
  }

  static void _handleError(error) {
    developer.log('❌ TCP error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _startReconnectTimer();
  }

  static void _handleDisconnection() {
    developer.log('🔌 Disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _pingTimer?.cancel();
    _startReconnectTimer();
  }

  static void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isConnected && !_isConnecting) {
        developer.log('🔄 Reconnecting...');
        connect();
      } else if (_isConnected) {
        timer.cancel();
      }
    });
  }

  static void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (_isConnected) {
        _send({'type': 'ping'});
      }
    });
  }

  static void _send(Map<String, dynamic> message) {
    if (_socket != null && _isConnected) {
      try {
        final encoded = jsonEncode(message) + '\n'; // important!
        _socket!.write(encoded);

        if (!message.containsValue('ping')) {
          commandNumber++;
          print('➡️ Sent message: $encoded');
          print('Sending message number: $commandNumber');
        }
        
        _socket!.flush();
        
      } catch (e) {
        developer.log('❌ Failed to send message: $e');
      }
    }
  }

  static Future<bool> sendDirections(Set<String> directions) async {
    if (!_isConnected) {
      developer.log('❌ Not connected');
      return false;
    }

    final command = _buildDirectionCommand(directions);
    print('➡️ Sending command: $command');

    _send({
      'type': 'direction',
      'command': command,
      'directions': directions.toList(),
    });

    return true;
  }

  static String _buildDirectionCommand(Set<String> directions) {
    if (directions.isEmpty) return 'STOP';
    if (directions.contains('forward') && directions.contains('left'))
      return 'FORWARD_LEFT';
    if (directions.contains('forward') && directions.contains('right'))
      return 'FORWARD_RIGHT';
    if (directions.contains('backward') && directions.contains('left'))
      return 'BACKWARD_LEFT';
    if (directions.contains('backward') && directions.contains('right'))
      return 'BACKWARD_RIGHT';
    if (directions.contains('forward')) return 'FORWARD';
    if (directions.contains('backward')) return 'BACKWARD';
    if (directions.contains('left')) return 'LEFT';
    if (directions.contains('right')) return 'RIGHT';
    return 'STOP';
  }

  static Future<bool> sendDirection(String direction) async {
    return sendDirections({direction});
  }

  static Future<bool> sendSpeed(double speed) async {
    if (!_isConnected) return false;
    speed *= 100;
    developer.log('Speed: $speed%');
    _send({'type': 'speed', 'speed': speed});
    return true;
  }

  static Future<Map<String, dynamic>?> getCarStatus() async {
    if (!_isConnected) {
      await connect();
      if (!_isConnected) {
        return {'connected': false, 'speed': 0.0, 'pwm': 0.0, 'battery': 0.0};
      }
    }
    return {'connected': true, 'speed': 0.0, 'pwm': 0.0, 'battery': 3.9};
  }

  static Future<void> initialize() async {
    await connect();
    statusStream.listen((status) {});
  }

  static Future<void> disconnect() async {
    developer.log('🔌 Disconnecting');
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _socket?.close();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  static void dispose() {
    disconnect();
    _statusController.close();
    _connectionController.close();
  }
}
