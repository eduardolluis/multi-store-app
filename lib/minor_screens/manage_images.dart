import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageImagesScreen extends StatefulWidget {
  final String docId;
  final List<dynamic> images;
  const ManageImagesScreen({super.key, required this.docId, required this.images});

  @override
  State<ManageImagesScreen> createState() => _ManageImagesScreenState();
}

class _ManageImagesScreenState extends State<ManageImagesScreen> {
  late List<String> _images;
  bool _uploading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _images = widget.images.map((e) => e.toString()).toList();
  }

  void _snack(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  Future<void> _addImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 600, maxHeight: 600);
    if (picked.isEmpty || !mounted) return;

    setState(() => _uploading = true);
    try {
      final supabase = Supabase.instance.client;
      final newUrls = <String>[];
      for (final img in picked) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final path = 'products/$fileName';
        await supabase.storage.from('products').upload(path, File(img.path));
        newUrls.add(supabase.storage.from('products').getPublicUrl(path));
      }
      final updated = [..._images, ...newUrls];
      await FirebaseFirestore.instance.collection('products').doc(widget.docId).update({
        'images': updated,
      });
      setState(() => _images = updated);
      _snack('${newUrls.length} image(s) added');
    } catch (_) {
      _snack('Upload failed');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeImage(int index) async {
    if (_images.length <= 1) {
      _snack('A product must have at least one image');
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
              itemBuilder: (context, index) => _ImageTile(
                url: _images[index],
                isMain: index == 0,
                onRemove: () => _removeImage(index),
              ),
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

class _ImageTile extends StatelessWidget {
  final String url;
  final bool isMain;
  final VoidCallback onRemove;
  const _ImageTile({required this.url, required this.isMain, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF1F3F7),
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
            ),
          ),
        ),
        if (isMain)
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
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
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
  }
}
