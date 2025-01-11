import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionModal extends StatefulWidget {
  final Map<dynamic, dynamic> magazineData;
  final double basePrice;
  final String? existingSubscriptionKey;

  const SubscriptionModal({
    super.key,
    required this.magazineData,
    required this.basePrice,
    this.existingSubscriptionKey,
  });

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  String _selectedPeriod = '1_month'; // Default selection
  bool _showDetails = false;
  late Razorpay _razorpay;
  String? _appliedCouponCode;
  double? _couponDiscount;
  bool _isValidatingCoupon = false;
  final TextEditingController _couponController = TextEditingController();

  final Map<String, Map<String, dynamic>> _subscriptionOptions = {
    '1_month': {
      'label': '1 Month',
      'multiplier': 1,
      'discount': 0,
    },
    '6_months': {
      'label': '6 Months',
      'multiplier': 6,
      'discount': 0.1, // 10% discount
    },
    '1_year': {
      'label': '1 Year',
      'multiplier': 12,
      'discount': 0.2, // 20% discount
    },
  };

  double _calculateIssuesCount(String period) {
    final option = _subscriptionOptions[period]!;
    final monthlyIssues = _getMonthlyIssues();
    return option['multiplier'] * monthlyIssues;
  }

  double _getMonthlyIssues() {
    final frequency =
        widget.magazineData['frequency']?.toLowerCase() ?? 'monthly';
    switch (frequency) {
      case 'weekly':
        return 4.0;
      case 'bi-weekly':
        return 2.0;
      case 'monthly':
        return 1.0;
      case 'quarterly':
        return 1 / 3;
      case 'bi-monthly':
        return 0.5;
      default:
        return 1.0;
    }
  }

  double _calculatePrice(String period) {
    final option = _subscriptionOptions[period]!;
    final issuesCount = _calculateIssuesCount(period);
    final baseTotal = widget.basePrice * issuesCount;
    final subscriptionDiscount = baseTotal * option['discount'];
    final withSubscriptionDiscount = baseTotal - subscriptionDiscount;

    if (_couponDiscount != null) {
      final couponDiscountAmount = withSubscriptionDiscount * _couponDiscount!;
      return withSubscriptionDiscount - couponDiscountAmount;
    }

    return withSubscriptionDiscount;
  }

  Widget _buildPriceDetails(String period) {
    final option = _subscriptionOptions[period]!;
    final issuesCount = _calculateIssuesCount(period);
    final originalPrice = widget.basePrice * issuesCount;
    final finalPrice = _calculatePrice(period);
    final discount = option['discount'] * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Applied Coupon Display
        if (_appliedCouponCode != null)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appliedCouponCode!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(_couponDiscount! * 100).toInt()}% discount (-₹${(finalPrice * _couponDiscount!).toStringAsFixed(2)})',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _appliedCouponCode = null;
                      _couponDiscount = null;
                      _couponController.clear();
                    });
                  },
                ),
              ],
            ),
          ),

        // Price Breakdown
        _buildPriceRow('Subtotal', '₹${originalPrice.toStringAsFixed(2)}'),
        const SizedBox(height: 12),

        if (discount > 0)
          _buildPriceRow(
            'Duration Discount',
            '- ₹${(originalPrice * option['discount']).toStringAsFixed(2)}',
            isDiscount: true,
          ),

        if (_couponDiscount != null)
          _buildPriceRow(
            'Coupon Discount',
            '- ₹${(finalPrice * _couponDiscount!).toStringAsFixed(2)}',
            isDiscount: true,
          ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),

        _buildPriceRow(
          'Total',
          '₹${finalPrice.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String amount,
      {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green[700] : null,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, bool isError) {
    // Remove any existing overlays first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 50,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: isError ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove the message after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  Future<void> _validateCoupon(String code) async {
    if (code.isEmpty) {
      _showMessage('Please enter a coupon code', true);
      return;
    }

    setState(() => _isValidatingCoupon = true);

    try {
      final couponRef =
          FirebaseDatabase.instance.ref().child('coupons').child(code);
      final snapshot = await couponRef.get();

      if (!snapshot.exists) {
        throw 'Invalid coupon code';
      }

      final couponData = snapshot.value as Map<dynamic, dynamic>;
      final expiryDate = DateTime.parse(couponData['expiryDate']);

      if (DateTime.now().isAfter(expiryDate)) {
        throw 'This coupon has expired';
      }

      final usedCount = couponData['usedCount'] ?? 0;
      final maxUses = couponData['maxUses'] ?? 1;

      if (usedCount >= maxUses) {
        throw 'This coupon has reached its maximum number of uses';
      }

      setState(() {
        _appliedCouponCode = code;
        _couponDiscount = (couponData['discountPercentage'] ?? 0.0) / 100;
      });

      _showMessage('Coupon applied successfully!', false);
    } catch (e) {
      setState(() {
        _appliedCouponCode = null;
        _couponDiscount = null;
      });
      _showMessage(e.toString(), true);
    } finally {
      setState(() => _isValidatingCoupon = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _couponController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_appliedCouponCode != null) {
      final couponRef = FirebaseDatabase.instance
          .ref()
          .child('coupons')
          .child(_appliedCouponCode!);

      // Increment the used count
      await couponRef.update({
        'usedCount': ServerValue.increment(1),
      });
    }

    final subscriptionData = {
      'magazineId': widget.magazineData['id'],
      'magazineTitle': widget.magazineData['title'],
      'period': _selectedPeriod,
      'startDate': DateTime.now().toIso8601String(),
      'endDate': DateTime.now()
          .add(Duration(
              days: _subscriptionOptions[_selectedPeriod]!['multiplier'] * 30))
          .toIso8601String(),
      'paymentId': response.paymentId,
      'amount': _calculatePrice(_selectedPeriod),
      'status': 'active',
    };

    if (widget.existingSubscriptionKey != null) {
      // Update existing subscription
      await FirebaseDatabase.instance
          .ref()
          .child('subscriptions')
          .child(user.uid)
          .child(widget.existingSubscriptionKey!)
          .update(subscriptionData);
    } else {
      // Create new subscription
      await FirebaseDatabase.instance
          .ref()
          .child('subscriptions')
          .child(user.uid)
          .push()
          .set(subscriptionData);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription successful!')),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _startPayment() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var options = {
      'key': 'rzp_test_A5qkBsgXRI2VXo', // Using your test key
      'amount':
          (_calculatePrice(_selectedPeriod) * 100).toInt(), // Amount in paise
      'name': widget.magazineData['title'],
      'description':
          '${_subscriptionOptions[_selectedPeriod]!['label']} Subscription',
      'prefill': {
        'contact': user.phoneNumber ?? '',
        'email': user.email ?? '',
      },
      'currency': 'INR', // Adding currency specification for India
      'theme': {
        'color': '#3399cc', // You can customize this color
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                enabled: _appliedCouponCode == null,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Have a coupon code?',
                  hintText: 'Enter code',
                  prefixIcon: const Icon(Icons.discount_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  // If coupon is applied, show success state
                  enabledBorder: _appliedCouponCode != null
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.green[600]!,
                            width: 2,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_appliedCouponCode == null)
              ElevatedButton(
                onPressed: _isValidatingCoupon
                    ? null
                    : () => _validateCoupon(_couponController.text.trim()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isValidatingCoupon
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Apply'),
              )
            else
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _appliedCouponCode = null;
                    _couponDiscount = null;
                    _couponController.clear();
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Remove'),
              ),
          ],
        ),
        if (_appliedCouponCode != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_couponDiscount! * 100).toInt()}% discount applied',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subscribe to ${widget.magazineData['title']}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Period Selection
                  SegmentedButton<String>(
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedPeriod = newSelection.first;
                      });
                    },
                    segments: _subscriptionOptions.entries.map((entry) {
                      return ButtonSegment<String>(
                        value: entry.key,
                        label: Text(entry.value['label']),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Coupon Section
                  _buildCouponSection(),
                  const SizedBox(height: 24),

                  // Price Details
                  _buildPriceDetails(_selectedPeriod),
                ],
              ),
            ),
          ),

          // Payment Button
          ElevatedButton(
            onPressed: _startPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Pay ₹${_calculatePrice(_selectedPeriod).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
