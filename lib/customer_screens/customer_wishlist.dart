import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
import 'package:multi_store_app/widgets/alert_dialog.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';
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
              context.watch<Cart>().getItems.isEmpty
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
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: Card(
                color: Colors.white,
                child: SizedBox(
                  height: 106,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 100,
                        width: 120,
                        child: Image.network(product.imagesUrl[0]),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    product.price.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          context.read<Wish>().removeItem(
                                            product,
                                          );
                                        },
                                        icon: Icon(Icons.delete_forever),
                                      ),
                                      const SizedBox(width: 10),
                                      context
                                                  .watch<Cart>()
                                                  .getItems
                                                  .firstWhereOrNull(
                                                    (element) =>
                                                        element.documentId ==
                                                        product.documentId,
                                                  ) !=
                                              null
                                          ? const SizedBox()
                                          : IconButton(
                                              onPressed: () {
                                                // context
                                                //             .read<Cart>()
                                                //             .getItems
                                                //             .firstWhereOrNull(
                                                //               (element) =>
                                                //                   element
                                                //                       .documentId ==
                                                //                   product
                                                //                       .documentId,
                                                //             ) !=
                                                //         null
                                                //     // ignore: avoid_print
                                                //     ? print('Already in cart')
                                                //     : context
                                                context.read<Cart>().addItem(
                                                  product.name,
                                                  product.price,
                                                  1,
                                                  product.quantity,
                                                  product.imagesUrl,
                                                  product.documentId,
                                                  product.supplierId,
                                                );
                                              },
                                              icon: Icon(
                                                Icons.add_shopping_cart,
                                              ),
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
