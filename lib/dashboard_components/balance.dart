import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class Balance extends StatelessWidget {
  const Balance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,

        elevation: 0,
        title: const AppbarTitle(title: "Balance"),
        leading: AppbarBackButton(),
      ),
    );
  }
}
