import 'package:flutter/material.dart';
import 'package:car/theme/app_theme.dart';
import 'dart:async';

class DirectionButton extends StatelessWidget {
  final IconData icon;
  final String direction;
  final bool isEnabled;
  final bool isPressed;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final double? size;

  const DirectionButton({
    super.key,
    required this.icon,
    required this.direction,
    required this.isEnabled,
    required this.isPressed,
    required this.onPressStart,
    required this.onPressEnd,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? 56.0;
    final iconSize = buttonSize; // Icon size is 70% of button size

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isEnabled ? (_) => onPressStart() : null,
      onTapUp: isEnabled ? (_) => onPressEnd() : null,
      onTapCancel: isEnabled ? () => onPressEnd() : null,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isEnabled 
            ? (isPressed ? AppTheme.darkGreen : AppTheme.lightGrey)
            : AppTheme.greyContainer,
          shape: BoxShape.circle,
          border: isPressed 
            ? Border.all(color: AppTheme.darkGreen, width: 2)
            : null,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: isEnabled 
            ? (isPressed ? Colors.white : Colors.black54)
            : Colors.grey,
        ),
      ),
    );
  }
}

class DirectionControlPad extends StatefulWidget {
  final bool isManualMode;
  final Function(Set<String>) onDirectionPressed;

  const DirectionControlPad({
    super.key,
    required this.isManualMode,
    required this.onDirectionPressed,
  });

  @override
  State<DirectionControlPad> createState() => _DirectionControlPadState();
}

class _DirectionControlPadState extends State<DirectionControlPad> {
  final Set<String> _pressedDirections = {};
  Timer? _continuousTimer;
  bool _isDisposed = false;
  
  void _startDirection(String direction) {
    if (!widget.isManualMode || _isDisposed) return;
    
    setState(() {
      _pressedDirections.add(direction);
    });
    
    // Send immediately
    widget.onDirectionPressed(_pressedDirections);
    
    // Start continuous sending if not already started
    if (_continuousTimer == null || !_continuousTimer!.isActive) {
      _continuousTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }
        
        if (_pressedDirections.isNotEmpty) {
          widget.onDirectionPressed(_pressedDirections);
        } else {
          timer.cancel();
          _continuousTimer = null;
        }
      });
    }
  }
  
  void _stopDirection(String direction) {
    if (_isDisposed) return;
    
    setState(() {
      _pressedDirections.remove(direction);
    });
    
    // Send current state (might be empty set to stop)
    widget.onDirectionPressed(_pressedDirections);
    
    // Stop continuous timer if no directions are pressed
    if (_pressedDirections.isEmpty) {
      _continuousTimer?.cancel();
      _continuousTimer = null;
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _continuousTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerPadding = 16.0;
        final availableWidth = constraints.maxWidth - (containerPadding * 2);
        final availableHeight = constraints.maxHeight - (containerPadding * 2);
        
        final safeWidth = availableWidth - 10;
        final safeHeight = availableHeight - 10;
      
        final maxButtonFromWidth = (safeWidth - 20) / 2; // 20px minimum spacing
        final maxButtonFromHeight = (safeHeight - 20) / 3; // 20px total spacing
        
        final buttonSize = (maxButtonFromWidth < maxButtonFromHeight ? maxButtonFromWidth : maxButtonFromHeight)
            .clamp(57.0, 90.0); 
        
        final horizontalSpacing = ((safeWidth - (buttonSize * 2)) / 2).clamp(45.0, 80.0);
        final verticalSpacing = ((safeHeight - (buttonSize * 3)) / 2).clamp(1.0, 1.0);
        
        return Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: AppTheme.containerBorderRadius,
          ),
          child: Center(
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Important: don't expand beyond content
                children: [
                  // Up Arrow
                  DirectionButton(
                    icon: Icons.keyboard_arrow_up,
                    direction: 'forward',
                    isEnabled: widget.isManualMode,
                    isPressed: _pressedDirections.contains('forward'),
                    onPressStart: () => _startDirection('forward'),
                    onPressEnd: () => _stopDirection('forward'),
                    size: buttonSize,
                  ),
                  SizedBox(height: verticalSpacing),
                  
                  // Left, Right Arrows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DirectionButton(
                        icon: Icons.keyboard_arrow_left,
                        direction: 'left',
                        isEnabled: widget.isManualMode,
                        isPressed: _pressedDirections.contains('left'),
                        onPressStart: () => _startDirection('left'),
                        onPressEnd: () => _stopDirection('left'),
                        size: buttonSize,
                      ),
                      SizedBox(width: horizontalSpacing),
                      DirectionButton(
                        icon: Icons.keyboard_arrow_right,
                        direction: 'right',
                        isEnabled: widget.isManualMode,
                        isPressed: _pressedDirections.contains('right'),
                        onPressStart: () => _startDirection('right'),
                        onPressEnd: () => _stopDirection('right'),
                        size: buttonSize,
                      ),
                    ],
                  ),
                  SizedBox(height: verticalSpacing),
                  
                  // Down Arrow
                  DirectionButton(
                    icon: Icons.keyboard_arrow_down,
                    direction: 'backward',
                    isEnabled: widget.isManualMode,
                    isPressed: _pressedDirections.contains('backward'),
                    onPressStart: () => _startDirection('backward'),
                    onPressEnd: () => _stopDirection('backward'),
                    size: buttonSize,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Also update the other UI components to be more responsive
class ConnectionStatusBar extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusBar({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: AppTheme.defaultBorderRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isConnected ? Colors.transparent : const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isConnected ? Colors.black87 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitleBar extends StatelessWidget {
  final String title;

  const SectionTitleBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: AppTheme.defaultBorderRadius,
      ),
      child: Text(
        title,
        style: AppTheme.titleStyle,
      ),
    );
  }
}

class CustomToggleButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomToggleButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.darkGreen : AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomSpeedSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const CustomSpeedSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppTheme.darkGreen,
        inactiveTrackColor: AppTheme.lightGreen,
        thumbColor: AppTheme.darkGreen,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12.0,
        ),
        trackHeight: 8.0,
      ),
      child: Slider(
        value: value,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
        min: 0.0,
        max: 1.0,
      ),
    );
  }
}

class StatisticRow extends StatelessWidget {
  final String label;
  final String value;

  const StatisticRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label, 
            style: AppTheme.statLabelStyle.copyWith(fontSize: 14), // Smaller font
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reduced padding
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(10), // Smaller radius
          ),
          child: Text(
            value, 
            style: AppTheme.statValueStyle.copyWith(fontSize: 13), // Smaller font
          ),
        ),
      ],
    );
  }
}