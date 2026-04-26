import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/utilities/categ_list.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/product_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const EditProductScreen({super.key, required this.docId, required this.data});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _uploadingImages = false;

  // ── Text controllers ──
  late final _nameCtrl = TextEditingController(text: widget.data['productName']?.toString() ?? '');
  late final _descCtrl = TextEditingController(
    text: widget.data['productDescription']?.toString() ?? '',
  );
  late final _priceCtrl = TextEditingController(text: widget.data['price']?.toString() ?? '');
  late final _qtyCtrl = TextEditingController(text: widget.data['quantity']?.toString() ?? '');
  late final _discCtrl = TextEditingController(text: widget.data['discount']?.toString() ?? '0');

  // ── Category state ──
  String? _mainCat;
  String? _subCat;

  // ── Images state ──
  late List<String> _existingImages;
  final List<XFile> _newImageFiles = [];
  final _picker = ImagePicker();

  List<String> get _subCategories => _subCatMap[_mainCat] ?? [];

  static final _subCatMap = {
    'men': men,
    'women': women,
    'electronics': electronics,
    'accessories': accessories,
    'shoes': shoes,
    'home & garden': homeandgarden,
    'beauty': beauty,
    'kids': kids,
    'bags': bags,
  };

  @override
  void initState() {
    super.initState();
    _mainCat = widget.data['category']?.toString();
    _subCat = widget.data['subcategory']?.toString();
    _existingImages = List<String>.from(widget.data['images'] ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ── Image helpers ──────────────────────────────────────────────────────────

  Future<void> _pickNewImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 600, maxHeight: 600);
    if (picked.isEmpty) return;
    setState(() => _newImageFiles.addAll(picked));
  }

  void _removeExistingImage(int index) {
    if (_existingImages.length + _newImageFiles.length <= 1) {
      _snack('A product must have at least one image');
      return;
    }
    setState(() => _existingImages.removeAt(index));
  }

  void _removeNewImage(int index) {
    if (_existingImages.length + _newImageFiles.length <= 1) {
      _snack('A product must have at least one image');
      return;
    }
    setState(() => _newImageFiles.removeAt(index));
  }

  Future<List<String>> _uploadNewImages() async {
    if (_newImageFiles.isEmpty) return [];
    final supabase = Supabase.instance.client;
    final urls = <String>[];
    for (final img in _newImageFiles) {
      final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${img.name}';
      await supabase.storage.from('products').upload(fileName, File(img.path));
      urls.add(supabase.storage.from('products').getPublicUrl(fileName));
    }
    return urls;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      // ── Lesson 150 Challenge: ownership verification ──
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _snack('Not logged in');
        return;
      }

      final ref = FirebaseFirestore.instance.collection('products').doc(widget.docId);
      final snap = await ref.get();

      if (!snap.exists) {
        _snack('Product not found');
        return;
      }

      final docData = snap.data() as Map<String, dynamic>;
      if (docData['cid'] != uid) {
        _snack('You do not own this product');
        return;
      }
      // ── End ownership check ──

      // Upload newly picked images to Supabase
      setState(() => _uploadingImages = true);
      final newUrls = await _uploadNewImages();
      setState(() => _uploadingImages = false);

      final allImages = [..._existingImages, ...newUrls];

      await ref.update({
        'productName': _nameCtrl.text.trim(),
        'productDescription': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
        'discount': int.tryParse(_discCtrl.text) ?? 0,
        'category': _mainCat,
        'subcategory': _subCat,
        'images': allImages,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _snack('Product updated successfully');
      Navigator.pop(context);
    } catch (_) {
      _snack('Failed to update product');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalImages = _existingImages.length + _newImageFiles.length;

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Images section ──────────────────────────────────────────
              _SectionCard(
                title: 'Product Images',
                icon: Icons.photo_library_rounded,
                trailing: _uploadingImages
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF111827)),
                      )
                    : TextButton.icon(
                        onPressed: _pickNewImages,
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF111827),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                child: totalImages == 0
                    ? GestureDetector(
                        onTap: _pickNewImages,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: Color(0xFF9CA3AF),
                                  size: 32,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Tap to add images',
                                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Existing images from Firestore
                            ..._existingImages.asMap().entries.map((e) {
                              return _ImageThumb(
                                isMain: e.key == 0,
                                isNew: false,
                                child: Image.network(e.value, fit: BoxFit.cover),
                                onRemove: () => _removeExistingImage(e.key),
                              );
                            }),
                            // Newly picked local images
                            ..._newImageFiles.asMap().entries.map((e) {
                              return _ImageThumb(
                                isMain: _existingImages.isEmpty && e.key == 0,
                                isNew: true,
                                child: Image.file(File(e.value.path), fit: BoxFit.cover),
                                onRemove: () => _removeNewImage(e.key),
                              );
                            }),
                            // Add-more button
                            GestureDetector(
                              onTap: _pickNewImages,
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFF9CA3AF),
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 14),

              // ── Basic info ──────────────────────────────────────────────
              FormSection(
                title: 'Basic Info',
                icon: Icons.info_outline_rounded,
                children: [
                  ProductFormField(
                    controller: _nameCtrl,
                    label: 'Product Name',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ProductFormField(
                    controller: _descCtrl,
                    label: 'Description',
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Pricing & stock ─────────────────────────────────────────
              FormSection(
                title: 'Pricing & Stock',
                icon: Icons.attach_money_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ProductFormField(
                          controller: _priceCtrl,
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
                        child: ProductFormField(
                          controller: _qtyCtrl,
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
                  ProductFormField(
                    controller: _discCtrl,
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

              // ── Category ────────────────────────────────────────────────
              FormSection(
                title: 'Category',
                icon: Icons.category_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    value: _mainCat,
                    decoration: dropdownDecor('Main Category'),
                    items: maincateg
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c[0].toUpperCase() + c.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _mainCat = v;
                      _subCat = null;
                    }),
                    validator: (v) => v == null ? 'Select a category' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _subCategories.contains(_subCat) ? _subCat : null,
                    decoration: dropdownDecor('Sub Category'),
                    items: _subCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _subCat = v),
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
              _saving ? (_uploadingImages ? 'Uploading images...' : 'Saving...') : 'Save Changes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Image thumbnail ────────────────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  final bool isMain;
  final bool isNew;
  final Widget child;
  final VoidCallback onRemove;

  const _ImageThumb({
    required this.isMain,
    required this.isNew,
    required this.child,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMain ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
              width: isMain ? 2 : 1,
            ),
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(13), child: child),
        ),
        if (isMain)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Main',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (isNew)
          Positioned(
            bottom: 4,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'New',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section card with optional trailing ────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.icon, required this.child, this.trailing});

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
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
 