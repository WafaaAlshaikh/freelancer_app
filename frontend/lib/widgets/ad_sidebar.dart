import 'package:flutter/material.dart';
import 'ad_banner.dart';

class AdSidebar extends StatelessWidget {
  const AdSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Sponsored',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          AdBanner(
            placement: 'sidebar_top',
            height: 250,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),
          AdBanner(
            placement: 'sidebar_bottom',
            height: 250,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }
}
