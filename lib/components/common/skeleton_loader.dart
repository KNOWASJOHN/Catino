import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.baseColor = const Color(0xFF2d2d2d),
    this.highlightColor = const Color(0xFF3d3d3d),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A standard card skeleton structure often used in lists
class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final EdgeInsets margin;

  const SkeletonCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e), // Card bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2d2d2d)),
      ),
      child: Row(
        children: [
          // Icon/Image placeholder
          const SkeletonLoader(width: 60, height: 60, borderRadius: 12),
          const SizedBox(width: 16),
          // Content lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 120, height: 16),
                const SizedBox(height: 8),
                const SkeletonLoader(width: 80, height: 12),
                const SizedBox(height: 8),
                const SkeletonLoader(width: 60, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List of SkeletonCards
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsets padding;

  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCard(),
    );
  }
}

/// Skeleton for UserCard
class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2d2d2d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              SkeletonLoader(width: 80, height: 80, borderRadius: 20),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 150, height: 24),
                  SizedBox(height: 12),
                  SkeletonLoader(width: 100, height: 16),
                ],
              ),
            ],
          ),
          Spacer(),
          SkeletonLoader(width: double.infinity, height: 40, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton for FoodSection grid
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
    } else {
      crossAxisCount = 4;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2d2d2d)),
          ),
          child: const SkeletonLoader(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 16,
          ),
        ),
      ),
    );
  }
}

/// Skeleton for ScrollCard (Banner)
class ScrollCardSkeleton extends StatelessWidget {
  const ScrollCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(left: 16, right: 16),
      child: const SkeletonLoader(
        width: double.infinity,
        height: 180,
        borderRadius: 24,
      ),
    );
  }
}

/// Skeleton for TableCalendar
class TableCalendarSkeleton extends StatelessWidget {
  const TableCalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: const SkeletonLoader(
        width: double.infinity,
        height: 350,
        borderRadius: 24,
      ),
    );
  }
}

/// Skeleton for OrderHistory (Alias for SkeletonList)
class OrderHistorySkeleton extends StatelessWidget {
  const OrderHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLoader(width: 150, height: 24), // Header title skeleton
          SizedBox(height: 16),
          SkeletonList(itemCount: 3, padding: EdgeInsets.zero),
        ],
      ),
    );
  }
}
