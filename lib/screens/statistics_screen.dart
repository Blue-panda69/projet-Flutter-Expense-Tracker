import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.filteredExpenses;

    final byCategory = <ExpenseCategory, double>{};
    final byDay = <DateTime, double>{};

    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      final dayKey = DateTime(e.date.year, e.date.month, e.date.day);
      byDay[dayKey] = (byDay[dayKey] ?? 0) + e.amount;
    }

    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final highestCategory = byCategory.entries.isEmpty
        ? null
        : byCategory.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
          );
    final daysCount = byDay.length;
    final averageDaily = daysCount == 0 ? 0.0 : total / daysCount;

    final pieSections = byCategory.entries
        .map(
          (entry) => PieChartSectionData(
            title:
                '${_categoryLabel(entry.key)}\n${entry.value.toStringAsFixed(0)}',
            value: entry.value,
            radius: 60,
          ),
        )
        .toList();

    final sortedDays = byDay.keys.toList()..sort();
    final barSpots = sortedDays.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      final value = byDay[day]!;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 12,
          ),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Avg/day: ${averageDaily.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (highestCategory != null)
                Text(
                  'Highest category: ${_categoryLabel(highestCategory.key)} '
                  '(${highestCategory.value.toStringAsFixed(2)})',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 24),
              Text(
                'By Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: byCategory.isEmpty
                    ? const Center(child: Text('No data'))
                    : PieChart(
                        PieChartData(
                          sections: pieSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 0,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                'By Day',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: byDay.isEmpty
                    ? const Center(child: Text('No data'))
                    : BarChart(
                        BarChartData(
                          barGroups: barSpots,
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= sortedDays.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final day = sortedDays[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('${day.day}'),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _categoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}


