import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class CustomerWishlist extends StatelessWidget {
  const CustomerWishlist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const AppbarTitle(title: "Customer Wishlist"),
        leading: AppbarBackButton(),
      ),
    );
  }
}
