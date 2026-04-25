import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:multi_store_app/models/product_model.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';

import '../minor_screens/edit_store.dart';

class VisitStore extends StatefulWidget {
  final String supplierId;

  const VisitStore({super.key, required this.supplierId});

  @override
  State<VisitStore> createState() => _VisitStoreState();
}

class _VisitStoreState extends State<VisitStore> {
  bool following = false;

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> productsStream = FirebaseFirestore.instance
        .collection('products')
        .where("cid", isEqualTo: widget.supplierId)
        .snapshots();

    final Stream<DocumentSnapshot> supplierStream = FirebaseFirestore.instance
        .collection('suppliers')
        .doc(widget.supplierId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: supplierStream,
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Material(child: Center(child: Text("Something went wrong")));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Material(child: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return const Material(child: Center(child: Text("Document does not exist")));
        }

        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

        final currentUserId = FirebaseAuth.instance.currentUser!.uid;
        final bool isOwner = data['cid'] == currentUserId;

        return Scaffold(
          backgroundColor: Colors.grey.shade100,

          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            toolbarHeight: 150,
            leading: const YellowBackButton(),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(data['coverImage']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.70), Colors.black.withOpacity(0.25)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  height: 85,
                  width: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.network(data['storeLogo'], fit: BoxFit.cover),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['storeName'].toString().toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOwner ? Colors.amber : Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 5,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () {
                            if (isOwner) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditStore(data: data)),
                              );
                            } else {
                              setState(() {
                                following = !following;
                              });
                            }
                          },
                          icon: Icon(
                            isOwner
                                ? Icons.edit
                                : following
                                ? Icons.check_circle
                                : Icons.favorite_border,
                            size: 18,
                          ),
                          label: Text(
                            isOwner
                                ? "EDIT STORE"
                                : following
                                ? "FOLLOWING"
                                : "FOLLOW",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: productsStream,
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront, size: 65, color: Colors.blueGrey),
                          SizedBox(height: 15),
                          Text(
                            "This Store has no items yet!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Acme",
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: StaggeredGridView.countBuilder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
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

          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.green,
            elevation: 8,
            child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 35),
          ),
        );
      },
    );
  }
}
