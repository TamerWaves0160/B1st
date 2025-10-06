import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/behavior.dart';

Color getColor(String type) {
  switch (type) {
    case 'On-task':
      return Colors.green;
    case 'Off-task':
      return Colors.red;
    case 'Disruptive':
      return Colors.orange;
    case 'Participating':
      return Colors.blue;
    case 'Unresponsive':
      return Colors.grey;
    default:
      return Colors.teal;
  }
}

class BehaviorChart extends StatefulWidget {
  final List<Behavior> behaviors;

  const BehaviorChart({super.key, required this.behaviors});

  @override
  State<BehaviorChart> createState() => _BehaviorChartState();
}

class _BehaviorChartState extends State<BehaviorChart> {
  String? selectedType;

  List<Behavior> get filteredBehaviors {
    if (selectedType == null) return widget.behaviors;
    return widget.behaviors.where((b) => b.type == selectedType).toList();
  }

  Map<String, double> get aggregatedData {
    final data = <String, double>{};
    for (var behavior in filteredBehaviors) {
      if (behavior.date != null) {
        data.update(behavior.date!, (value) => value + behavior.duration,
            ifAbsent: () => behavior.duration.toDouble());
      }
    }
    return data;
  }

  Widget buildLegend() {
    final legendItems = {
      'On-task': Colors.green,
      'Off-task': Colors.red,
      'Disruptive': Colors.orange,
      'Participating': Colors.blue,
      'Unresponsive': Colors.grey,
    };

    return Wrap(
      spacing: 12,
      children: legendItems.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: entry.value),
            const SizedBox(width: 4),
            Text(entry.key),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartData = aggregatedData;
    final groupData = chartData.entries.map((entry) {
      final date = entry.key;
      final totalDuration = entry.value;
      final behaviorsOnDate =
          filteredBehaviors.where((b) => b.date == date).toList();

      final barRods = behaviorsOnDate.map((behavior) {
        return BarChartRodData(
          toY: behavior.duration.toDouble(),
          color: getColor(behavior.type ?? ''),
          width: 16,
        );
      }).toList();

      return BarChartGroupData(
        x: chartData.keys.toList().indexOf(date),
        barRods: [
          BarChartRodData(
            toY: totalDuration,
            rodStackItems: barRods
                .map((rod) => BarChartRodStackItem(
                    0, rod.toY, rod.color ?? Colors.transparent))
                .toList(),
            width: 16,
          )
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          hint: const Text('Filter by behavior'),
          value: selectedType,
          items: <String>[
            'On-task',
            'Off-task',
            'Disruptive',
            'Participating',
            'Unresponsive',
          ].map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList()
            ..insert(
                0, const DropdownMenuItem(value: null, child: Text('All'))),
          onChanged: (value) {
            setState(() {
              selectedType = value;
            });
          },
        ),
        const SizedBox(height: 12),
        buildLegend(),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Builder(builder: (context) {
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: groupData,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}m');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < chartData.keys.length) {
                              return Text(chartData.keys.elementAt(index));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}