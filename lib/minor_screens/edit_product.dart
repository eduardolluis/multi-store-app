import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/utilities/categ_list.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/product_form.dart';

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

  late final _nameCtrl = TextEditingController(text: widget.data['productName']?.toString() ?? '');
  late final _descCtrl = TextEditingController(
    text: widget.data['productDescription']?.toString() ?? '',
  );
  late final _priceCtrl = TextEditingController(text: widget.data['price']?.toString() ?? '');
  late final _qtyCtrl = TextEditingController(text: widget.data['quantity']?.toString() ?? '');
  late final _discCtrl = TextEditingController(text: widget.data['discount']?.toString() ?? '0');

  String? _mainCat;
  String? _subCat;

  List<String> get _subCategories => _subCatMap[_mainCat] ?? [];

  static final  _subCatMap = {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.docId).update({
        'productName': _nameCtrl.text.trim(),
        'productDescription': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
        'discount': int.tryParse(_discCtrl.text) ?? 0,
        'category': _mainCat,
        'subcategory': _subCat,
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
              _saving ? 'Saving...' : 'Save Changes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
