import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/report_dataset.dart';

/// Bar chart: events by severity (Mild/Moderate/Severe)
class SeverityBarChart extends StatelessWidget {
  final ReportDataset ds;
  const SeverityBarChart({super.key, required this.ds});

  @override
  Widget build(BuildContext context) {
    final mild = ds.bySeverity['Mild'] ?? 0;
    final mod  = ds.bySeverity['Moderate'] ?? 0;
    final sev  = ds.bySeverity['Severe'] ?? 0;
    final maxY = [mild, mod, sev].fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Events by Severity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.6,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY.toDouble(),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      final label = switch (idx) { 0 => 'Mild', 1 => 'Moderate', _ => 'Severe' };
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(label, style: const TextStyle(fontSize: 12)),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: mild.toDouble())]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: mod.toDouble())]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: sev.toDouble())]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bar chart: events by behavior type (top N by frequency)
class TypeBarChart extends StatelessWidget {
  final ReportDataset ds;
  final int topN;
  const TypeBarChart({super.key, required this.ds, this.topN = 6});

  @override
  Widget build(BuildContext context) {
    final items = ds.byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = items.take(topN).toList();
    if (top.isEmpty) {
      return const Text('No behavior data to chart yet.');
    }
    final maxY = top.first.value.clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Events by Behavior Type', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.8,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY.toDouble(),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= top.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(top[idx].key, style: const TextStyle(fontSize: 10)),
                      );
                    },
                    reservedSize: 36,
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < top.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: top[i].value.toDouble()),
                  ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
