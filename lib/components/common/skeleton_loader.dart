import 'package:flutter/material.dart';
import 'dart:ui';

/// A shimmer skeleton loading widget that provides a smooth pulsing animation
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: (widget.baseColor ?? Colors.grey[300])?.withOpacity(
              _animation.value,
            ),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for the UserCard component - matches black87 card with QR code
class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      decoration: BoxDecoration(
        color: Colors.black87,
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
            // User greeting skeleton
            const SkeletonLoader(
              width: 200,
              height: 24,
              baseColor: Colors.white30,
            ),
            const SizedBox(height: 8),
            // Welcome text skeleton
            const SkeletonLoader(
              width: 300,
              height: 12,
              baseColor: Colors.white24,
            ),
            const SizedBox(height: 15),
            // "Latest Order:" text skeleton
            Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  const SkeletonLoader(
                    width: 100,
                    height: 15,
                    baseColor: Colors.white30,
                  ),
                  const SizedBox(height: 5),
                  // Order code skeleton
                  const SkeletonLoader(
                    width: 80,
                    height: 15,
                    baseColor: Colors.white30,
                  ),
                  const SizedBox(height: 15),
                  // QR code skeleton
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const SkeletonLoader(
                      width: 180,
                      height: 180,
                      baseColor: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Status skeleton
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonLoader(
                        width: 20,
                        height: 20,
                        baseColor: Colors.white30,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      SizedBox(width: 5),
                      SkeletonLoader(
                        width: 60,
                        height: 12,
                        baseColor: Colors.white24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for the FoodSection component - grid layout
class FoodSectionSkeleton extends StatelessWidget {
  const FoodSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth < 600) {
      crossAxisCount = 2;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
    } else if (screenWidth < 1200) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 5;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      itemCount: 6,
      itemBuilder: (context, index) => _buildFoodItemSkeleton(),
    );
  }

  Widget _buildFoodItemSkeleton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image skeleton
            const SkeletonLoader(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            // Content skeletons
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(
                    width: 80,
                    height: 16,
                    baseColor: Colors.white30,
                  ),
                  const SizedBox(height: 4),
                  const SkeletonLoader(
                    width: 100,
                    height: 10,
                    baseColor: Colors.white24,
                  ),
                  const SizedBox(height: 8),
                  const SkeletonLoader(
                    width: 60,
                    height: 15,
                    baseColor: Colors.white30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for the ScrollCard component - PageView style
class ScrollCardSkeleton extends StatelessWidget {
  const ScrollCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardHeight = MediaQuery.of(context).size.height * 0.4;

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image skeleton
                  const SkeletonLoader(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonLoader(
                          width: 200,
                          height: 24,
                          baseColor: Colors.white30,
                        ),
                        const SizedBox(height: 8),
                        const SkeletonLoader(
                          width: 250,
                          height: 14,
                          baseColor: Colors.white24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        // Page indicators skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == 0 ? 12 : 8,
              height: index == 0 ? 12 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == 0 ? Colors.black : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton loader for the OrderHistoryList component - glassmorphic style
class OrderHistorySkeleton extends StatelessWidget {
  const OrderHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: [
              // Heading
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: const SkeletonLoader(
                  width: 140,
                  height: 20,
                  baseColor: Colors.black26,
                ),
              ),
              // Content
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildOrderItemSkeleton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Status icon skeleton
            const SkeletonLoader(
              width: 56,
              height: 56,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            const SizedBox(width: 18),
            // Order details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: 80, height: 14),
                  const SizedBox(height: 8),
                  const SkeletonLoader(width: 60, height: 20),
                  const SizedBox(height: 8),
                  const SkeletonLoader(width: 100, height: 12),
                  const SizedBox(height: 6),
                  Container(height: 1, width: 60, color: Colors.grey[300]),
                  const SizedBox(height: 6),
                  const SkeletonLoader(width: 70, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // QR indicator skeleton
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SkeletonLoader(
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                const SizedBox(height: 6),
                const SkeletonLoader(
                  width: 24,
                  height: 20,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
