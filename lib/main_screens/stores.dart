import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/main_screens/visit_store.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const AppbarTitle(title: 'Stores'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('suppliers').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No stores yet',
                  style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                ),
              );
            }

            return GridView.builder(
              itemCount: snapshot.data!.docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: 25,
                crossAxisSpacing: 25,
                crossAxisCount: 2,
              ),
              itemBuilder: (context, index) {
                final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                // Support both 'cid' and 'sid' — old docs may have only one
                final supplierId = (data['cid'] ?? data['sid'] ?? '').toString();
                final storeName = (data['storeName'] ?? 'Store').toString();
                final storeLogo = (data['storeLogo'] ?? '').toString();

                if (supplierId.isEmpty) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VisitStore(supplierId: supplierId)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              height: 110,
                              width: 120,
                              child: Image.asset('images/inapp/store.jpg'),
                            ),
                            Positioned(
                              bottom: 28,
                              left: 10,
                              child: SizedBox(
                                height: 48,
                                width: 100,
                                child: storeLogo.isEmpty
                                    ? const Icon(Icons.store, color: Colors.blueGrey)
                                    : Image.network(
                                        storeLogo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.store, color: Colors.blueGrey),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          storeName,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'AkayaKanadaka',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
