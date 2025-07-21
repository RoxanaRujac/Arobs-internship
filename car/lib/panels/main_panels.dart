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

            // Content based on mode
            Expanded(
              child: carData.isManualMode 
                ? _buildManualContent()
                : _buildAutoContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualContent() {
    return Column(
      children: [
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
    );
  }

  Widget _buildAutoContent() {
    return Column(
      children: [
        // Auto mode dropdowns
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAutoDropdown('Follow', ['Line', 'Circle', 'Object']),
              _buildAutoDropdown('Count', ['Thrash cans', 'Bottles', 'Objects']),
              _buildAutoDropdown('Feature', ['Detection', 'Recognition', 'Tracking']),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Go Button
        Container(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              // Handle auto mode start
              onShowMessage('Auto mode started');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightGrey,
              foregroundColor: Colors.black87,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Go',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoDropdown(String label, List<String> options) {
    return Row(
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.first,
                isExpanded: true,
                items: options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  // Handle dropdown change
                },
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StatsPanel extends StatefulWidget {
  final CarData carData;

  const StatsPanel({super.key, required this.carData});

  @override
  State<StatsPanel> createState() => _StatsPanelState();
}

class _StatsPanelState extends State<StatsPanel> {
  bool _isStatsSelected = true;

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
            // Stats/Extra Toggle
            Row(
              children: [
                CustomToggleButton(
                  text: 'Stats',
                  isSelected: _isStatsSelected,
                  onTap: () => setState(() => _isStatsSelected = true),
                ),
                const SizedBox(width: 8),
                CustomToggleButton(
                  text: 'Extra',
                  isSelected: !_isStatsSelected,
                  onTap: () => setState(() => _isStatsSelected = false),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Content based on selected tab
            Expanded(
              child: _isStatsSelected 
                ? _buildStatsContent()
                : _buildExtraContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    return Column(
      children: [
        StatisticRow(
          label: 'Speed',
          value: '${widget.carData.currentSpeed.toStringAsFixed(0)} km/h',
        ),
        const SizedBox(height: 12),
        
        StatisticRow(
          label: 'PWM duty cycle',
          value: '${widget.carData.pwmDutyCycle.toStringAsFixed(0)}%',
        ),
        const SizedBox(height: 12),
        
        StatisticRow(
          label: 'Battery',
          value: '${widget.carData.batteryVoltage.toStringAsFixed(1)} V',
        ),
      ],
    );
  }

  Widget _buildExtraContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildExtraButton(
          icon: Icons.warning,
          label: 'Emergency\nlights',
          color: Colors.red,
          onTap: () {
            // Handle emergency lights
          },
        ),
        _buildExtraButton(
          icon: Icons.local_parking,
          label: 'Park',
          color: Colors.yellow,
          onTap: () {
            // Handle park
          },
        ),
        _buildExtraButton(
          icon: Icons.star_outline,
          label: 'Crash\nassistant',
          color: Colors.purple[300]!,
          onTap: () {
            // Handle crash assistant
          },
        ),
      ],
    );
  }

  Widget _buildExtraButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}