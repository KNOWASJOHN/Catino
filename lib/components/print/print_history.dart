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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Row(
            children: [
              const Text(
                'History',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${printJobs.length}',
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── List ──
        Expanded(
          child: printJobs.isEmpty
              ? _buildEmptyState()
              : ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.06, 0.88, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.separated(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    itemCount: printJobs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 20,
                      color: Colors.grey.shade100,
                    ),
                    itemBuilder: (context, index) {
                      return _buildPrintJobTile(printJobs[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPrintJobTile(PrintJob job) {
    return InkWell(
      onTap: onJobTap != null ? () => onJobTap!(job) : null,
      splashColor: AppColors.primary.withOpacity(0.06),
      highlightColor: AppColors.primary.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Code badge ──
            _buildCodeBadge(job.code),
            const SizedBox(width: 14),

            // ── Details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.fileName,
                    style: const TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _metaLine(job),
                    style: const TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 7.5,
                      color: Colors.black45,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ── Right column: price + status ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  PricingConfig.formatPrice(job.price),
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: job.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.status.displayText,
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: job.status.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Compact meta info as a single dot-separated string
  String _metaLine(PrintJob job) {
    final parts = <String>[
      job.formattedDateTime,
      '${job.pageCount}p',
      job.colorMode == ColorMode.color ? 'Color' : 'B&W',
      job.sides == Sides.double ? '2-sided' : '1-sided',
    ];
    return parts.join('  ·  ');
  }

  Widget _buildCodeBadge(String code) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 34,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No print history',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your print jobs will appear here',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 9,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
