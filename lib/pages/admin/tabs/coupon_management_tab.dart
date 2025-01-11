import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class CouponManagementTab extends StatefulWidget {
  const CouponManagementTab({super.key});

  @override
  State<CouponManagementTab> createState() => _CouponManagementTabState();
}

class _CouponManagementTabState extends State<CouponManagementTab> {
  final _discountController = TextEditingController();
  final _maxUsesController = TextEditingController(text: '1');
  DateTime _selectedExpiryDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    final snapshot =
        await FirebaseDatabase.instance.ref().child('coupons').get();
    if (snapshot.exists) {
      final couponsData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _coupons = couponsData.entries
            .map((e) => {
                  'code': e.key,
                  ...Map<String, dynamic>.from(e.value as Map),
                })
            .toList();
      });
    }
  }

  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> _createCoupon() async {
    if (_discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a discount percentage')),
      );
      return;
    }

    final discount = double.tryParse(_discountController.text);
    if (discount == null || discount <= 0 || discount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid discount (1-100)')),
      );
      return;
    }

    final maxUses = int.tryParse(_maxUsesController.text);
    if (maxUses == null || maxUses < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enter a valid number of maximum uses (minimum 1)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final couponCode = _generateCouponCode();
      await FirebaseDatabase.instance
          .ref()
          .child('coupons')
          .child(couponCode)
          .set({
        'discountPercentage': discount,
        'expiryDate': _selectedExpiryDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'maxUses': maxUses,
        'usedCount': 0,
      });

      await _loadCoupons();
      _discountController.clear();
      _maxUsesController.text = '1';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon created: $couponCode')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating coupon: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCoupon(String code) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('coupons')
          .child(code)
          .remove();
      await _loadCoupons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting coupon: $e')),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon code copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create New Coupon Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create New Coupon',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Discount Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discount Percentage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _discountController,
                        decoration: InputDecoration(
                          hintText: '0-100',
                          suffixText: '%',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Maximum Uses Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maximum Uses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _maxUsesController,
                        decoration: InputDecoration(
                          hintText: 'e.g., 1',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // Expiry Date Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expiry Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedExpiryDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedExpiryDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedExpiryDate.toString().split(' ')[0],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Create Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createCoupon,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Coupon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Active Coupons Section
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Active Coupons',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _coupons.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final coupon = _coupons[index];
                  final expiryDate = DateTime.parse(coupon['expiryDate']);
                  final isExpired = DateTime.now().isAfter(expiryDate);
                  final usedCount = coupon['usedCount'] ?? 0;
                  final maxUses = coupon['maxUses'] ?? 1;
                  final isFullyUsed = usedCount >= maxUses;

                  return ListTile(
                    title: Row(
                      children: [
                        Text(
                          coupon['code'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () => _copyToClipboard(coupon['code']),
                          tooltip: 'Copy code',
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discount: ${coupon['discountPercentage']}% | Expires: ${expiryDate.toString().split(' ')[0]}',
                        ),
                        Text(
                          'Uses: $usedCount / $maxUses',
                          style: TextStyle(
                            color: isFullyUsed
                                ? Colors.red[700]
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExpired)
                          _buildStatusChip('Expired', Colors.red)
                        else if (isFullyUsed)
                          _buildStatusChip('Fully Used', Colors.orange)
                        else
                          _buildStatusChip('Active', Colors.green),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteCoupon(coupon['code']),
                          tooltip: 'Delete coupon',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
