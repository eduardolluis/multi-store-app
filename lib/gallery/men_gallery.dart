import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MenGalleryScreen extends StatefulWidget {
  const MenGalleryScreen({super.key});

  @override
  State<MenGalleryScreen> createState() => _MenGalleryScreenState();
}

class _MenGalleryScreenState extends State<MenGalleryScreen> {
  final Stream<QuerySnapshot> _productsStream = FirebaseFirestore.instance
      .collection('products')
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
          return Text("Loading");
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            return ListTile(
              leading: Image(image: NetworkImage(data['images'][0])),
              title: Text(data['productName']),
              subtitle: Text(data['price'].toString()),
            );
          }).toList(),
        );
      },
    );
  }
}
