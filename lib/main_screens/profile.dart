import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/customer_screens/customer_orders.dart';
import 'package:multi_store_app/customer_screens/customer_wishlist.dart';
import 'package:multi_store_app/main_screens/cart.dart';
import 'package:multi_store_app/widgets/alert_dialog.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String documentId;
  const ProfileScreen({super.key, required this.documentId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CollectionReference customers = FirebaseFirestore.instance.collection('customers');
  CollectionReference anonymous = FirebaseFirestore.instance.collection('anonymous');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseAuth.instance.currentUser!.isAnonymous
          ? anonymous.doc(widget.documentId).get()
          : customers.doc(widget.documentId).get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text("Something went wrong");
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return const Text("Document does not exist");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          return Scaffold(
            backgroundColor: Colors.grey[300],
            body: Stack(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.yellow, Colors.brown]),
                  ),
                ),
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      centerTitle: true,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.white,
                      expandedHeight: 140,
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          return FlexibleSpaceBar(
                            title: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: constraints.biggest.height <= 120 ? 1 : 0,
                              child: const Text("Account", style: TextStyle(color: Colors.black)),
                            ),
                            background: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.yellow, Colors.brown]),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8, left: 30),
                                child: Row(
                                  children: [
                                    data['profileImage'] == ''
                                        ? const CircleAvatar(
                                            radius: 50,
                                            backgroundImage: AssetImage('images/inapp/guest.jpg'),
                                          )
                                        : CircleAvatar(
                                            radius: 50,
                                            backgroundImage: NetworkImage(data['profileImage']),
                                          ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 25),
                                      child: Text(
                                        data['name'] == ''
                                            ? "GUEST"
                                            : data['name'].toString().toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: MediaQuery.of(context).size.width * 0.9,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      bottomLeft: Radius.circular(30),
                                    ),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CartScreen(back: AppbarBackButton()),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      height: 40,
                                      width: MediaQuery.of(context).size.width * 0.2,
                                      child: const Center(
                                        child: Text(
                                          'Cart',
                                          style: TextStyle(color: Colors.yellow, fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  color: Colors.yellow,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => CustomerOrders()),
                                      );
                                    },
                                    child: SizedBox(
                                      height: 40,
                                      width: MediaQuery.of(context).size.width * 0.2,
                                      child: const Center(
                                        child: Text(
                                          'Orders',
                                          style: TextStyle(color: Colors.black54, fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(30),
                                      bottomRight: Radius.circular(30),
                                    ),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => WishListScreen()),
                                      );
                                    },
                                    child: SizedBox(
                                      height: 40,
                                      width: MediaQuery.of(context).size.width * 0.2,
                                      child: const Center(
                                        child: Text(
                                          'WishList',
                                          style: TextStyle(color: Colors.yellow, fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            color: Colors.grey[300],
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 150,
                                  child: Image(image: AssetImage('images/inapp/logo.jpg')),
                                ),
                                ProfileHeaderLabel(headerLabel: "  Account Info  "),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    height: 260,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        RepeatedListTile(
                                          title: 'Email Address',
                                          subtitle: data['email'] == ''
                                              ? 'Example@email.com'
                                              : data['email'].toString().toLowerCase(),
                                          icon: Icons.email,
                                        ),
                                        YellowDivider(),
                                        RepeatedListTile(
                                          title: 'Phone No.',
                                          subtitle: data['phone'] == ''
                                              ? '+1234567890'
                                              : data['phone'],
                                          icon: Icons.phone,
                                        ),
                                        YellowDivider(),
                                        RepeatedListTile(
                                          title: 'Address',
                                          subtitle: data['address'] == ''
                                              ? 'No. 123, ABC Street, City'
                                              : data['address'],
                                          icon: Icons.location_pin,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ProfileHeaderLabel(headerLabel: "  Account Settings  "),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    height: 260,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        // ── Edit Profile — now navigates ──
                                        RepeatedListTile(
                                          title: "Edit Profile",
                                          subtitle: "",
                                          icon: Icons.edit,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditProfileScreen(
                                                  documentId: widget.documentId,
                                                  currentData: data,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        YellowDivider(),
                                        RepeatedListTile(
                                          title: "Change Password",
                                          icon: Icons.lock,
                                          onPressed: () => _showChangePassword(context),
                                        ),
                                        YellowDivider(),
                                        RepeatedListTile(
                                          title: 'Log Out',
                                          icon: Icons.logout,
                                          onPressed: () async {
                                            MyAlertDialog.showMyDialog(
                                              context: context,
                                              title: "Log Out",
                                              content: "Are you sure you want to log out?",
                                              tabNo: () => Navigator.pop(context),
                                              tabYes: () async {
                                                await FirebaseAuth.instance.signOut();
                                                Navigator.pop(context);
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/welcome_screen',
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator(color: Colors.purple));
      },
    );
  }

  void _showChangePassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'New password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              final newPass = ctrl.text.trim();
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              await FirebaseAuth.instance.currentUser?.updatePassword(newPass);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Password updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Edit Profile Screen
// ══════════════════════════════════════════════════════════════════════════════

class EditProfileScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> currentData;
  const EditProfileScreen({super.key, required this.documentId, required this.currentData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final _nameCtrl = TextEditingController(text: widget.currentData['name']?.toString() ?? '');
  late final _phoneCtrl = TextEditingController(
    text: widget.currentData['phone']?.toString() ?? '',
  );
  late final _addressCtrl = TextEditingController(
    text: widget.currentData['address']?.toString() ?? '',
  );

  XFile? _imageFile;
  final _picker = ImagePicker();

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _imageFile = picked);
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final supabase = Supabase.instance.client;
    final fileName = 'profile_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('images').upload(fileName, File(_imageFile!.path));
    return supabase.storage.from('images').getPublicUrl(fileName);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? newImageUrl;
      if (_imageFile != null) {
        newImageUrl = await _uploadImage();
      }

      final updates = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      };
      if (newImageUrl != null) updates['profileImage'] = newImageUrl;

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.documentId)
          .update(updates);

      if (!mounted) return;
      _snack('Profile updated successfully');
      Navigator.pop(context);
    } catch (_) {
      _snack('Failed to update profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.currentData['profileImage']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FB),
        leading: const AppbarBackButton(),
        title: const AppbarTitle(title: 'Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Profile photo ──────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.purple.shade100,
                        backgroundImage: _imageFile != null
                            ? FileImage(File(_imageFile!.path)) as ImageProvider
                            : currentImage.isNotEmpty
                            ? NetworkImage(currentImage)
                            : const AssetImage('images/inapp/guest.jpg') as ImageProvider,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Change photo', style: TextStyle(color: Colors.purple)),
              ),

              const SizedBox(height: 16),

              // ── Fields ─────────────────────────────────────────────────
              _ProfileField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: _addressCtrl,
                label: 'Address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
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
              backgroundColor: Colors.purple,
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

// ── Profile field ──────────────────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
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
        labelStyle: const TextStyle(color: Colors.purple),
        prefixIcon: Icon(icon, color: Colors.purple),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.purple, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }
}

// ── Reusable widgets (same as before) ────────────────────────────────────────

class YellowDivider extends StatelessWidget {
  const YellowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Divider(color: Colors.yellow, thickness: 1.2),
    );
  }
}

class RepeatedListTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Function()? onPressed;
  const RepeatedListTile({
    super.key,
    required this.title,
    this.subtitle = "",
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: ListTile(title: Text(title), subtitle: Text(subtitle), leading: Icon(icon)),
    );
  }
}

class ProfileHeaderLabel extends StatelessWidget {
  final String headerLabel;
  const ProfileHeaderLabel({super.key, required this.headerLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40, width: 50, child: Divider(color: Colors.grey, thickness: 1)),
          Text(
            headerLabel,
            style: const TextStyle(color: Colors.grey, fontSize: 24, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 40, width: 50, child: Divider(color: Colors.grey, thickness: 1)),
        ],
      ),
    );
  }
}
