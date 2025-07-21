class CarData {
  final bool isConnected;
  final bool isManualMode;
  final double speedValue;
  final double currentSpeed;
  final double pwmDutyCycle;
  final double batteryVoltage;

  const CarData({
    required this.isConnected,
    required this.isManualMode,
    required this.speedValue,
    required this.currentSpeed,
    required this.pwmDutyCycle,
    required this.batteryVoltage,
  });

  CarData copyWith({
    bool? isConnected,
    bool? isManualMode,
    double? speedValue,
    double? currentSpeed,
    double? pwmDutyCycle,
    double? batteryVoltage,
  }) {
    return CarData(
      isConnected: isConnected ?? this.isConnected,
      isManualMode: isManualMode ?? this.isManualMode,
      speedValue: speedValue ?? this.speedValue,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      pwmDutyCycle: pwmDutyCycle ?? this.pwmDutyCycle,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
    );
  }
}