import 'package:flutter/material.dart';
import '../../../../shared/models/dot_reading.dart';
import '../../../../core/theme/app_colors.dart';

class DotGridDisplay extends StatelessWidget {
  final List<DotReading> readings;

  const DotGridDisplay({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    const rows = ['R1', 'R2', 'R3'];
    const cols = ['C1', 'C2'];
    const rowLabels = ['Control', 'IgM', 'IgG'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dot Readings', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 60),
            ...cols.map((c) => Expanded(
              child: Center(child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))),
            )),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(rows.length, (ri) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(rowLabels[ri], style: const TextStyle(fontSize: 12)),
                ),
                ...cols.map((c) {
                  final dotId = '${rows[ri]}$c';
                  final reading = readings.where((d) => d.dotId == dotId).firstOrNull;
                  return Expanded(child: Center(child: _DotCircle(reading: reading)));
                }),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        const Row(children: [
          _LegendDot(color: AppColors.positive),
          SizedBox(width: 4),
          Text('Reactive', style: TextStyle(fontSize: 12)),
          SizedBox(width: 16),
          _LegendDot(color: AppColors.invalid),
          SizedBox(width: 4),
          Text('Non-reactive', style: TextStyle(fontSize: 12)),
        ]),
      ],
    );
  }
}

class _DotCircle extends StatelessWidget {
  final DotReading? reading;
  const _DotCircle({this.reading});

  @override
  Widget build(BuildContext context) {
    if (reading == null) {
      return const SizedBox(
        width: 40, height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black12),
        ),
      );
    }

    final color = reading!.isReactive ? AppColors.positive : AppColors.invalid;
    final sat = (reading!.saturation * 100).toStringAsFixed(0);

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 2),
        Text('S:$sat%', style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
