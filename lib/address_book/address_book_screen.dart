import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/address_book/address_model.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

const List<Map<String, String>> kCountries = [
  {'name': 'United States', 'code': 'US'},
  {'name': 'Canada', 'code': 'CA'},
  {'name': 'United Kingdom', 'code': 'GB'},
  {'name': 'Australia', 'code': 'AU'},
  {'name': 'Germany', 'code': 'DE'},
  {'name': 'France', 'code': 'FR'},
  {'name': 'Spain', 'code': 'ES'},
  {'name': 'Italy', 'code': 'IT'},
  {'name': 'Netherlands', 'code': 'NL'},
  {'name': 'Brazil', 'code': 'BR'},
  {'name': 'Mexico', 'code': 'MX'},
  {'name': 'Argentina', 'code': 'AR'},
  {'name': 'Colombia', 'code': 'CO'},
  {'name': 'Chile', 'code': 'CL'},
  {'name': 'Dominican Republic', 'code': 'DO'},
  {'name': 'Japan', 'code': 'JP'},
  {'name': 'South Korea', 'code': 'KR'},
  {'name': 'China', 'code': 'CN'},
  {'name': 'India', 'code': 'IN'},
  {'name': 'Saudi Arabia', 'code': 'SA'},
  {'name': 'UAE', 'code': 'AE'},
  {'name': 'Egypt', 'code': 'EG'},
  {'name': 'South Africa', 'code': 'ZA'},
  {'name': 'Nigeria', 'code': 'NG'},
  {'name': 'Other', 'code': 'XX'},
];

String _flagEmoji(String code) {
  if (code == 'XX') return '🌐';
  return code.toUpperCase().split('').map((c) {
    return String.fromCharCode(c.codeUnitAt(0) + 0x1F1A5);
  }).join();
}

class AddressBookScreen extends StatelessWidget {
  final bool selectionMode;
  const AddressBookScreen({super.key, this.selectionMode = false});

  CollectionReference get _addressCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('customers').doc(uid).collection('addresses');
  }

  Future<void> _setDefault(String addressId, List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

  Future<void> _delete(
    BuildContext context,
    String addressId,
    bool wasDefault,
    List<QueryDocumentSnapshot> docs,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _addressCollection.doc(addressId).delete();

    if (wasDefault) {
      final remaining = docs.where((d) => d.id != addressId).toList();
      if (remaining.isNotEmpty) {
        await remaining.first.reference.update({'isDefault': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        leading: const AppbarBackButton(),
        title: AppbarTitle(title: selectionMode ? 'Select Address' : 'Address Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.black87),
            tooltip: 'Add address',
            onPressed: () => _openForm(context, null),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _addressCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _EmptyState(onAdd: () => _openForm(context, null));
          }

          final sorted = [...docs]
            ..sort((a, b) {
              final aDefault = (a.data() as Map)['isDefault'] == true;
              final bDefault = (b.data() as Map)['isDefault'] == true;
              if (aDefault && !bDefault) return -1;
              if (!aDefault && bDefault) return 1;
              return 0;
            });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final doc = sorted[i];
              final address = AddressModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

              return _AddressCard(
                address: address,
                selectionMode: selectionMode,
                onSelect: selectionMode ? () => Navigator.pop(context, address) : null,
                onEdit: () => _openForm(context, address),
                onDelete: () => _delete(context, address.id, address.isDefault, sorted),
                onSetDefault: address.isDefault ? null : () => _setDefault(address.id, sorted),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Address'),
        onPressed: () => _openForm(context, null),
      ),
    );
  }

  void _openForm(BuildContext context, AddressModel? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddressFormScreen(existing: existing)),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool selectionMode;
  final VoidCallback? onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _AddressCard({
    required this.address,
    required this.selectionMode,
    required this.onEdit,
    required this.onDelete,
    this.onSelect,
    this.onSetDefault,
  });

  IconData get _labelIcon {
    switch (address.label.toLowerCase()) {
      case 'work':
        return Icons.business_rounded;
      case 'other':
        return Icons.place_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selectionMode ? onSelect : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: address.isDefault
              ? Border.all(color: Colors.amber.shade700, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: address.isDefault ? Colors.amber.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _labelIcon,
                      size: 20,
                      color: address.isDefault ? Colors.amber.shade700 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    address.label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (address.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _flagEmoji(
                      kCountries.firstWhere(
                        (c) => c['name'] == address.country,
                        orElse: () => {'code': 'XX'},
                      )['code']!,
                    ),
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(Icons.person_outline_rounded, address.fullName),
              const SizedBox(height: 4),
              _InfoRow(Icons.phone_outlined, address.phone),
              const SizedBox(height: 4),
              _InfoRow(Icons.location_on_outlined, address.formattedAddress),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (onSetDefault != null)
                    _ActionChip(
                      icon: Icons.star_border_rounded,
                      label: 'Set Default',
                      onTap: onSetDefault!,
                      color: Colors.amber.shade700,
                    ),
                  const Spacer(),
                  _ActionChip(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: onEdit,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    onTap: onDelete,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No saved addresses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an address to speed up checkout',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  final AddressModel? existing;
  const AddressFormScreen({super.key, this.existing});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late String _selectedLabel;
  late String _selectedCountry;

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressLineCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _zipCtrl;
  late bool _isDefault;

  final List<String> _labels = ['Home', 'Work', 'Other'];


  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedLabel = e?.label ?? 'Home';
    _selectedCountry = e?.country.isNotEmpty == true ? e!.country : 'United States';
    _fullNameCtrl = TextEditingController(text: e?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _addressLineCtrl = TextEditingController(text: e?.addressLine ?? '');
    _cityCtrl = TextEditingController(text: e?.city ?? '');
    _stateCtrl = TextEditingController(text: e?.state ?? '');
    _zipCtrl = TextEditingController(text: e?.zipCode ?? '');
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressLineCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final custRef = FirebaseFirestore.instance.collection('customers').doc(uid);
      final addrCollection = custRef.collection('addresses');

      final newAddress = AddressModel(
        id: widget.existing?.id ?? '',
        label: _selectedLabel,
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        addressLine: _addressLineCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        zipCode: _zipCtrl.text.trim(),
        country: _selectedCountry,
        isDefault: _isDefault,
      );

      if (_isDefault) {
        final existing = await addrCollection.get();
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in existing.docs) {
          if (doc.id != (widget.existing?.id ?? '')) {
            batch.update(doc.reference, {'isDefault': false});
          }
        }
        await batch.commit();
      }

      if (widget.existing == null) {
        final existing = await addrCollection.get();
        final map = newAddress.toMap();
        if (existing.docs.isEmpty) map['isDefault'] = true;
        await addrCollection.add(map);
      } else {
        await addrCollection.doc(widget.existing!.id).update(newAddress.toMap());
      }

      if (_isDefault || widget.existing == null) {
        final snap = await addrCollection.get();
        if (snap.docs.isEmpty) {
          await custRef.update({'address': newAddress.formattedAddress});
        } else {
          final defaultDocs = snap.docs
              .where((d) => (d.data() as Map)['isDefault'] == true)
              .toList();
          final defaultDoc = defaultDocs.isNotEmpty ? defaultDocs.first : snap.docs.first;
          final defaultAddr = AddressModel.fromMap(
            defaultDoc.data(),
            defaultDoc.id,
          );
          await custRef.update({'address': defaultAddr.formattedAddress});
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving address: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showCountryPicker() {
    final controller = TextEditingController();
    List<Map<String, String>> filtered = [...kCountries];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Country',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Search country...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          filtered = kCountries
                              .where((c) => c['name']!.toLowerCase().contains(val.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final country = filtered[i];
                        final isSelected = country['name'] == _selectedCountry;
                        return ListTile(
                          leading: Text(
                            _flagEmoji(country['code']!),
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(country['name']!),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.amber)
                              : null,
                          tileColor: isSelected ? Colors.amber.withOpacity(0.08) : null,
                          onTap: () {
                            setState(() => _selectedCountry = country['name']!);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        leading: const AppbarBackButton(),
        title: AppbarTitle(title: isEditing ? 'Edit Address' : 'New Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _SectionHeader('Address Label'),
            Row(
              children: _labels.map((label) {
                final selected = _selectedLabel == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLabel = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? Colors.black87 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? Colors.black87 : Colors.grey.shade300),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _SectionHeader('Personal Info'),
            _FormField(
              controller: _fullNameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              validator: (v) => v == null || v.isEmpty ? 'Enter full name' : null,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 20),
            _SectionHeader('Address Details'),
            _FormField(
              controller: _addressLineCtrl,
              label: 'Street Address',
              icon: Icons.home_outlined,
              validator: (v) => v == null || v.isEmpty ? 'Enter street address' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    controller: _cityCtrl,
                    label: 'City',
                    icon: Icons.location_city_outlined,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    controller: _stateCtrl,
                    label: 'State / Province',
                    icon: Icons.map_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _FormField(
                    controller: _zipCtrl,
                    label: 'ZIP / Postal Code',
                    icon: Icons.markunread_mailbox_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _flagEmoji(
                              kCountries.firstWhere(
                                (c) => c['name'] == _selectedCountry,
                                orElse: () => {'code': 'XX'},
                              )['code']!,
                            ),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedCountry,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text(
                  'Set as default address',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Used automatically at checkout',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                activeColor: Colors.amber.shade700,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    isEditing ? 'Save Changes' : 'Save Address',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
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
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
