import 'package:flutter/material.dart';
import '../../models/print_job.dart';

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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Code badge
              _buildCodeBadge(job.code),
              const SizedBox(width: 16),

              // Job details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.fileName,
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.formattedDateTime,
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Status indicator
              _buildStatusChip(job.status),
            ],
          ),
        ),
      ),
    );
  }

  /// Build code badge - easy to customize styling
  Widget _buildCodeBadge(String code) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.limeAccent.shade700.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.limeAccent.shade700, width: 2),
      ),
      child: Center(
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.displayText,
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: status.color,
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
