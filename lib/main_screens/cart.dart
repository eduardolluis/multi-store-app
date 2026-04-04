import 'package:flutter/material.dart';
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  final Widget? back;
  const CartScreen({super.key, this.back});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            leading: widget.back,
            title: AppbarTitle(title: 'Cart'),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_forever, color: Colors.black),
              ),
            ],
          ),
          body: Consumer<Cart>(
            builder: (BuildContext context, cart, child) {
              return ListView.builder(
                itemCount: cart.count,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(cart.getItems[index].name));
                },
              );
            },
          ),
          bottomSheet: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text("Total: \$ ", style: TextStyle(fontSize: 18)),
                    Text(
                      "0.00",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                YellowButton(label: "CHECK OUT", width: 0.45, onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
