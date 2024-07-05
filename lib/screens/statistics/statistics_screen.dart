import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_selection.dart';
import '../../providers/statistics.dart';
import '../../widgets/two_pane.dart';
import 'widgets/game_statistics_page.dart';
import 'widgets/overall_statistics_page.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedGameProvider.notifier).deselect();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to any change of statistics and update when necessary
    ref.watch(statisticsUpdaterProvider);

    return TwoPane(
      primaryBuilder: (_) => const OverallStatisticsPage(),
      secondaryBuilder: (_) => const GameStatisticsPage(),
      stackingStyleOnPortrait: StackingStyle.newPage,
    );
  }
}
