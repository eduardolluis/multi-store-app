import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

List<String> label = [
  'my store',
  'orders',
  'edit profile',
  'manage products',
  'balance',
  'statics',
];

List<IconData> icons = [
  Icons.store,
  Icons.shop_2_outlined,
  Icons.edit,
  Icons.settings,
  Icons.attach_money,
  Icons.show_chart,
];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppbarTitle(title: "Dashboard"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: GridView.count(
          mainAxisSpacing: 50,
          crossAxisSpacing: 50,
          crossAxisCount: 2,
          children: List.generate(6, (index) {
            return Card(
              elevation: 20,
              shadowColor: Colors.purpleAccent[200],
              color: Colors.blueGrey.withOpacity(0.7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(icons[index], color: Colors.yellowAccent, size: 50),
                  Text(
                    label[index].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.yellowAccent,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      fontFamily: 'Acme',
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
