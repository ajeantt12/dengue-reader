import 'package:flutter/material.dart';
import '../../../../shared/models/dot_reading.dart';
import '../../../../core/theme/app_colors.dart';

/// Row roles under the control-calibrated scheme (see ResultCalculator):
/// row 1 anchors "fully reactive", row 2 anchors "background", row 3 is the
/// sample judged against those two anchors.
const _rowRoleLabels = {
  1: 'Positive control',
  2: 'Negative control',
  3: 'Sample',
};

class DotGridDisplay extends StatelessWidget {
  final List<DotReading> readings;

  /// dotIds classed reactive by ResultCalculator's calibrated threshold for
  /// this analysis. Colours every well, so the controls visibly confirm they
  /// behaved as expected alongside the sample's own classification.
  final Set<String> reactiveDotIds;

  const DotGridDisplay(
      {super.key, required this.readings, this.reactiveDotIds = const {}});

  @override
  Widget build(BuildContext context) {
    // Derive the grid shape from the readings themselves so it adapts to
    // whatever the detector found (a close-up shows a 3×3 block).
    final rowIndices = <int>{};
    final colIndices = <int>{};
    for (final d in readings) {
      final m = RegExp(r'^R(\d+)C(\d+)$').firstMatch(d.dotId);
      if (m == null) continue;
      rowIndices.add(int.parse(m.group(1)!));
      colIndices.add(int.parse(m.group(2)!));
    }
    final rows = rowIndices.toList()..sort();
    final cols = colIndices.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dot Readings', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        const Text(
            'Row 1: positive control · Row 2: negative control · Row 3: sample',
            style: TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 110),
            ...cols.map((c) => Expanded(
              child: Center(child: Text('C$c', style: const TextStyle(fontWeight: FontWeight.bold))),
            )),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.map((rowNum) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    _rowRoleLabels[rowNum] ?? 'Row $rowNum',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                ...cols.map((c) {
                  final dotId = 'R${rowNum}C$c';
                  final reading = readings.where((d) => d.dotId == dotId).firstOrNull;
                  return Expanded(
                    child: Center(
                      child: _DotCircle(
                        reading: reading,
                        isReactive:
                            reading != null && reactiveDotIds.contains(dotId),
                      ),
                    ),
                  );
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
  final bool isReactive;
  const _DotCircle({this.reading, this.isReactive = false});

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

    final color = isReactive ? AppColors.positive : AppColors.invalid;
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
