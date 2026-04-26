import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditBusiness extends StatefulWidget {
  const EditBusiness({super.key});

  @override
  State<EditBusiness> createState() => _EditBusinessState();
}

class _EditBusinessState extends State<EditBusiness> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  XFile? _logoFile;
  XFile? _coverFile;
  String _currentLogo = '';
  String _currentCover = '';

  final _picker = ImagePicker();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final snap = await FirebaseFirestore.instance.collection('suppliers').doc(_uid).get();
    if (!snap.exists) {
      setState(() => _loading = false);
      return;
    }
    final data = snap.data() as Map<String, dynamic>;
    _nameCtrl.text = data['storeName']?.toString() ?? '';
    _phoneCtrl.text = data['phone']?.toString() ?? '';
    _currentLogo = data['storeLogo']?.toString() ?? '';
    _currentCover = data['coverImage']?.toString() ?? '';
    setState(() => _loading = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _logoFile = picked);
  }

  Future<void> _pickCover() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 400,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _coverFile = picked);
  }

  Future<String?> _uploadImage(XFile file, String folder) async {
    final supabase = Supabase.instance.client;
    final fileName = '${folder}_${_uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('images').upload(fileName, File(file.path));
    return supabase.storage.from('images').getPublicUrl(fileName);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String logoUrl = _currentLogo;
      String coverUrl = _currentCover;

      if (_logoFile != null) {
        logoUrl = await _uploadImage(_logoFile!, 'logo') ?? logoUrl;
      }
      if (_coverFile != null) {
        coverUrl = await _uploadImage(_coverFile!, 'cover') ?? coverUrl;
      }

      await FirebaseFirestore.instance.collection('suppliers').doc(_uid).update({
        'storeName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'storeLogo': logoUrl,
        'coverImage': coverUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _snack('Business updated successfully');
      Navigator.pop(context);
    } catch (_) {
      _snack('Failed to save changes');
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
        title: const AppbarTitle(title: 'Edit Business'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Cover image ──────────────────────────────────────
                    _SectionCard(
                      title: 'Cover Image',
                      icon: Icons.image_rounded,
                      child: GestureDetector(
                        onTap: _coverFile == null ? _pickCover : null,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: _coverFile != null
                                    ? Image.file(File(_coverFile!.path), fit: BoxFit.cover)
                                    : _currentCover.isNotEmpty
                                    ? Image.network(
                                        _currentCover,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _emptyImagePlaceholder('Add cover image'),
                                      )
                                    : _emptyImagePlaceholder('Add cover image'),
                              ),
                            ),
                            // overlay buttons
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  _ImageActionBtn(
                                    icon: Icons.edit_rounded,
                                    label: 'Change',
                                    onTap: _pickCover,
                                  ),
                                  if (_coverFile != null) ...[
                                    const SizedBox(width: 6),
                                    _ImageActionBtn(
                                      icon: Icons.refresh_rounded,
                                      label: 'Reset',
                                      onTap: () => setState(() => _coverFile = null),
                                      color: Colors.orange,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_coverFile != null)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'New',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Store logo ───────────────────────────────────────
                    _SectionCard(
                      title: 'Store Logo',
                      icon: Icons.store_rounded,
                      child: Row(
                        children: [
                          // Logo preview
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _logoFile != null
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE5E7EB),
                                    width: _logoFile != null ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(19),
                                  child: _logoFile != null
                                      ? Image.file(File(_logoFile!.path), fit: BoxFit.cover)
                                      : _currentLogo.isNotEmpty
                                      ? Image.network(
                                          _currentLogo,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.store, size: 40, color: Colors.grey),
                                        )
                                      : const Icon(Icons.store, size: 40, color: Colors.grey),
                                ),
                              ),
                              if (_logoFile != null)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'New',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(width: 20),

                          // Buttons
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OutlineBtn(
                                icon: Icons.photo_library_rounded,
                                label: 'Change Logo',
                                onTap: _pickLogo,
                              ),
                              if (_logoFile != null) ...[
                                const SizedBox(height: 8),
                                _OutlineBtn(
                                  icon: Icons.refresh_rounded,
                                  label: 'Reset',
                                  onTap: () => setState(() => _logoFile = null),
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Store info ────────────────────────────────────────
                    _SectionCard(
                      title: 'Store Information',
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        children: [
                          _BusinessField(
                            controller: _nameCtrl,
                            label: 'Store Name',
                            icon: Icons.store_rounded,
                            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          _BusinessField(
                            controller: _phoneCtrl,
                            label: 'Phone Number',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
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

  Widget _emptyImagePlaceholder(String label) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF9CA3AF), size: 36),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

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
          child,
        ],
      ),
    );
  }
}

class _ImageActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ImageActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF111827),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF111827),
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _BusinessField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _BusinessField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
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
