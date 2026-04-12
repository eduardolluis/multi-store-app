import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/minor_screens/edit_product.dart';
import 'package:multi_store_app/minor_screens/manage_images.dart';
import 'package:multi_store_app/utilities/categ_list.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/product_form.dart';

class ManageProducts extends StatefulWidget {
  const ManageProducts({super.key});

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  String _searchQuery = '';
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FB),
        title: const AppbarTitle(title: 'Manage Products'),
        leading: const AppbarBackButton(),
      ),
      body: Column(
        children: [
          _SearchFilterBar(
            onSearch: (v) => setState(() => _searchQuery = v.toLowerCase()),
            selectedCategory: _filterCategory,
            onCategorySelected: (v) => setState(() => _filterCategory = v),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('cid', isEqualTo: _uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const _ErrorView();
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyProductsView();
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['productName'] ?? '').toString().toLowerCase();
                  final cat = (data['category'] ?? '').toString().toLowerCase();
                  final matchSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
                  final matchCat = _filterCategory == null || cat == _filterCategory!.toLowerCase();
                  return matchSearch && matchCat;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No products match your search.',
                      style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _ProductCard(docId: docs[index].id, data: data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search + filter bar ───────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const _SearchFilterBar({
    required this.onSearch,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                onChanged: onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: PopupMenuButton<String?>(
              onSelected: onCategorySelected,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: selectedCategory != null
                          ? const Color(0xFF111827)
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      selectedCategory ?? 'All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selectedCategory != null
                            ? const Color(0xFF111827)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('All categories')),
                ...maincateg.map(
                  (c) => PopupMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _ProductCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = (data['productName'] ?? 'Unnamed product').toString();
    final price = _toDouble(data['price']);
    final qty = _toInt(data['quantity']);
    final category = (data['category'] ?? 'Uncategorized').toString();
    final subcategory = (data['subcategory'] ?? '').toString();
    final images = data['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images[0].toString() : '';
    final discount = _toInt(data['discount']);
    final isLowStock = qty > 0 && qty <= 5;
    final isOutOfStock = qty == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumbnail(url: imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$category${subcategory.isNotEmpty ? ' › $subcategory' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          MiniChip(
                            label: '\$${price.toStringAsFixed(2)}',
                            color: const Color(0xFF111827),
                            textColor: Colors.white,
                          ),
                          if (discount > 0)
                            MiniChip(
                              label: '-$discount%',
                              color: const Color(0xFFFEF3C7),
                              textColor: const Color(0xFF92400E),
                            ),
                          if (isOutOfStock)
                            const MiniChip(
                              label: 'Out of stock',
                              color: Color(0xFFFEE2E2),
                              textColor: Color(0xFFDC2626),
                            )
                          else if (isLowStock)
                            MiniChip(
                              label: 'Low: $qty left',
                              color: const Color(0xFFFFF7ED),
                              textColor: const Color(0xFFEA580C),
                            )
                          else
                            MiniChip(
                              label: 'Stock: $qty',
                              color: const Color(0xFFDCFCE7),
                              textColor: const Color(0xFF166534),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                ProductActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProductScreen(docId: docId, data: data),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                ProductActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Images',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageImagesScreen(docId: docId, images: images),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                ProductActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  color: const Color(0xFFDC2626),
                  onTap: () => _confirmDelete(context, docId, name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete product', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('products').doc(docId).delete();
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String url;
  const _ProductThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 80,
        height: 80,
        color: const Color(0xFFF1F3F7),
        child: url.isEmpty
            ? const Icon(Icons.image_outlined, color: Colors.grey)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'Something went wrong',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  );
}
