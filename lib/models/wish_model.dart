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
    final hasDiscount = product.salePrice < product.price;

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount)
                                Text(
                                  product.price.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                product.salePrice.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.read<Wish>().removeItem(product),
                                icon: const Icon(Icons.delete_forever),
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
                                          product.salePrice,
                                          1,
                                          product.quantity,
                                          product.imagesUrl,
                                          product.documentId,
                                          product.supplierId,
                                        );
                                      },
                                      icon: const Icon(Icons.add_shopping_cart),
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
