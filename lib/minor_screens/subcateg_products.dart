import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/models/product_model.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

class SubcategProducts extends StatefulWidget {
  final String maincategoryName;
  final String subcategoryName;
  const SubcategProducts({
    super.key,
    required this.subcategoryName,
    required this.maincategoryName,
  });

  @override
  State<SubcategProducts> createState() => _SubcategProductsState();
}

class _SubcategProductsState extends State<SubcategProducts> {
  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> productsStream = FirebaseFirestore.instance
        .collection('products')
        .where("category", isEqualTo: widget.maincategoryName)
        .where('subcategory', isEqualTo: widget.subcategoryName)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const AppbarBackButton(),
        title: AppbarTitle(title: widget.subcategoryName),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              staggeredTileBuilder: (index) => StaggeredTile.fit(1),
            ),
          );
        },
      ),
    );
  }
}
