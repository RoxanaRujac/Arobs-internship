import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class CarCommunicationService {
  static const String espIp = '192.168.4.1';
  static const int espPort = 444;
  
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  static bool _isConnecting = false;
  
  // Stream controllers for real-time data
  static final StreamController<Map<String, dynamic>> _statusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  static final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  
  // Timers for connection management
  static Timer? _reconnectTimer;
  static Timer? _pingTimer;
  
  // Getters for streams
  static Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  static Stream<bool> get connectionStream => _connectionController.stream;
  static bool get isConnected => _isConnected;
  
  // Initialize WebSocket connection
  static Future<bool> connect() async {
    if (_isConnected || _isConnecting) return _isConnected;
    
    _isConnecting = true;
    
    try {
      print('🔄 Connecting to ESP32 at ws://$espIp:$espPort');
      
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$espIp:$espPort'),
      );
      
      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      
      // Wait a bit to see if connection is established
      await Future.delayed(const Duration(seconds: 2));
      
      if (_isConnected) {
        _startPingTimer();
        print('✅ Connected to ESP32');
      }
      
      _isConnecting = false;
      return _isConnected;
      
    } catch (e) {
      print('❌ Failed to connect to ESP32: $e');
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(false);
      _startReconnectTimer();
      return false;
    }
  }
  

//{"type": "connection", "status": "connected"}
//{"type": "status", "speed": 15.5, "pwm": 75, "battery": 4.1}
//{"type": "ack", "command": "FORWARD"}
//{"type": "pong"}

  // Handle incoming messages from ESP32
  static void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      
      switch (type) {
        case 'connection':
          _isConnected = true;
          _connectionController.add(true);
          break;
          
        case 'status':
          // Forward status updates to the app
          _statusController.add({
            'connected': true,
            'speed': data['speed']?.toDouble() ?? 0.0,
            'pwm': data['pwm']?.toDouble() ?? 0.0,
            'battery': data['battery']?.toDouble() ?? 3.9,
          });
          break;
          
        case 'ack':
          break;
          
        case 'pong':
          // Keep-alive response
          break;
          
        default:
          print('📥 Received unknown message type: $type');
      }
    } catch (e) {
      print('❌ Error parsing message: $e');
    }
  }
  
  // Handle connection errors
  static void _handleError(error) {
    print('❌ WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _startReconnectTimer();
  }
  
  // Handle disconnection
  static void _handleDisconnection() {
    print('🔌 Disconnected from ESP32');
    _isConnected = false;
    _connectionController.add(false);
    _pingTimer?.cancel();
    _startReconnectTimer();
  }
  
  // Start automatic reconnection
  static void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected && !_isConnecting) {
        print('🔄 Attempting to reconnect...');
        connect();
      } else if (_isConnected) {
        timer.cancel();
      }
    });
  }
  
  // Start ping timer to keep connection alive
  static void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isConnected) {
        _sendMessage({'type': 'ping'});
      } else {
        timer.cancel();
      }
    });
  }
  
  // Send message to ESP32
  static void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('❌ Error sending message: $e');
      }
    }
  }
  
  // Send direction commands
  static Future<bool> sendDirections(Set<String> directions) async {
    if (!_isConnected) {
      print('❌ Not connected to ESP32');
      return false;
    }
    
    final command = _buildDirectionCommand(directions);
  
    
    _sendMessage({
      'type': 'direction',
      'command': command,
      'directions': directions.toList(),
    });
    
    return true;
  }
  
  // Build direction command string
  static String _buildDirectionCommand(Set<String> directions) {
    if (directions.isEmpty) return 'STOP';
    
    if (directions.contains('forward') && directions.contains('left')) {
      return 'FORWARD_LEFT';
    } else if (directions.contains('forward') && directions.contains('right')) {
      return 'FORWARD_RIGHT';
    } else if (directions.contains('backward') && directions.contains('left')) {
      return 'BACKWARD_LEFT';
    } else if (directions.contains('backward') && directions.contains('right')) {
      return 'BACKWARD_RIGHT';
    } else if (directions.contains('forward')) {
      return 'FORWARD';
    } else if (directions.contains('backward')) {
      return 'BACKWARD';
    } else if (directions.contains('left')) {
      return 'LEFT';
    } else if (directions.contains('right')) {
      return 'RIGHT';
    }
    
    return 'STOP';
  }
  
  // Legacy method for backward compatibility
  static Future<bool> sendDirection(String direction) async {
    return sendDirections({direction});
  }
  
  // Send speed command
  static Future<bool> sendSpeed(double speed) async {
    if (!_isConnected) {
      print('❌ Not connected to ESP32');
      return false;
    }
    speed *= 100; // Convert to percentage (0-100)
    print('speed : $speed%');

    _sendMessage({
      'type': 'speed',
      'speed': speed,
    });
    
    return true;
  }
  
  // Get car status
  static Future<Map<String, dynamic>?> getCarStatus() async {
    if (!_isConnected) {
      await connect();
      
      if (!_isConnected) {
        return {
          'connected': false,
          'speed': 0.0,
          'pwm': 0.0,
          'battery': 0.0,
        };
      }
    }
    
    // Return the latest status
    return {
      'connected': _isConnected,
      'speed': 0.0, //  updated via stream
      'pwm': 0.0,   
      'battery': 3.9,
    };
  }
  
  // Initialize the service
  static Future<void> initialize() async {
    await connect();
    statusStream.listen((status) {
    });
  }
  
  // Disconnect and cleanup
  static Future<void> disconnect() async {
    print('🔌 Disconnecting from ESP32');
    
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    
    _isConnected = false;
    _connectionController.add(false);
  }
  
  // Dispose resources
  static void dispose() {
    disconnect();
    _statusController.close();
    _connectionController.close();
  }
}