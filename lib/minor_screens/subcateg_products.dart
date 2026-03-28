import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class SubcategProducts extends StatelessWidget {
  final String maincategoryName;
  final String subcategoryName;
  const SubcategProducts({
    super.key,
    required this.subcategoryName,
    required this.maincategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const AppbarBackButton(),
        title: AppbarTitle(title: subcategoryName),
      ),
      body: Center(child: Text(maincategoryName)),
    );
  }
}
