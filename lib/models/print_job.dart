import 'package:flutter/material.dart';
import '../utils/pricing_config.dart';

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
  final ColorMode colorMode;
  final Sides sides;
  final double price;

  const PrintJob({
    required this.id,
    required this.code,
    required this.fileName,
    required this.dateTime,
    required this.status,
    this.pageCount = 1,
    this.fileUrl = '',
    this.colorMode = ColorMode.blackAndWhite,
    this.sides = Sides.single,
    this.price = 0.0,
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
      'colorMode': colorMode.toDbString(),
      'sides': sides.toDbString(),
      'price': price,
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
      colorMode: ColorMode.fromString(map['colorMode'] ?? 'blackAndWhite'),
      sides: Sides.fromString(map['sides'] ?? 'single'),
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

  /// Create from Supabase Map
  factory PrintJob.fromSupabaseMap(Map<String, dynamic> map) {
    return PrintJob(
      id: map['id'] ?? '',
      code: map['code'] ?? '00',
      fileName: map['file_name'] ?? 'Unknown',
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      status: PrintStatus.fromString(map['status'] ?? 'pending'),
      pageCount: map['page_count'] ?? 1,
      fileUrl: map['file_url'] ?? '',
      colorMode: ColorMode.fromString(map['color_mode'] ?? 'blackAndWhite'),
      sides: Sides.fromString(map['sides'] ?? 'single'),
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}
