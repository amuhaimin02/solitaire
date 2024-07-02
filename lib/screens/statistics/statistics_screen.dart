import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/statistics.dart';
import '../../widgets/two_pane.dart';
import 'widgets/overall_statistics.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to any change of statistics and update when necessary
    ref.watch(statisticsUpdaterProvider);

    return TwoPane(
      primaryBuilder: (_) => const OverallStatistics(),
      secondaryBuilder: (_) => const Placeholder(),
      stackingStyleOnPortrait: StackingStyle.bottomSheet,
    );
  }
}
