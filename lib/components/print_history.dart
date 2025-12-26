import 'package:flutter/material.dart';

/// Enum for print job status - easy to extend with new statuses
enum PrintStatus {
  finished,
  pending,
  cancelled;

  /// Get display text for the status
  String get displayText {
    switch (this) {
      case PrintStatus.finished:
        return 'Finished';
      case PrintStatus.pending:
        return 'Pending';
      case PrintStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get color for the status
  Color get color {
    switch (this) {
      case PrintStatus.finished:
        return Colors.green;
      case PrintStatus.pending:
        return Colors.orange;
      case PrintStatus.cancelled:
        return Colors.red;
    }
  }

  /// Get icon for the status
  IconData get icon {
    switch (this) {
      case PrintStatus.finished:
        return Icons.check_circle;
      case PrintStatus.pending:
        return Icons.pending;
      case PrintStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Convert from string
  static PrintStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'finished':
        return PrintStatus.finished;
      case 'pending':
        return PrintStatus.pending;
      case 'cancelled':
        return PrintStatus.cancelled;
      default:
        return PrintStatus.pending;
    }
  }
}

/// Model class for a print job - easy to modify and extend
class PrintJob {
  final String id;
  final String code; // 2-digit unique
  final String fileName;
  final DateTime dateTime;
  final PrintStatus status;
  final int pageCount;
  final String fileUrl;

  const PrintJob({
    required this.id,
    required this.code,
    required this.fileName,
    required this.dateTime,
    required this.status,
    this.pageCount = 1,
    this.fileUrl = '',
  });

  /// Format date and time for display
  String get formattedDateTime {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'fileName': fileName,
      'timestamp': dateTime.millisecondsSinceEpoch,
      'status': status.displayText.toLowerCase(),
      'pageCount': pageCount,
      'fileUrl': fileUrl,
    };
  }

  /// Create from Firebase Map
  factory PrintJob.fromMap(Map<dynamic, dynamic> map) {
    return PrintJob(
      id: map['id'] ?? '',
      code: map['code'] ?? '00',
      fileName: map['fileName'] ?? 'Unknown',
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      status: PrintStatus.fromString(map['status'] ?? 'pending'),
      pageCount: map['pageCount'] ?? 1,
      fileUrl: map['fileUrl'] ?? '',
    );
  }
}

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
