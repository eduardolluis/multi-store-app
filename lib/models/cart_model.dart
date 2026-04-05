import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/providers/product_class.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
import 'package:provider/provider.dart';

class CartModel extends StatelessWidget {
  const CartModel({super.key, required this.product, required this.cart});

  final Product product;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        color: Colors.white,
        child: SizedBox(
          height: 100,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.price.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          Container(
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                product.qty == 1
                                    ? IconButton(
                                        onPressed: () {
                                          showCupertinoModalPopup(
                                            context: context,
                                            builder: (BuildContext context) => CupertinoActionSheet(
                                              title: Text('Remove Item'),
                                              message: Text(
                                                'Are you sure you want to remove this item?',
                                              ),
                                              actions: <CupertinoActionSheetAction>[
                                                CupertinoActionSheetAction(
                                                  child: Text(
                                                    'Move to wishlist',
                                                  ),
                                                  onPressed: () async {
                                                    final alreadyInWish = context
                                                        .read<Wish>()
                                                        .getWishItems
                                                        .firstWhereOrNull(
                                                          (element) =>
                                                              element
                                                                  .documentId ==
                                                              product
                                                                  .documentId,
                                                        );

                                                    if (alreadyInWish == null) {
                                                      await context
                                                          .read<Wish>()
                                                          .addWishItem(
                                                            product.name,
                                                            product.price,
                                                            1,
                                                            product.quantity,
                                                            product.imagesUrl,
                                                            product.documentId,
                                                            product.supplierId,
                                                          );
                                                    }

                                                    context
                                                        .read<Cart>()
                                                        .removeItem(product);
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                                CupertinoActionSheetAction(
                                                  child: Text('Delete item'),
                                                  onPressed: () async {
                                                    context
                                                                .read<Wish>()
                                                                .getWishItems
                                                                .firstWhereOrNull(
                                                                  (element) =>
                                                                      element
                                                                          .documentId ==
                                                                      product
                                                                          .documentId,
                                                                ) !=
                                                            null
                                                        ? context
                                                              .read<Cart>()
                                                              .removeItem(
                                                                product,
                                                              )
                                                        : await context
                                                              .read<Wish>()
                                                              .addWishItem(
                                                                product.name,
                                                                product.price,
                                                                1,
                                                                product
                                                                    .quantity,
                                                                product
                                                                    .imagesUrl,
                                                                product
                                                                    .documentId,
                                                                product
                                                                    .supplierId,
                                                              );
                                                    context
                                                        .read<Cart>()
                                                        .removeItem(product);
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ],
                                              cancelButton: TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.delete_forever,
                                          size: 18,
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: () {
                                          cart.reduceByOne(product);
                                        },
                                        icon: Icon(
                                          FontAwesomeIcons.minus,
                                          size: 18,
                                        ),
                                      ),
                                Text(
                                  product.qty.toString(),
                                  style: product.qty == product.quantity
                                      ? TextStyle(
                                          color: Colors.red,
                                          fontSize: 20,
                                          fontFamily: 'Acme',
                                        )
                                      : TextStyle(
                                          fontSize: 20,
                                          fontFamily: 'Acme',
                                        ),
                                ),
                                IconButton(
                                  onPressed: product.qty == product.quantity
                                      ? null
                                      : () {
                                          cart.increment(product);
                                        },
                                  icon: Icon(FontAwesomeIcons.plus, size: 18),
                                ),
                              ],
                            ),
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
  }
}
