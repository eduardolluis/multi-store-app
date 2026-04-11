import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/providers/product_class.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
import 'package:provider/provider.dart';

class WishListModel extends StatelessWidget {
  const WishListModel({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        color: Colors.white,
        child: SizedBox(
          height: 106,
          child: Row(
            children: [
              SizedBox(height: 100, width: 120, child: Image.network(product.imagesUrl[0])),
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
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  context.read<Wish>().removeItem(product);
                                },
                                icon: Icon(Icons.delete_forever),
                              ),
                              const SizedBox(width: 10),
                              context.watch<Cart>().getItems.firstWhereOrNull(
                                            (element) => element.documentId == product.documentId,
                                          ) !=
                                          null ||
                                      product.quantity == 0
                                  ? const SizedBox()
                                  : IconButton(
                                      onPressed: () {
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
                                      icon: Icon(Icons.add_shopping_cart),
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
  }
}
