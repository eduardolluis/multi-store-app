import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/address_book/address_book_screen.dart';
import 'package:multi_store_app/address_book/address_model.dart';
import 'package:multi_store_app/minor_screens/payment_screen.dart';
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';
import 'package:provider/provider.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final CollectionReference _customers = FirebaseFirestore.instance.collection('customers');

  CollectionReference get _addressCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('customers').doc(uid).collection('addresses');
  }

  AddressModel? _selectedAddress;

  Future<AddressModel?> _fetchDefaultAddress() async {
    final snap = await _addressCollection.where('isDefault', isEqualTo: true).limit(1).get();

    if (snap.docs.isNotEmpty) {
      return AddressModel.fromMap(
        snap.docs.first.data() as Map<String, dynamic>,
        snap.docs.first.id,
      );
    }

    final fallback = await _addressCollection.limit(1).get();
    if (fallback.docs.isNotEmpty) {
      return AddressModel.fromMap(
        fallback.docs.first.data() as Map<String, dynamic>,
        fallback.docs.first.id,
      );
    }

    return null;
  }

  Future<void> _pickAddress() async {
    final chosen = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddressBookScreen(selectionMode: true)),
    );
    if (chosen != null) {
      setState(() => _selectedAddress = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalPrice = context.watch<Cart>().totalPrice;

    return FutureBuilder<DocumentSnapshot>(
      future: _customers.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder: (context, custSnapshot) {
        if (custSnapshot.connectionState == ConnectionState.waiting) {
          return const Material(child: Center(child: CircularProgressIndicator()));
        }

        if (!custSnapshot.hasData || !custSnapshot.data!.exists) {
          return const Material(child: Center(child: Text('User not found')));
        }

        final customerData = custSnapshot.data!.data() as Map<String, dynamic>;

        return FutureBuilder<AddressModel?>(
          future: _selectedAddress == null ? _fetchDefaultAddress() : null,
          builder: (context, addrSnapshot) {
            final address = _selectedAddress ?? addrSnapshot.data;
            final bool isLoadingAddr =
                _selectedAddress == null && addrSnapshot.connectionState == ConnectionState.waiting;

            return Material(
              color: Colors.grey[200],
              child: SafeArea(
                child: Scaffold(
                  backgroundColor: Colors.grey[200],
                  appBar: AppBar(
                    elevation: 0,
                    centerTitle: true,
                    backgroundColor: Colors.grey[200],
                    leading: const AppbarBackButton(),
                    title: const AppbarTitle(title: 'Place Order'),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DeliverySection(
                          isLoading: isLoadingAddr,
                          address: address,
                          customerData: customerData,
                          onChangeTap: _pickAddress,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Consumer<Cart>(
                              builder: (context, cart, _) {
                                return ListView.builder(
                                  itemCount: cart.count,
                                  itemBuilder: (context, index) {
                                    final order = cart.getItems[index];
                                    return Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Container(
                                        height: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(width: 0.4),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(15),
                                                bottomLeft: Radius.circular(15),
                                              ),
                                              child: SizedBox(
                                                height: 100,
                                                width: 100,
                                                child: Image.network(order.imagesUrl[0]),
                                              ),
                                            ),
                                            Flexible(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  Text(
                                                    order.name,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 12,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          order.price.toStringAsFixed(2),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                        Text(
                                                          ' x${order.qty}',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.grey[600],
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
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottomSheet: Container(
                    color: Colors.grey[200],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: YellowButton(
                        label: 'Confirm \$${totalPrice.toStringAsFixed(2)} USD',
                        width: 1,
                        onPressed: () {
                          if (address == null) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text('No Delivery Address'),
                                content: const Text(
                                  'Please add a delivery address before placing your order.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black87,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AddressBookScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('Add Address'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                selectedAddress: address,
                                customerData: customerData,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Delivery Section ──────────────────────────────────────────────────────────

class _DeliverySection extends StatelessWidget {
  final bool isLoading;
  final AddressModel? address;
  final Map<String, dynamic> customerData;
  final VoidCallback onChangeTap;

  const _DeliverySection({
    required this.isLoading,
    required this.address,
    required this.customerData,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: address != null
            ? Border.all(color: Colors.amber.shade200, width: 1.5)
            : Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : address == null
            ? _NoAddressContent(onAddTap: onChangeTap)
            : _AddressContent(address: address!, onChangeTap: onChangeTap),
      ),
    );
  }
}

class _NoAddressContent extends StatelessWidget {
  final VoidCallback onAddTap;
  const _NoAddressContent({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_off_rounded, color: Colors.red, size: 28),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'No delivery address found.\nPlease add one.',
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: onAddTap,
          child: const Text('Add', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}

class _AddressContent extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onChangeTap;

  const _AddressContent({required this.address, required this.onChangeTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 6),
            Text(
              'Delivering to — ${address.label}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onChangeTap,
              child: const Text(
                'Change',
                style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(address.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(address.formattedAddress, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(address.phone, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
}
