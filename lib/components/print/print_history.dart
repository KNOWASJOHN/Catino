import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../models/print_job.dart';
import '../../utils/pricing_config.dart';

/// Reusable Print History Widget
class PrintHistory extends StatelessWidget {
  final List<PrintJob> printJobs;
  final Function(PrintJob)? onJobTap;

  const PrintHistory({super.key, required this.printJobs, this.onJobTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Text(
            'Print History',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              decoration: TextDecoration.underline,
            ),
          ),
          // List of print jobs
          Expanded(
            child: printJobs.isEmpty
                ? _buildEmptyState()
                : ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.08, 0.9, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 50),
                      itemCount: printJobs.length,
                      itemBuilder: (context, index) {
                        return _buildPrintJobCard(printJobs[index]);
                      },
                    ),
                  ),
          ),
          SizedBox(height: 17),
        ],
      ),
    );
  }

  /// Build individual print job card - easy to customize appearance
  Widget _buildPrintJobCard(PrintJob job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onJobTap != null ? () => onJobTap!(job) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code badge
              _buildCodeBadge(job.code),
              const SizedBox(width: 14),

              // Job details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File name and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.fileName,
                            style: TextStyle(
                              fontFamily: 'Unbounded',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(job.status),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Date/Time
                    Text(
                      job.formattedDateTime,
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 8,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Print options and price in a row
                    Row(
                      children: [
                        // Print options - compact
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildCompactInfoChip(
                                icon: Icons.pages,
                                label: '${job.pageCount}p',
                              ),
                              _buildCompactInfoChip(
                                icon: job.colorMode == ColorMode.color
                                    ? Icons.palette
                                    : Icons.filter_b_and_w,
                                label: job.colorMode == ColorMode.color
                                    ? 'Color'
                                    : 'B&W',
                              ),
                              _buildCompactInfoChip(
                                icon: job.sides == Sides.double
                                    ? Icons.filter_2
                                    : Icons.filter_1,
                                label: job.sides == Sides.double
                                    ? '2-sided'
                                    : '1-sided',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Price - compact
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            PricingConfig.formatPrice(job.price),
                            style: TextStyle(
                              fontFamily: 'Unbounded',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build code badge - easy to customize styling
  Widget _buildCodeBadge(String code) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryCta.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryCta, width: 2),
      ),
      child: Center(
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// Build status chip - easy to customize colors and icons
  Widget _buildStatusChip(PrintStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.displayText,
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact info chip for print options
  Widget _buildCompactInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.black54),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 8,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state when no print jobs exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.print_disabled, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No print history yet',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
