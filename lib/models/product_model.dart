import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/minor_screens/product_detail.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
import 'package:provider/provider.dart';

// Helper: compute sale price from raw product map
double computeSalePrice(dynamic products) {
  final price = (products['price'] as num?)?.toDouble() ?? 0.0;
  final discount = (products['discount'] as num?)?.toInt() ?? 0;
  if (discount <= 0 || discount > 100) return price;
  return price * (1 - discount / 100);
}

class ProductModel extends StatefulWidget {
  final dynamic products;
  const ProductModel({super.key, required this.products});

  @override
  State<ProductModel> createState() => _ProductModelState();
}

class _ProductModelState extends State<ProductModel> {
  late var existingItemWishlist = context.read<Wish>().getWishItems.firstWhereOrNull(
    (product) => product.documentId == widget.products['productId'],
  );

  @override
  Widget build(BuildContext context) {
    final price = (widget.products['price'] as num?)?.toDouble() ?? 0.0;
    final discount = (widget.products['discount'] as num?)?.toInt() ?? 0;
    final salePrice = computeSalePrice(widget.products);
    final hasDiscount = discount > 0 && discount <= 100;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productList: widget.products),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 100, maxHeight: 250),
                      child: Image(image: NetworkImage(widget.products['images'][0])),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      widget.products['productName'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
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
                                '${price.toStringAsFixed(2)}\$',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '${salePrice.toStringAsFixed(2)}\$',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        widget.products['cid'] == FirebaseAuth.instance.currentUser!.uid
                            ? IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.edit, color: Colors.black),
                              )
                            : IconButton(
                                onPressed: () {
                                  existingItemWishlist != null
                                      ? context.read<Wish>().removeThis(
                                          widget.products['productId'],
                                        )
                                      : context.read<Wish>().addWishItem(
                                          widget.products['productName'],
                                          price,
                                          salePrice,
                                          1,
                                          widget.products['quantity'],
                                          widget.products['images'],
                                          widget.products['productId'],
                                          widget.products['cid'],
                                        );
                                },
                                icon:
                                    context.watch<Wish>().getWishItems.firstWhereOrNull(
                                          (product) =>
                                              product.documentId == widget.products['productId'],
                                        ) !=
                                        null
                                    ? const Icon(Icons.favorite, color: Colors.red, size: 30)
                                    : const Icon(
                                        Icons.favorite_outline,
                                        color: Colors.red,
                                        size: 30,
                                      ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
