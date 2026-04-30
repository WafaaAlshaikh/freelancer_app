// lib/screens/rating/rating_breakdown_widget.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/rating_model.dart';
import '../../theme/app_theme.dart';

class RatingBreakdownWidget extends StatelessWidget {
  final RatingStats stats;

  const RatingBreakdownWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context),
          const SizedBox(height: 20),
          _buildDistributionChart(context),
          const SizedBox(height: 20),
          if (stats.categoryAverages!.isNotEmpty)
            _buildCategoryAverages(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.purple.shade900.withOpacity(0.3),
                  Colors.blue.shade900.withOpacity(0.3),
                ]
              : [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            t.ratingSummary,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                context,
                t.averageRating,
                stats.average.toStringAsFixed(1),
                '⭐',
              ),
              _summaryItem(
                context,
                t.totalReviews,
                stats.total.toString(),
                '📝',
              ),
              _summaryItem(
                context,
                t.positiveRate,
                '${((stats.distribution[4] ?? 0) + (stats.distribution[5] ?? 0)) * 100 ~/ stats.total}%',
                '👍',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String label,
    String value,
    String icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionChart(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final maxCount = stats.distribution.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.ratingDistribution,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxCount,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} ★',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
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
              final percentage = stats.total > 0
                  ? (count / stats.total * 100).toInt()
                  : 0;
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
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAverages(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.categoryAverages,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.categoryAverages!.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < entry.value.toInt()
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return AppColors.success;
    if (rating == 3) return AppColors.warning;
    return AppColors.danger;
  }
}
