import 'package:flutter/material.dart';
import '../models/car_data.dart';
import '../controllers/car_controller.dart';
import '../theme/app_theme.dart';
import '../components/ui_components.dart';

class ControlPanel extends StatelessWidget {
  final CarData carData;
  final CarController controller;
  final Function(String) onShowMessage;

  const ControlPanel({
    super.key,
    required this.carData,
    required this.controller,
    required this.onShowMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        borderRadius: AppTheme.containerBorderRadius,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: AppTheme.defaultBorderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manual/Auto Toggle - Made responsive
            Row(
              children: [
                CustomToggleButton(
                  text: 'Manual',
                  isSelected: carData.isManualMode,
                  onTap: () => controller.toggleMode(true),
                ),
                const SizedBox(width: 8),
                CustomToggleButton(
                  text: 'Auto',
                  isSelected: !carData.isManualMode,
                  onTap: () => controller.toggleMode(false),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Direction Label
            const Center(
              child: Text('Direction', style: AppTheme.labelStyle),
            ),
            
            // Joystick Direction Controls
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: JoystickDirectionControl(
                  isManualMode: carData.isManualMode,
                  onDirectionPressed: (directions) async {
                    final success = await controller.sendDirections(directions);
                    if (!success && directions.isNotEmpty) {
                      //onShowMessage('Failed to send direction commands');
                    }
                  },
                ),
              ),
            ),
  
            const SizedBox(height: 16),

            // Speed Label
            const Center(
              child: Text('Speed', style: AppTheme.labelStyle),
            ),
            
            const SizedBox(height: 8),

            // Speed Slider
            CustomSpeedSlider(
              value: carData.speedValue,
              onChanged: (value) => controller.updateSpeed(value),
              onChangeEnd: (value) async {
                final success = await controller.sendSpeedCommand(value);
                if (!success) {
                  onShowMessage('Failed to set speed');
                }
              },
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class StatsPanel extends StatelessWidget {
  final CarData carData;

  const StatsPanel({super.key, required this.carData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        borderRadius: AppTheme.containerBorderRadius,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: AppTheme.defaultBorderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            StatisticRow(
              label: 'Speed',
              value: '${carData.currentSpeed.toStringAsFixed(0)} km/h',
            ),
            const SizedBox(height: 12),
            
            StatisticRow(
              label: 'PWM duty cycle',
              value: '${carData.pwmDutyCycle.toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 12),
            
            StatisticRow(
              label: 'Battery',
              value: '${carData.batteryVoltage.toStringAsFixed(1)} V',
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}