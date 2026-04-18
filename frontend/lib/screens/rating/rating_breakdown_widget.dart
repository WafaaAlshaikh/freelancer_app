// lib/screens/rating/rating_breakdown_widget.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/rating_model.dart';

class RatingBreakdownWidget extends StatelessWidget {
  final RatingStats stats;

  const RatingBreakdownWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildDistributionChart(),
          const SizedBox(height: 20),
          if (stats.categoryAverages!.isNotEmpty) _buildCategoryAverages(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Rating Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                'Average Rating',
                stats.average.toStringAsFixed(1),
                '⭐',
              ),
              _summaryItem(
                'Total Reviews',
                stats.total.toString(),
                '📝',
              ),
              _summaryItem(
                'Positive Rate',
                '${((stats.distribution[4] ?? 0) + (stats.distribution[5] ?? 0)) * 100 ~/ stats.total}%',
                '👍',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, String icon) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDistributionChart() {
    final maxCount = stats.distribution.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxCount,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} ★',
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(5, (i) {
                  final rating = i + 1;
                  final count = stats.distribution[rating] ?? 0;
                  return BarChartGroupData(
                    x: rating,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: _getRatingColor(rating),
                        width: 30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final rating = i + 1;
              final count = stats.distribution[rating] ?? 0;
              final percentage = stats.total > 0 ? (count / stats.total * 100).toInt() : 0;
              return Column(
                children: [
                  Text(
                    '$rating ★',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(rating),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAverages() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Averages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...stats.categoryAverages!.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(entry.key, style: const TextStyle(fontSize: 13)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < entry.value.toInt() ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      )),
                      const SizedBox(width: 8),
                      Text(
                        entry.value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }
}