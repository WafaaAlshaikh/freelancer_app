import 'package:flutter/material.dart';
import 'package:freelancer_platform/screens/admin/coupons_management_tab.dart';
import 'package:freelancer_platform/screens/admin/plans_management_tab.dart';
import 'package:freelancer_platform/screens/admin/subscription_stats_tab.dart';
import '../../services/api_service.dart';
import '../../models/subscription_plan_model.dart';
import '../../models/coupon_model.dart';
import '../../models/subscription_stats_model.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Subscription Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff14A800),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            Tab(text: 'Plans', icon: Icon(Icons.subscriptions)),
            Tab(text: 'Coupons', icon: Icon(Icons.local_offer)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SubscriptionStatsTab(),
          PlansManagementTab(),
          CouponsManagementTab(),
        ],
      ),
    );
  }
}
