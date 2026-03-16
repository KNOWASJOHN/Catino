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
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.dialog,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '👋 Hello, $userName!',
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back to Catino. Explore our latest products and offers!',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.5),
                height: 1.6,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 0.6,
              color: AppColors.borderHighlight,
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet!',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t placed any orders.\nStart shopping and your latest order\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 9,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.4),
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [AppShadows.accentGlow(AppColors.primary)],
              ),
              child: const Text(
                'Start Shopping',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
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
          Text(
            'LATEST ORDER',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 9,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '#${orderCode!}',
            style: const TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(2),
                color: Colors.white,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.borderHighlight, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status ?? ''),
                  color: AppColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  status ?? '',
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
