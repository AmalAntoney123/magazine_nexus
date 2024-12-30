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
  bool _showDetails = false;

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
      ),
    );
  }
}
