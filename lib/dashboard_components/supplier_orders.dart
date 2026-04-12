import 'package:flutter/material.dart';
import 'package:multi_store_app/dashboard_components/delivered_order.dart';
import 'package:multi_store_app/dashboard_components/preparing_order.dart';
import 'package:multi_store_app/dashboard_components/shipping_order.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class SupplierOrders extends StatelessWidget {
  const SupplierOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          title: const AppbarTitle(title: "Orders"),
          bottom: TabBar(
            indicatorColor: Colors.yellow,
            indicatorWeight: 8,
            tabs: [
              RepeatedTab(label: 'Pending'),
              RepeatedTab(label: 'Shipping'),
              RepeatedTab(label: 'Delivered'),
            ],
          ),
          leading: AppbarBackButton(),
        ),
        body: TabBarView(children: [Preparing(), Shipping(), Delivered()]),
      ),
    );
  }
}

class RepeatedTab extends StatelessWidget {
  final String label;
  const RepeatedTab({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Center(
        child: Text(label, style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
