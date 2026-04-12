import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:multi_store_app/main_screens/cart.dart';
import 'package:multi_store_app/main_screens/visit_store.dart';
import 'package:multi_store_app/minor_screens/fullscreen_view.dart';
import 'package:multi_store_app/models/product_model.dart';
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/providers/wish_providers.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';
import 'package:provider/provider.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';
import 'package:badges/badges.dart' as badge;

class ProductDetailScreen extends StatefulWidget {
  final dynamic productList;
  const ProductDetailScreen({super.key, required this.productList});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final Stream<QuerySnapshot> productsStream = FirebaseFirestore.instance
      .collection('products')
      .where('category', isEqualTo: widget.productList['category'])
      .where('subCategory', isEqualTo: widget.productList['subCategory'])
      .snapshots();

  final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  late List<dynamic> imagesList = widget.productList['images'];

  @override
  Widget build(BuildContext context) {
    final price = (widget.productList['price'] as num?)?.toDouble() ?? 0.0;
    final discount = (widget.productList['discount'] as num?)?.toInt() ?? 0;
    final salePrice = computeSalePrice(widget.productList);
    final hasDiscount = discount > 0 && discount <= 100;

    var existingItemCart = context.read<Cart>().getItems.firstWhereOrNull(
      (product) => product.documentId == widget.productList['productId'],
    );

    return Material(
      child: SafeArea(
        child: ScaffoldMessenger(
          key: scaffoldKey,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenView(imagesList: imagesList),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Swiper(
                            pagination: const SwiperPagination(builder: SwiperPagination.fraction),
                            itemCount: imagesList.length,
                            itemBuilder: (context, index) {
                              return Image(image: NetworkImage(imagesList[index]));
                            },
                          ),
                        ),
                        Positioned(
                          left: 15,
                          top: 20,
                          child: CircleAvatar(
                            backgroundColor: Colors.yellow,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 15,
                          top: 20,
                          child: CircleAvatar(
                            backgroundColor: Colors.yellow,
                            child: IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
                          ),
                        ),
                        if (hasDiscount)
                          Positioned(
                            top: 20,
                            left: 70,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '-$discount%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productList['productName'],
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
                                  Row(
                                    children: [
                                      Text(
                                        'USD ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        '${price.toStringAsFixed(2)}\$',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                Row(
                                  children: [
                                    const Text(
                                      'USD ',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Text(
                                      '${salePrice.toStringAsFixed(2)}\$',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                var existingItemWishlist = context
                                    .read<Wish>()
                                    .getWishItems
                                    .firstWhereOrNull(
                                      (product) =>
                                          product.documentId == widget.productList['productId'],
                                    );
                                existingItemWishlist != null
                                    ? context.read<Wish>().removeThis(
                                        widget.productList['productId'],
                                      )
                                    : context.read<Wish>().addWishItem(
                                        widget.productList['productName'],
                                        price,
                                        salePrice,
                                        1,
                                        widget.productList['quantity'],
                                        widget.productList['images'],
                                        widget.productList['productId'],
                                        widget.productList['cid'],
                                      );
                              },
                              icon:
                                  context.watch<Wish>().getWishItems.firstWhereOrNull(
                                        (product) =>
                                            product.documentId == widget.productList['productId'],
                                      ) !=
                                      null
                                  ? const Icon(Icons.favorite, color: Colors.red, size: 30)
                                  : const Icon(Icons.favorite_outline, color: Colors.red, size: 30),
                            ),
                          ],
                        ),
                        widget.productList['quantity'] == 0
                            ? const Text(
                                'This Item is out of Stock',
                                style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                              )
                            : Text(
                                '${widget.productList['quantity']} Pieces available in stock',
                                style: const TextStyle(color: Colors.blueGrey, fontSize: 16),
                              ),
                        ProductDetailsLabel(label: '  Item Description  '),
                        Text(
                          widget.productList['productDescription'],
                          textScaleFactor: 1.1,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProductDetailsLabel(label: ' Similar Items '),
                  SizedBox(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: productsStream,
                      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'This category \n \n  has no items yet!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Acme',
                                letterSpacing: 1.5,
                              ),
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          child: StaggeredGridView.countBuilder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              return ProductModel(products: snapshot.data!.docs[index].data());
                            },
                            staggeredTileBuilder: (index) => StaggeredTile.fit(1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            bottomSheet: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VisitStore(supplierId: widget.productList['cid']),
                            ),
                          );
                        },
                        icon: const Icon(Icons.store),
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartScreen(back: AppbarBackButton()),
                            ),
                          );
                        },
                        icon: Padding(
                          padding: const EdgeInsets.all(2),
                          child: badge.Badge(
                            showBadge: context.read<Cart>().getItems.isEmpty ? false : true,
                            badgeStyle: const badge.BadgeStyle(badgeColor: Colors.yellow),
                            badgeContent: Text(
                              context.watch<Cart>().getItems.length.toString(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            child: const Icon(Icons.shopping_cart),
                          ),
                        ),
                      ),
                    ],
                  ),
                  YellowButton(
                    label: existingItemCart != null ? 'Added to cart' : 'ADD TO CART',
                    onPressed: () {
                      if (widget.productList['quantity'] == 0) {
                        MyMessageHandler.showSnackBar(scaffoldKey, 'This Item is out of Stock');
                      } else if (existingItemCart != null) {
                        MyMessageHandler.showSnackBar(scaffoldKey, 'This item already in cart');
                      } else {
                        context.read<Cart>().addItem(
                          widget.productList['productName'],
                          price,
                          salePrice,
                          1,
                          widget.productList['quantity'],
                          widget.productList['images'],
                          widget.productList['productId'],
                          widget.productList['cid'],
                        );
                      }
                    },
                    width: .55,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductDetailsLabel extends StatelessWidget {
  final String label;
  const ProductDetailsLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40, width: 50, child: Divider(color: Colors.yellow[900], thickness: 1)),
          Text(
            label,
            style: TextStyle(color: Colors.yellow[900], fontSize: 24, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 40, width: 50, child: Divider(color: Colors.yellow[900], thickness: 1)),
        ],
      ),
    );
  }
}
