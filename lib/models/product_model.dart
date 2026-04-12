import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/minor_screens/product_detail.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
import 'package:provider/provider.dart';

// ── Sale price helper (shared across the app) ─────────────────────────────────
double computeSalePrice(dynamic products) {
  final price = (products['price'] as num?)?.toDouble() ?? 0.0;
  final discount = (products['discount'] as num?)?.toInt() ?? 0;
  if (discount <= 0 || discount > 100) return price;
  return price * (1 - discount / 100);
}

class ProductModel extends StatelessWidget {
  final dynamic products;
  const ProductModel({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final price = (products['price'] as num?)?.toDouble() ?? 0.0;
    final discount = (products['discount'] as num?)?.toInt() ?? 0;
    final salePrice = computeSalePrice(products);
    final hasDiscount = discount > 0 && discount <= 100;
    final isOwner = products['cid'] == FirebaseAuth.instance.currentUser?.uid;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productList: products)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              // ── Image + discount badge ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 100, maxHeight: 250),
                      child: Image(image: NetworkImage(products['images'][0])),
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

              // ── Name + price + wishlist ──
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      products['productName'],
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
                        // ── Price display ──
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

                        // ── Wishlist / edit button ──
                        isOwner
                            ? IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.edit, color: Colors.black),
                              )
                            : _WishlistButton(
                                productId: products['productId'],
                                productName: products['productName'],
                                price: price,
                                salePrice: salePrice,
                                quantity: (products['quantity'] as num?)?.toInt() ?? 0,
                                images: products['images'],
                                supplierId: products['cid'],
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

// ── Extracted wishlist button avoids stale state on list rebuilds ─────────────
class _WishlistButton extends StatelessWidget {
  final String productId;
  final String productName;
  final double price;
  final double salePrice;
  final int quantity;
  final dynamic images;
  final String supplierId;

  const _WishlistButton({
    required this.productId,
    required this.productName,
    required this.price,
    required this.salePrice,
    required this.quantity,
    required this.images,
    required this.supplierId,
  });

  @override
  Widget build(BuildContext context) {
    final inWishlist =
        context.watch<Wish>().getWishItems.firstWhereOrNull((p) => p.documentId == productId) !=
        null;

    return IconButton(
      onPressed: () {
        if (inWishlist) {
          context.read<Wish>().removeThis(productId);
        } else {
          context.read<Wish>().addWishItem(
            productName,
            price, // original price stored for display/strikethrough
            salePrice, // actual price paid — passed to cart from wish
            1,
            quantity,
            images,
            productId,
            supplierId,
          );
        }
      },
      icon: Icon(inWishlist ? Icons.favorite : Icons.favorite_outline, color: Colors.red, size: 30),
    );
  }
}
