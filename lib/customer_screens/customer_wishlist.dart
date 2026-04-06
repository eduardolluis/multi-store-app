import 'package:flutter/material.dart';
import 'package:multi_store_app/models/wish_model.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
import 'package:multi_store_app/widgets/alert_dialog.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:provider/provider.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            leading: const AppbarBackButton(),
            backgroundColor: Colors.white,
            title: AppbarTitle(title: 'WishList'),
            actions: [
              context.watch<Wish>().getWishItems.isEmpty
                  ? const SizedBox()
                  : IconButton(
                      onPressed: () {
                        MyAlertDialog.showMyDialog(
                          context: context,
                          title: 'Clear Wishlist',
                          content:
                              'Are you sure you want to clear your wishlist?',
                          tabNo: () {
                            Navigator.pop(context);
                          },
                          tabYes: () {
                            context.read<Wish>().clearWishList();
                            Navigator.pop(context);
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.black,
                      ),
                    ),
            ],
          ),
          body: context.watch<Wish>().getWishItems.isNotEmpty
              ? WishItems()
              : EmptyWishlist(),
        ),
      ),
    );
  }
}

class EmptyWishlist extends StatelessWidget {
  const EmptyWishlist({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Your Wishlist Is Empty", style: TextStyle(fontSize: 30)),
        ],
      ),
    );
  }
}

class WishItems extends StatelessWidget {
  const WishItems({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Wish>(
      builder: (BuildContext context, wish, child) {
        return ListView.builder(
          itemCount: wish.count,
          itemBuilder: (context, index) {
            final product = wish.getWishItems[index];
            return WishListModel(product: product);
          },
        );
      },
    );
  }
}
