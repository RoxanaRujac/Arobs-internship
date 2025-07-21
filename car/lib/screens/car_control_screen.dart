import 'package:flutter/material.dart';
import '../controllers/car_controller.dart';
import '../theme/app_theme.dart';
import '../components/ui_components.dart';
import '../panels/main_panels.dart';

class CarControlScreen extends StatefulWidget {
  const CarControlScreen({super.key});

  @override
  State<CarControlScreen> createState() => _CarControlScreenState();
}

class _CarControlScreenState extends State<CarControlScreen> {
  late CarController _carController;

  @override
  void initState() {
    super.initState();
    _carController = CarController();
    _carController.initialize();
  }

  @override
  void dispose() {
    _carController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: ListenableBuilder(
            listenable: _carController,
            builder: (context, child) {
              final carData = _carController.carData;
              
              return Column(
                children: [
                  // Connection Status
                  ConnectionStatusBar(isConnected: carData.isConnected),
                  
                  const SizedBox(height: 16),
                  
                  // Control Section
                  const SectionTitleBar(title: 'Control'),
                  const SizedBox(height: 4),
                  
                  Expanded(
                    flex: 7,
                    child: ControlPanel(
                      carData: carData,
                      controller: _carController,
                      onShowMessage: _showMessage,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats Section
                  const SectionTitleBar(title: 'Dashboard'),
                  const SizedBox(height: 4),

                  Expanded(
                    flex: 3,
                    child: StatsPanel(carData: carData),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}