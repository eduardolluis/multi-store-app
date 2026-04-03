import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:multi_store_app/minor_screens/fullscreen_view.dart';
import 'package:multi_store_app/models/product_model.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic productList;
  const ProductDetailScreen({super.key, required this.productList});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late List<dynamic> imagesList = widget.productList['images'];

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: widget.productList['category'])
        .where('subCategory', isEqualTo: widget.productList['subCategory'])
        .snapshots();

    return Material(
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullScreenView(imagesList: imagesList),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: Swiper(
                          pagination: const SwiperPagination(
                            builder: SwiperPagination.fraction,
                          ),
                          itemCount: imagesList.length,
                          itemBuilder: (context, index) {
                            return Image(
                              image: NetworkImage(imagesList[index]),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 15,
                        top: 20,
                        child: CircleAvatar(
                          backgroundColor: Colors.yellow,
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.arrow_back_ios_new),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 15,
                        top: 20,
                        child: CircleAvatar(
                          backgroundColor: Colors.yellow,
                          child: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.share),
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
                          Row(
                            children: [
                              Text(
                                "USD ",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                widget.productList['price'].toStringAsFixed(2) +
                                    ('\$'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),

                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.favorite_border_outlined,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${widget.productList['quantity']} Pieces available in stock",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 16),
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
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot,
                        ) {
                          if (snapshot.hasError) {
                            return Text('Something went wrong');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                "This category \n \n  has no items yet!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Acme",
                                  letterSpacing: 1.5,
                                ),
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            child: StaggeredGridView.countBuilder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                return ProductModel(
                                  products: snapshot.data!.docs[index].data(),
                                );
                              },
                              staggeredTileBuilder: (index) =>
                                  StaggeredTile.fit(1),
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
                    IconButton(onPressed: () {}, icon: const Icon(Icons.store)),
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_cart),
                    ),
                  ],
                ),

                YellowButton(
                  label: 'ADD TO CART',
                  onPressed: () {},
                  width: .55,
                ),
              ],
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
          SizedBox(
            height: 40,
            width: 50,
            child: Divider(color: Colors.yellow[900], thickness: 1),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.yellow[900],
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 40,
            width: 50,
            child: Divider(color: Colors.yellow[900], thickness: 1),
          ),
        ],
      ),
    );
  }
}
