import 'package:flutter/material.dart';

enum LightLevel { tooDataark, dim, good, bright }

class LightingIndicator extends StatelessWidget {
  final double brightness; // 0.0–1.0

  const LightingIndicator({super.key, required this.brightness});

  LightLevel get _level {
    if (brightness < 0.15) return LightLevel.tooDataark;
    if (brightness < 0.30) return LightLevel.dim;
    if (brightness < 0.85) return LightLevel.good;
    return LightLevel.bright;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;

    final (icon, color, label) = switch (level) {
      LightLevel.tooDataark => (Icons.brightness_2, Colors.red, 'Too dark — flash enabled'),
      LightLevel.dim => (Icons.brightness_3, Colors.orange, 'Low light — hold steady'),
      LightLevel.good => (Icons.brightness_5, Colors.greenAccent, 'Good lighting'),
      LightLevel.bright => (Icons.brightness_7, Colors.amber, 'Very bright — avoid glare'),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
