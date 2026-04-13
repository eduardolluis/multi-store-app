import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  int _selectedValue = 1;
  bool _processing = false;

  late AnimationController _slideController;
  late AnimationController _successController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _successScaleAnim;
  late Animation<double> _successFadeAnim;

  bool _showSuccess = false;

  final CollectionReference _customers = FirebaseFirestore.instance.collection('customers');

  String? get _paypalClientId => dotenv.maybeGet('PAYPAL_CLIENT_ID');
  String? get _paypalSecretKey => dotenv.maybeGet('PAYPAL_SECRET_KEY');
  String? get _backendUrl => dotenv.maybeGet('BACKEND_URL');

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _successScaleAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _successController, curve: Curves.elasticOut));

    _successFadeAnim = CurvedAnimation(parent: _successController, curve: Curves.easeOut);

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _createOrders(
    Map<String, dynamic> customerData,
    Cart cart,
    String paymentMethod, {
    String? paymentIntentId,
  }) async {
    for (final item in cart.getItems) {
      final orderId = const Uuid().v4();

      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'cid': customerData['cid'],
        'custname': customerData['name'],
        'email': customerData['email'],
        'phone': customerData['phone'],
        'address': customerData['address'],
        'profileImage': customerData['profileImage'] ?? '',
        'sid': item.supplierId,
        'proid': item.documentId,
        'orderId': orderId,
        'ordername': item.name,
        'orderImage': item.imagesUrl[0],
        'orderqty': item.qty,
        'orderprice': item.qty * item.salePrice,
        'deliverystatus': 'preparing',
        'deliverydate': '',
        'orderdate': DateTime.now(),
        'paymentstatus': paymentMethod,
        if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
        'orderreview': false,
      });

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ref = FirebaseFirestore.instance.collection('products').doc(item.documentId);

        final snap = await tx.get(ref);
        final currentQty = (snap['quantity'] as num).toInt();

        tx.update(ref, {'quantity': currentQty - item.qty});
      });
    }
  }

  Future<void> _onPaymentSuccess(Cart cart) async {
    cart.clearCart();

    if (!mounted) return;

    setState(() {
      _processing = false;
      _showSuccess = true;
    });

    _successController.forward();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.popUntil(context, ModalRoute.withName('/customer_home'));
  }

  void _showError(String msg) {
    if (!mounted) return;

    setState(() => _processing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _payCash(Map<String, dynamic> customerData, Cart cart) async {
    await _createOrders(customerData, cart, 'cash on delivery');
    await _onPaymentSuccess(cart);
  }

  Future<void> _payWithCard(Map<String, dynamic> customerData, Cart cart, double totalPaid) async {
    try {
      final backendUrl = _backendUrl;

      if (backendUrl == null || backendUrl.isEmpty) {
        _showError('Falta BACKEND_URL en tu archivo .env');
        return;
      }

      final int amountInCents = (totalPaid * 100).round();

      final response = await http.post(
        Uri.parse('$backendUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amountInCents, 'currency': 'usd'}),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _showError(body['error']?.toString() ?? 'Could not initiate payment.');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final clientSecret = data['clientSecret'] as String?;
      final paymentIntentId = data['paymentIntentId'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        _showError('Stripe did not return a client secret.');
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Duck Store',
          style: ThemeMode.system,
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            name: CollectionMode.automatic,
            email: CollectionMode.automatic,
          ),
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF111827),
              background: Color(0xFFF5F7FB),
              componentBackground: Colors.white,
            ),
            shapes: PaymentSheetShape(borderRadius: 16, borderWidth: 1),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _createOrders(customerData, cart, 'card', paymentIntentId: paymentIntentId);

      await _onPaymentSuccess(cart);
    } on StripeException catch (e) {
      debugPrint(
        'StripeException: ${e.error.code} | ${e.error.localizedMessage ?? e.error.message}',
      );

      if (e.error.code == FailureCode.Canceled) {
        if (mounted) {
          setState(() => _processing = false);
        }
      } else {
        _showError('Payment failed: ${e.error.localizedMessage ?? e.error.message}');
      }
    } catch (e, s) {
      debugPrint('Unexpected Stripe error: $e');
      debugPrintStack(stackTrace: s);
      _showError('Unexpected error. Please try again.');
    }
  }

  Future<void> _payWithPayPal(
    Map<String, dynamic> customerData,
    Cart cart,
    double totalPaid,
    double totalPrice,
  ) async {
    final clientId = _paypalClientId;
    final secretKey = _paypalSecretKey;

    if (clientId == null || clientId.isEmpty || secretKey == null || secretKey.isEmpty) {
      _showError('Faltan PAYPAL_CLIENT_ID o PAYPAL_SECRET_KEY en tu archivo .env');
      return;
    }

    if (!mounted) return;

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext checkoutContext) => PaypalCheckoutView(
            sandboxMode: true,
            clientId: clientId,
            secretKey: secretKey,
            transactions: [
              {
                "amount": {
                  "total": totalPaid.toStringAsFixed(2),
                  "currency": "USD",
                  "details": {
                    "subtotal": totalPrice.toStringAsFixed(2),
                    "shipping": '10.00',
                    "shipping_discount": 0,
                  },
                },
                "description": "Duck Store Purchase",
                "item_list": {
                  "items": cart.getItems.map((item) {
                    return {
                      "name": item.name,
                      "quantity": item.qty,
                      "price": item.salePrice.toStringAsFixed(2),
                      "currency": "USD",
                    };
                  }).toList(),
                },
              },
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (Map params) async {
              await _createOrders(
                customerData,
                cart,
                'paypal',
                paymentIntentId: params['paymentId']?.toString(),
              );

              await _onPaymentSuccess(cart);
            },
            onError: (error) {
              Navigator.of(checkoutContext).pop();
              _showError('PayPal error: $error');
            },
            onCancel: () {
              Navigator.of(checkoutContext).pop();
              if (mounted) {
                setState(() => _processing = false);
              }
            },
          ),
        ),
      );
    } catch (e) {
      _showError('Unexpected PayPal error. Please try again.');
    }
  }

  Future<void> _handlePayment(
    Map<String, dynamic> customerData,
    Cart cart,
    double totalPaid,
    double totalPrice,
  ) async {
    setState(() => _processing = true);

    switch (_selectedValue) {
      case 1:
        await _payCash(customerData, cart);
        break;
      case 2:
        await _payWithCard(customerData, cart, totalPaid);
        break;
      case 3:
        await _payWithPayPal(customerData, cart, totalPaid, totalPrice);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();
    final totalPrice = cart.totalPrice;
    final totalPaid = totalPrice + 10.0;

    if (_showSuccess) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: Center(
          child: ScaleTransition(
            scale: _successScaleAnim,
            child: FadeTransition(
              opacity: _successFadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Order Placed!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your order is being prepared.',
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _customers.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: const Color(0xFFF5F7FB),
            leading: const AppbarBackButton(),
            title: const AppbarTitle(title: 'Payment'),
          ),
          body: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(label: 'Order Summary'),
                  const SizedBox(height: 10),
                  _SummaryCard(totalPrice: totalPrice, totalPaid: totalPaid),
                  const SizedBox(height: 22),
                  const _SectionLabel(label: 'Delivering To'),
                  const SizedBox(height: 10),
                  _DeliveryCard(data: data),
                  const SizedBox(height: 22),
                  const _SectionLabel(label: 'Payment Method'),
                  const SizedBox(height: 10),
                  _PaymentOption(
                    value: 1,
                    groupValue: _selectedValue,
                    onChanged: (v) => setState(() => _selectedValue = v!),
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when your order arrives',
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFD1FAE5),
                  ),
                  const SizedBox(height: 10),
                  _PaymentOption(
                    value: 2,
                    groupValue: _selectedValue,
                    onChanged: (v) => setState(() => _selectedValue = v!),
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, Mastercard & more — powered by Stripe',
                    icon: Icons.credit_card_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFDBEAFE),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        FaIcon(FontAwesomeIcons.ccVisa, color: Color(0xFF1A1F71), size: 22),
                        SizedBox(width: 8),
                        FaIcon(FontAwesomeIcons.ccMastercard, color: Color(0xFFEB001B), size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PaymentOption(
                    value: 3,
                    groupValue: _selectedValue,
                    onChanged: (v) => setState(() => _selectedValue = v!),
                    title: 'PayPal',
                    subtitle: 'Fast and secure checkout',
                    icon: FontAwesomeIcons.paypal,
                    iconColor: const Color(0xFF003087),
                    iconBg: const Color(0xFFDBEAFE),
                    isFaIcon: true,
                    trailing: const FaIcon(
                      FontAwesomeIcons.ccPaypal,
                      color: Color(0xFF009CDE),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PaymentMethodNote(selectedValue: _selectedValue),
                ],
              ),
            ),
          ),
          bottomSheet: _ConfirmButton(
            processing: _processing,
            selectedValue: _selectedValue,
            totalPaid: totalPaid,
            onPressed: () => _handlePayment(data, context.read<Cart>(), totalPaid, totalPrice),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalPrice;
  final double totalPaid;

  const _SummaryCard({required this.totalPrice, required this.totalPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          _SummaryRow(
            label: 'Subtotal',
            value: '\$${totalPrice.toStringAsFixed(2)}',
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            valueStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const _SummaryRow(
            label: 'Shipping',
            value: '\$10.00',
            labelStyle: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            valueStyle: TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFF3F4F6), thickness: 1.5),
          ),
          _SummaryRow(
            label: 'Total',
            value: '\$${totalPaid.toStringAsFixed(2)}',
            labelStyle: const TextStyle(
              fontSize: 18,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
            valueStyle: const TextStyle(
              fontSize: 18,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DeliveryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.location_on_rounded, color: Color(0xFF7C3AED), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['name'] ?? 'Guest').toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (data['address'] ?? 'No address set').toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if ((data['phone'] ?? '').toString().isNotEmpty)
                  Text(
                    data['phone'].toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool processing;
  final int selectedValue;
  final double totalPaid;
  final VoidCallback onPressed;

  const _ConfirmButton({
    required this.processing,
    required this.selectedValue,
    required this.totalPaid,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    String label;

    if (selectedValue == 1) {
      label = 'Place Order — Cash on Delivery';
    } else if (selectedValue == 2) {
      label = 'Pay \$${totalPaid.toStringAsFixed(2)} with Card';
    } else {
      label = 'Pay \$${totalPaid.toStringAsFixed(2)} with PayPal';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: processing ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF111827),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: processing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final int value;
  final int groupValue;
  final ValueChanged<int?> onChanged;
  final String title;
  final String subtitle;
  final dynamic icon;
  final Color iconColor;
  final Color iconBg;
  final bool isFaIcon;
  final Widget? trailing;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isFaIcon = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF111827).withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: RadioListTile<int>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFF111827),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: isFaIcon
                  ? FaIcon(icon, color: iconColor, size: 18)
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFF111827) : const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodNote extends StatelessWidget {
  final int selectedValue;

  const _PaymentMethodNote({required this.selectedValue});

  @override
  Widget build(BuildContext context) {
    final notes = {
      1: (
        Icons.info_outline_rounded,
        const Color(0xFF10B981),
        const Color(0xFFD1FAE5),
        'Your order will be processed immediately. Pay when your package arrives.',
      ),
      2: (
        Icons.lock_rounded,
        const Color(0xFF3B82F6),
        const Color(0xFFDBEAFE),
        'Your payment is 100% secure. Stripe encrypts all card data.',
      ),
      3: (
        FontAwesomeIcons.shieldHalved,
        const Color(0xFF003087),
        const Color(0xFFDBEAFE),
        'You will complete payment via PayPal securely.',
      ),
    };

    final note = notes[selectedValue];
    if (note == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: note.$3, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(note.$1, color: note.$2, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note.$4,
              style: TextStyle(fontSize: 13, color: note.$2, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}
