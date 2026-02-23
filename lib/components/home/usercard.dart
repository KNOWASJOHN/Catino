import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

class UserCard extends StatelessWidget {
  final String userName;
  final String? orderCode;
  final List<Map<String, dynamic>> items;
  final String? status;
  final int timestamp;

  const UserCard({
    super.key,
    required this.userName,
    this.orderCode,
    this.items = const [],
    this.status,
    this.timestamp = 0,
  });

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'ordered':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  bool get _hasOrder => orderCode != null && orderCode!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '👋 Hello, $userName!',
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back to Catino. Explore our latest products and offers!',
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 12,
                fontWeight: FontWeight.w200,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 15),
            _hasOrder ? _buildOrderSection() : _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet!',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Looks like you haven\'t placed any orders.\nStart shopping and your latest order\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 11,
                fontWeight: FontWeight.w200,
                color: Colors.white54,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Start Shopping',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSection() {
    final qrData = jsonEncode({
      'orderCode': orderCode,
      'items': items,
      'status': status,
      'timestamp': timestamp,
    });

    return Align(
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text(
            'Latest Order:',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            orderCode!,
            style: const TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getStatusIcon(status ?? ''), color: Colors.white),
              const SizedBox(width: 5),
              Text(
                status ?? '',
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
