import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionModal extends StatefulWidget {
  final Map<dynamic, dynamic> magazineData;
  final double basePrice;

  const SubscriptionModal({
    super.key,
    required this.magazineData,
    required this.basePrice,
  });

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  String _selectedPeriod = '1_month'; // Default selection
  bool _showDetails = false;
  late Razorpay _razorpay;

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
    final discount = baseTotal * option['discount'];
    return baseTotal - discount;
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
        if (discount > 0) ...[
          Text(
            '₹${originalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${discount.toInt()}% OFF',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
        Text(
          '₹${finalPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _showDetails = !_showDetails),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_showDetails ? 'Hide details' : 'See more'),
              Icon(_showDetails ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
        if (_showDetails) ...[
          const Divider(),
          Text(
            'Price Breakdown:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text('Base price per issue: ₹${widget.basePrice.toStringAsFixed(2)}'),
          Text('Number of issues: ${issuesCount.toStringAsFixed(1)}'),
          Text('Subtotal: ₹${originalPrice.toStringAsFixed(2)}'),
          if (discount > 0)
            Text(
                'Discount (${discount.toInt()}%): -₹${(originalPrice * option['discount']).toStringAsFixed(2)}'),
          const Divider(),
          Text(
            'Total: ₹${finalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
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
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

    await FirebaseDatabase.instance
        .ref()
        .child('subscriptions')
        .child(user.uid)
        .push()
        .set(subscriptionData);

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
      'key': 'rzp_test_1AC0p6RtIwwvLU', // Using your test key
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Subscribe to ${widget.magazineData['title']}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
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
            // Price Details
            _buildPriceDetails(_selectedPeriod),
            const SizedBox(height: 32),
            // Subscribe Button
            ElevatedButton(
              onPressed: _startPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Text(
                'Pay ₹${_calculatePrice(_selectedPeriod).toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(height: 16),
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
