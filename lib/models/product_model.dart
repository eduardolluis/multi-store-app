import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/minor_screens/product_detail.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
import 'package:provider/provider.dart';

class ProductModel extends StatefulWidget {
  final dynamic products;
  const ProductModel({super.key, required this.products});

  @override
  State<ProductModel> createState() => _ProductModelState();
}

class _ProductModelState extends State<ProductModel> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailScreen(productList: widget.products),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Container(
                  constraints: BoxConstraints(minHeight: 100, maxHeight: 250),
                  child: Image(
                    image: NetworkImage(widget.products['images'][0]),
                  ),
                ),
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
                        Text(
                          widget.products['price'].toStringAsFixed(2) + ('\$'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        widget.products['cid'] ==
                                FirebaseAuth.instance.currentUser!.uid
                            ? IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                ),
                              )
                            : IconButton(
                                onPressed: () {
                                  context
                                              .read<Wish>()
                                              .getWishItems
                                              .firstWhereOrNull(
                                                (product) =>
                                                    product.documentId ==
                                                    widget
                                                        .products['productId'],
                                              ) !=
                                          null
                                      ? context.read<Wish>().removeThis(
                                          widget.products['productId'],
                                        )
                                      : context.read<Wish>().addWishItem(
                                          widget.products['productName'],
                                          widget.products['price'],
                                          1,
                                          widget.products['quantity'],
                                          widget.products['images'],
                                          widget.products['productId'],
                                          widget.products['cid'],
                                        );
                                },
                                icon:
                                    context
                                            .watch<Wish>()
                                            .getWishItems
                                            .firstWhereOrNull(
                                              (product) =>
                                                  product.documentId ==
                                                  widget.products['productId'],
                                            ) !=
                                        null
                                    ? const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 30,
                                      )
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
