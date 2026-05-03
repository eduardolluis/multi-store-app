import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:multi_store_app/models/product_model.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';
import 'package:url_launcher/url_launcher.dart';

import '../minor_screens/edit_store.dart';

class VisitStore extends StatefulWidget {
  final String supplierId;
  const VisitStore({super.key, required this.supplierId});

  @override
  State<VisitStore> createState() => _VisitStoreState();
}

class _VisitStoreState extends State<VisitStore> {
  bool _following = false;
  bool _loadingFollow = true;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // ── WhatsApp store phone number ─────────────────────────────────────────────
  static const String _storeWhatsApp = '8495191571';

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    if (_currentUserId == null) {
      setState(() => _loadingFollow = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(_currentUserId)
          .collection('following')
          .doc(widget.supplierId)
          .get();
      if (mounted) {
        setState(() {
          _following = doc.exists;
          _loadingFollow = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFollow = false);
    }
  }

  Future<void> _toggleFollow(String storeName) async {
    if (_currentUserId == null) return;

    final followRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(_currentUserId)
        .collection('following')
        .doc(widget.supplierId);

    final supplierRef = FirebaseFirestore.instance.collection('suppliers').doc(widget.supplierId);

    if (_following) {
      // Unfollow
      await followRef.delete();
      await supplierRef.update({'followersCount': FieldValue.increment(-1)}).catchError((_) async {
        // field might not exist yet, ignore
      });
      if (mounted) setState(() => _following = false);
    } else {
      // Follow
      await followRef.set({
        'storeId': widget.supplierId,
        'storeName': storeName,
        'followedAt': FieldValue.serverTimestamp(),
      });
      await supplierRef.set({'followersCount': FieldValue.increment(1)}, SetOptions(merge: true));
      if (mounted) setState(() => _following = true);
    }
  }

  Future<void> _openWhatsApp() async {
    // Remove any non-digit chars and build wa.me URL
    final phone = _storeWhatsApp.replaceAll(RegExp(r'\D'), '');
    // Include country code for Dominican Republic (+1-809/829/849)
    final fullPhone = phone.startsWith('1') ? phone : '1$phone';
    final uri = Uri.parse('https://wa.me/$fullPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try whatsapp scheme
        final fallback = Uri.parse('whatsapp://send?phone=$fullPhone');
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('cid', isEqualTo: widget.supplierId)
        .snapshots();

    final Stream<DocumentSnapshot> supplierStream = FirebaseFirestore.instance
        .collection('suppliers')
        .doc(widget.supplierId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: supplierStream,
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Material(child: Center(child: Text('Something went wrong')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Material(child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Material(child: Center(child: Text('Store not found')));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final storeOwnerId = (data['sid'] ?? data['cid'] ?? '').toString();
        final bool isOwner = currentUserId.isNotEmpty && storeOwnerId == currentUserId;

        final coverImage = (data['coverImage'] ?? '').toString();
        final storeLogo = (data['storeLogo'] ?? '').toString();
        final storeName = (data['storeName'] ?? 'Store').toString();

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            toolbarHeight: 150,
            leading: const YellowBackButton(),
            flexibleSpace: _CoverBackground(coverImage: coverImage),
            title: Row(
              children: [
                _StoreLogo(url: storeLogo),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName.toUpperCase(),
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
                        child: isOwner
                            ? ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  elevation: 5,
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => EditStore(data: data)),
                                ),
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text(
                                  'EDIT STORE',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              )
                            : _loadingFollow
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _following
                                      ? Colors.green.shade600
                                      : Colors.white,
                                  foregroundColor: _following ? Colors.white : Colors.black,
                                  elevation: 5,
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () => _toggleFollow(storeName),
                                icon: Icon(
                                  _following ? Icons.check_circle : Icons.favorite_border,
                                  size: 18,
                                ),
                                label: Text(
                                  _following ? 'FOLLOWING' : 'FOLLOW',
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                            'This Store has no items yet!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Acme',
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
                    staggeredTileBuilder: (_) => StaggeredTile.fit(1),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openWhatsApp,
            backgroundColor: const Color(0xFF25D366),
            elevation: 8,
            tooltip: 'Chat on WhatsApp',
            child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 35),
          ),
        );
      },
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _CoverBackground extends StatelessWidget {
  final String coverImage;
  const _CoverBackground({required this.coverImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800,
        image: coverImage.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(coverImage),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : null,
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
    );
  }
}

class _StoreLogo extends StatelessWidget {
  final String url;
  const _StoreLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      width: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
        color: Colors.white24,
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
        child: url.isEmpty
            ? const Icon(Icons.store, color: Colors.white54, size: 40)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.store, color: Colors.white54, size: 40),
              ),
      ),
    );
  }
}
