import 'package:flutter/material.dart';
import 'dart:async';
import '../models/car_data.dart';
import '../services/services.dart';
import 'dart:developer' as developer;

class CarController extends ChangeNotifier {
  CarData _carData = const CarData(
    isConnected: false,
    isManualMode: true,
    speedValue: 0.4,
    currentSpeed: 5.0,
    pwmDutyCycle: 65.0,
    batteryVoltage: 3.9,
  );

  Timer? _statusUpdateTimer;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _connectionSubscription;
  bool _isDisposed = false;
  Set<String> _currentDirections = {};

  CarData get carData => _carData;

  bool _emergencyLightsOn = false;
  bool get emergencyLightsOn => _emergencyLightsOn;

Future<bool> toggleEmergencyLights() async {
    try {
      final success = await CarCommunicationService.toggleEmergencyLights();
      if (success) {
        _emergencyLightsOn = CarCommunicationService.emergencyLightsOn;
        notifyListeners(); // Notify UI to update
        developer.log('✅ Emergency lights toggled: ${_emergencyLightsOn ? 'ON' : 'OFF'}');
      }
      return success;
    } catch (e) {
      developer.log('❌ Failed to toggle emergency lights: $e');
      return false;
    }
  }

  // Set emergency lights state directly
  Future<bool> setEmergencyLights(bool enabled) async {
    try {
      final success = await CarCommunicationService.setEmergencyLights(enabled);
      if (success) {
        _emergencyLightsOn = enabled;
        notifyListeners(); // Notify UI to update
        print('✅ Emergency lights set to: ${enabled ? 'ON' : 'OFF'}');
      }
      return success;
    } catch (e) {
      print('❌ Failed to set emergency lights: $e');
      return false;
    }
  }
 
  Future<bool> park() async {
    try {
      final success = await CarCommunicationService.park();
      if (success) {
        print('✅ Car parked successfully');
      }
      return success;
    } catch (e) {
      print('❌ Failed to park car: $e');
      return false;
    }
  }


  // Initialize controller and start WebSocket connection
  void initialize() {
    _initializeWebSocket();
  }

  // Initialize WebSocket connection and listeners
  Future<void> _initializeWebSocket() async {
    // Initialize the WebSocket service
    await CarCommunicationService.initialize();

    // Listen to connection status changes
    _connectionSubscription = CarCommunicationService.connectionStream.listen((
      isConnected,
    ) {
      if (!_isDisposed) {
        updateCarData(_carData.copyWith(isConnected: isConnected));
        if (isConnected) {
          print('✅ WebSocket connected');
        } else {
          print('❌ WebSocket disconnected');
        }
      }
    });

    // Listen to real-time status updates
    _statusSubscription = CarCommunicationService.statusStream.listen((status) {
      if (!_isDisposed) {
        updateCarData(
          _carData.copyWith(
            isConnected: status['connected'] ?? false,
            currentSpeed: status['speed'] ?? 0.0,
            pwmDutyCycle: status['pwm'] ?? 0.0,
            batteryVoltage: status['battery'] ?? 3.9,
          ),
        );
      }
    });

    // Fallback status updates for compatibility
    _startStatusUpdates();
  }

  // Update car data and notify listeners
  void updateCarData(CarData newData) {
    if (_isDisposed) return;
    _carData = newData;
    notifyListeners();
  }

  // Toggle between manual and auto mode
  void toggleMode(bool isManual) {
    // Stop all directions when switching modes
    if (!isManual) {
      _currentDirections.clear();
      CarCommunicationService.sendDirections({});
    }
    updateCarData(_carData.copyWith(isManualMode: isManual));
  }

  // Update speed value from slider
  void updateSpeed(double speed) {
    updateCarData(_carData.copyWith(speedValue: speed));
  }

  // Send multiple direction commands to car (for simultaneous control)
  Future<bool> sendDirections(Set<String> directions) async {
    if (!_carData.isManualMode) {
      developer.log('❌ Cannot send directions in auto mode');
      return false;
    }

    _currentDirections = directions;

    try {
      final success = await CarCommunicationService.sendDirections(directions);
      if (success) {
        if (directions.isEmpty) {
          //print('✅ Stop command sent successfully');
        } else {
          //print('✅ Direction commands sent successfully: ${directions.join(', ')}');
        }
      }
      return success;
    } catch (e) {
      developer.log('❌ Failed to send directions: $e');
      return false;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> sendDirection(String direction) async {
    return sendDirections({direction});
  }

  // Send speed command to car
  Future<bool> sendSpeedCommand(double speed) async {
    try {
      final success = await CarCommunicationService.sendSpeed(speed);
      if (success) {}
      return success;
    } catch (e) {
      return false;
    }
  }

  // Get current pressed directions
  Set<String> get currentDirections => Set.from(_currentDirections);

  // Check connection status
  bool get isConnected => CarCommunicationService.isConnected;

  Future<bool> reconnect() async {
    return await CarCommunicationService.connect();
  }

  // Start periodic status updates (fallback)
  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (_isDisposed) return;

      try {
        final status = await CarCommunicationService.getCarStatus();
        if (status != null && !_isDisposed) {
          // Only update if we don't have a WebSocket connection
          if (!CarCommunicationService.isConnected) {
            updateCarData(
              _carData.copyWith(
                isConnected: status['connected'] ?? false,
                currentSpeed: (status['speed'] ?? 0.0).toDouble(),
                pwmDutyCycle: (status['pwm'] ?? 0.0).toDouble(),
                batteryVoltage: (status['battery'] ?? 3.9).toDouble(),
              ),
            );
          }
        }
      } catch (e) {
        developer.log('❌ Failed to get car status: $e');
        if (!_isDisposed) {
          updateCarData(_carData.copyWith(isConnected: false));
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _statusUpdateTimer?.cancel();
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();

    // Stop all directions when disposing
    _currentDirections.clear();
    CarCommunicationService.sendDirections({});

    super.dispose();
  }
}
