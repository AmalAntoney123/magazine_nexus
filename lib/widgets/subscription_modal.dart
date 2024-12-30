import 'package:flutter/material.dart';

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

  double _calculatePrice(String period) {
    final option = _subscriptionOptions[period]!;
    final baseTotal = widget.basePrice * option['multiplier'];
    final discount = baseTotal * option['discount'];
    return baseTotal - discount;
  }

  Widget _buildPriceDetails(String period) {
    final option = _subscriptionOptions[period]!;
    final originalPrice = widget.basePrice * option['multiplier'];
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
            onPressed: () {
              // TODO: Implement payment processing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment gateway integration coming soon!'),
                ),
              );
            },
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
    );
  }
}
