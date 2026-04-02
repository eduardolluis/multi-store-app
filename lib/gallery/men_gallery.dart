import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/models/product_model.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

class MenGalleryScreen extends StatefulWidget {
  const MenGalleryScreen({super.key});

  @override
  State<MenGalleryScreen> createState() => _MenGalleryScreenState();
}

class _MenGalleryScreenState extends State<MenGalleryScreen> {
  final Stream<QuerySnapshot> _productsStream = FirebaseFirestore.instance
      .collection('products')
      .where("category", isEqualTo: 'men')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsStream,
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
              return ProductModel(products: snapshot.data!.docs[index].data());
            },
            staggeredTileBuilder: (index) => StaggeredTile.fit(1),
          ),
        );
      },
    );
  }
}
