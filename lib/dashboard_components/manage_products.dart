import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/utilities/categ_list.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          // ── Search & Filter bar ─────────────────────────────────
          Padding(
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
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
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
                // Category filter
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: PopupMenuButton<String?>(
                    onSelected: (val) => setState(() => _filterCategory = val),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: _filterCategory != null
                                ? const Color(0xFF111827)
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _filterCategory ?? 'All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _filterCategory != null
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
                        (c) => PopupMenuItem(
                          value: c,
                          child: Text(c[0].toUpperCase() + c.substring(1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Product list ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('cid', isEqualTo: _uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _EmptyProductsView();
                }

                // Apply search + category filter
                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['productName'] ?? '').toString().toLowerCase();
                  final cat = (data['category'] ?? '').toString().toLowerCase();

                  final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
                  final matchesCategory =
                      _filterCategory == null || cat == _filterCategory!.toLowerCase();

                  return matchesSearch && matchesCategory;
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

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _ProductCard({required this.docId, required this.data});

  String _readString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final t = v.toString().trim();
    return t.isEmpty ? fallback : t;
  }

  double _readDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final name = _readString(data['productName'], 'Unnamed product');
    final price = _readDouble(data['price']);
    final qty = _readInt(data['quantity']);
    final category = _readString(data['category'], 'Uncategorized');
    final subcategory = _readString(data['subcategory'], '');
    final images = data['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images[0].toString() : '';
    final discount = _readInt(data['discount']);
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
          // ── Main row ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF1F3F7),
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.image_outlined, color: Colors.grey)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined, color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
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
                          _MiniChip(
                            label: '\$${price.toStringAsFixed(2)}',
                            color: const Color(0xFF111827),
                            textColor: Colors.white,
                          ),
                          if (discount > 0)
                            _MiniChip(
                              label: '-$discount%',
                              color: const Color(0xFFFEF3C7),
                              textColor: const Color(0xFF92400E),
                            ),
                          isOutOfStock
                              ? _MiniChip(
                                  label: 'Out of stock',
                                  color: const Color(0xFFFEE2E2),
                                  textColor: const Color(0xFFDC2626),
                                )
                              : isLowStock
                              ? _MiniChip(
                                  label: 'Low: $qty left',
                                  color: const Color(0xFFFFF7ED),
                                  textColor: const Color(0xFFEA580C),
                                )
                              : _MiniChip(
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

          // ── Action buttons ──
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _EditProductScreen(docId: docId, data: data),
                      ),
                    );
                  },
                ),
                Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                _ActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Images',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _ManageImagesScreen(docId: docId, images: images),
                      ),
                    );
                  },
                ),
                Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                _ActionButton(
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
}

// ── Edit Product Screen ───────────────────────────────────────────────────────

class _EditProductScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _EditProductScreen({required this.docId, required this.data});

  @override
  State<_EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<_EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _discountController;

  String? _mainCategory;
  String? _subCategory;

  List<String> get _subCategories {
    switch (_mainCategory) {
      case 'men':
        return men;
      case 'women':
        return women;
      case 'electronics':
        return electronics;
      case 'accessories':
        return accessories;
      case 'shoes':
        return shoes;
      case 'home & garden':
        return homeandgarden;
      case 'beauty':
        return beauty;
      case 'kids':
        return kids;
      case 'bags':
        return bags;
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['productName']?.toString() ?? '');
    _descController = TextEditingController(
      text: widget.data['productDescription']?.toString() ?? '',
    );
    _priceController = TextEditingController(text: widget.data['price']?.toString() ?? '');
    _qtyController = TextEditingController(text: widget.data['quantity']?.toString() ?? '');
    _discountController = TextEditingController(text: widget.data['discount']?.toString() ?? '0');
    _mainCategory = widget.data['category']?.toString();
    _subCategory = widget.data['subcategory']?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.docId).update({
        'productName': _nameController.text.trim(),
        'productDescription': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'quantity': int.tryParse(_qtyController.text) ?? 0,
        'discount': int.tryParse(_discountController.text) ?? 0,
        'category': _mainCategory,
        'subcategory': _subCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FB),
        leading: const AppbarBackButton(),
        title: const AppbarTitle(title: 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _Section(
                title: 'Basic Info',
                icon: Icons.info_outline_rounded,
                children: [
                  _Field(
                    controller: _nameController,
                    label: 'Product Name',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _descController,
                    label: 'Description',
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'Pricing & Stock',
                icon: Icons.attach_money_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _priceController,
                          label: 'Price (USD)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          controller: _qtyController,
                          label: 'Quantity',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            if (int.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _discountController,
                    label: 'Discount (%)',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 100) return 'Enter 0-100';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'Category',
                icon: Icons.category_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    value: _mainCategory,
                    decoration: _dropDecor('Main Category'),
                    items: maincateg.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c[0].toUpperCase() + c.substring(1)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() {
                      _mainCategory = v;
                      _subCategory = null;
                    }),
                    validator: (v) => v == null ? 'Select a category' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _subCategories.contains(_subCategory) ? _subCategory : null,
                    decoration: _dropDecor('Sub Category'),
                    items: _subCategories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (v) => setState(() => _subCategory = v),
                    validator: (v) => v == null ? 'Select a subcategory' : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: const Color(0xFFF5F7FB),
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _saving ? 'Saving...' : 'Save Changes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Manage Images Screen ──────────────────────────────────────────────────────

class _ManageImagesScreen extends StatefulWidget {
  final String docId;
  final List<dynamic> images;

  const _ManageImagesScreen({required this.docId, required this.images});

  @override
  State<_ManageImagesScreen> createState() => _ManageImagesScreenState();
}

class _ManageImagesScreenState extends State<_ManageImagesScreen> {
  late List<String> _images;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _images = widget.images.map((e) => e.toString()).toList();
  }

  Future<void> _addImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 600, maxHeight: 600);
    if (picked.isEmpty || !mounted) return;

    setState(() => _uploading = true);

    try {
      final supabase = Supabase.instance.client;
      final newUrls = <String>[];

      for (final img in picked) {
        final file = File(img.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final path = 'products/$fileName';
        await supabase.storage.from('products').upload(path, file);
        newUrls.add(supabase.storage.from('products').getPublicUrl(path));
      }

      final updated = [..._images, ...newUrls];
      await FirebaseFirestore.instance.collection('products').doc(widget.docId).update({
        'images': updated,
      });

      setState(() => _images = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newUrls.length} image(s) added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeImage(int index) async {
    if (_images.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A product must have at least one image'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updated = List<String>.from(_images)..removeAt(index);
    await FirebaseFirestore.instance.collection('products').doc(widget.docId).update({
      'images': updated,
    });

    setState(() => _images = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FB),
        leading: const AppbarBackButton(),
        title: const AppbarTitle(title: 'Product Images'),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              ),
            )
          else
            IconButton(
              onPressed: _addImages,
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.black),
              tooltip: 'Add images',
            ),
        ],
      ),
      body: _images.isEmpty
          ? const Center(child: Text('No images yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _images[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F3F7),
                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Main badge
                    if (index == 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Main',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Delete button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _addImages,
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Add Images', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _MiniChip({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF374151),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF111827)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
      ),
    );
  }
}

InputDecoration _dropDecor(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5),
    ),
  );
}

class _EmptyProductsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inventory_2_outlined, size: 82, color: Color(0xFF9CA3AF)),
            SizedBox(height: 14),
            Text(
              'No products yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF374151)),
            ),
            SizedBox(height: 8),
            Text(
              'Your uploaded products will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
