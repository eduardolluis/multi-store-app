import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  CollectionReference customers = FirebaseFirestore.instance.collection(
    'customers',
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: customers.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text("Something went wrong");
            }

            if (snapshot.hasData && !snapshot.data!.exists) {
              return const Text("Document does not exist");
            }

            if (snapshot.connectionState == ConnectionState.done) {
              Map<String, dynamic> data =
                  snapshot.data!.data() as Map<String, dynamic>;
              return Material(
                color: Colors.grey[200],
                child: SafeArea(
                  child: Scaffold(
                    backgroundColor: Colors.grey[200],
                    appBar: AppBar(
                      elevation: 0,
                      centerTitle: true,
                      backgroundColor: Colors.grey[200],
                      leading: const AppbarBackButton(),
                      title: AppbarTitle(title: 'Place Order'),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                      child: Column(
                        children: [
                          Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    bottomSheet: Container(
                      color: Colors.grey[200],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: YellowButton(
                          label: 'Confirm',
                          onPressed: () {},
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Center(child: CircularProgressIndicator());
          },
    );
  }
}
