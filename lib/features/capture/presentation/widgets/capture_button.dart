import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  final VoidCallback? onTap;
  final int countdown; // 0 = idle, >0 = counting down

  const CaptureButton({super.key, this.onTap, required this.countdown});

  @override
  Widget build(BuildContext context) {
    final isActive = countdown > 0;

    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.amber : Colors.white,
            width: 4,
          ),
        ),
        child: Center(
          child: isActive
              ? Text(
                  '$countdown',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onTap != null ? Colors.white : Colors.white38,
                  ),
                ),
        ),
      ),
    );
  }
}
