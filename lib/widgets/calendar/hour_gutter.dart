import 'package:flutter/material.dart';

import 'time_grid_metrics.dart';

class HourGutter extends StatelessWidget {
  const HourGutter({super.key, required this.range});

  final TimeRange range;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hourCount = range.endHour - range.startHour;

    return SizedBox(
      width: kGutterWidth,
      height: hourCount * kHourHeight,
      child: Stack(
        children: [
          for (var i = 0; i < hourCount; i++)
            Positioned(
              top: i * kHourHeight - 7,
              right: 6,
              child: Text(
                '${(range.startHour + i).toString().padLeft(2, '0')}:00',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
