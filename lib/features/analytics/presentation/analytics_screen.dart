import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progress analytics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AnalyticsView(kind: _AnalyticsKind.weekly),
            _AnalyticsView(kind: _AnalyticsKind.monthly),
          ],
        ),
      ),
    );
  }
}

enum _AnalyticsKind { weekly, monthly }

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView({required this.kind});

  final _AnalyticsKind kind;

  List<double> get _cravings => kind == _AnalyticsKind.weekly ? [4, 3, 2, 3, 2, 1, 1] : [7, 6, 5, 5, 4, 3, 2, 2, 2, 1, 1, 1];
  List<double> get _cigs => kind == _AnalyticsKind.weekly ? [6, 8, 10, 9, 11, 12, 14] : [30, 35, 38, 40, 44, 48, 52, 55, 60, 66, 70, 78];
  List<double> get _money => kind == _AnalyticsKind.weekly ? [5, 10, 18, 25, 32, 40, 50] : [30, 60, 90, 120, 150, 190, 230, 270, 320, 370, 430, 500];
  List<double> get _streak => kind == _AnalyticsKind.weekly ? [1, 2, 3, 4, 5, 6, 7] : [7, 10, 14, 18, 22, 28, 34, 40, 50, 60, 70, 82];

  String get _labelSuffix => kind == _AnalyticsKind.weekly ? 'day' : 'wk';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          _ChartCard(
            title: 'Cravings per ${kind == _AnalyticsKind.weekly ? 'day' : 'week'}',
            color: AppColors.primary,
            data: _cravings,
            labelBuilder: (i) => '${i + 1}$_labelSuffix',
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Cigarettes avoided',
            color: Colors.teal,
            data: _cigs,
            labelBuilder: (i) => '${i + 1}$_labelSuffix',
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Money saved',
            color: Colors.orange,
            data: _money,
            labelBuilder: (i) => '${i + 1}$_labelSuffix',
            valuePrefix: '4',
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Streak history',
            color: Colors.purple,
            data: _streak,
            labelBuilder: (i) => '${i + 1}$_labelSuffix',
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.color,
    required this.data,
    required this.labelBuilder,
    this.valuePrefix = '',
  });

  final String title;
  final Color color;
  final List<double> data;
  final String Function(int) labelBuilder;
  final String valuePrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = [
      for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Animated', style: theme.textTheme.bodySmall?.copyWith(color: color)),
              ),
            ],
          ),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                lineTouchData: LineTouchData(handleBuiltInTouches: true),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labelBuilder(index), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.10),
                    ),
                    dotData: FlDotData(show: true),
                    spots: spots,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${valuePrefix.isNotEmpty ? valuePrefix : ''}${data.isNotEmpty ? data.last.toStringAsFixed(0) : ''} latest',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
