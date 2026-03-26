import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          double fill;
          
          if (rating >= starValue) {
            fill = 1;
          } else if (rating > index && rating < starValue) {
            fill = rating - index;
          } else {
            fill = 0;
          }
          
          return SizedBox(
            width: size,
            height: size,
            child: Icon(
              fill >= 0.5 ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: size,
            ),
          );
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}