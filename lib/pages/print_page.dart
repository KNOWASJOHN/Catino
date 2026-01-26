import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/log.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/print/upload.dart';
import '../components/print/print_history.dart';
import '../models/print_job.dart';
import '../services/data/print_service.dart';
import 'pdf_viewer_page.dart';

class PrintPage extends StatefulWidget {
  const PrintPage({super.key});

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  final PrintService _printService = PrintService();
  List<PrintJob> _printJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _printService.startListeningToPrintJobs();
    _loadPrintJobs();
  }

  Future<void> _loadPrintJobs() async {
    setState(() => _isLoading = true);

    try {
      List<PrintJob> jobs = await _printService.getUserPrintJobs();

      if (mounted) {
        setState(() {
          _printJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      logError('Error loading print jobs', e, st);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPrintJobs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Upload(onUploadComplete: _loadPrintJobs),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00C853),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading print jobs...',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _printJobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.print_disabled,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No print jobs found',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadPrintJobs,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00C853),
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  fontFamily: 'Unbounded',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : PrintHistory(
                        printJobs: _printJobs,
                        onJobTap: (job) {
                          // Handle when a print job is tapped
                          _showJobDetails(job);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetails(PrintJob job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Print Job #${job.code}',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('File', job.fileName),
            _buildDetailRow('Date', job.formattedDateTime),
            _buildDetailRow('Status', job.status.displayText),
            _buildDetailRow('Pages', '${job.pageCount}'),
            _buildDetailRow('Price', '₹${job.price.toStringAsFixed(2)}'),
            if (job.paymentId != null && job.paymentId!.isNotEmpty) ...[
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),
              Text(
                'Payment Information',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              _buildDetailRow('Payment ID', job.paymentId ?? 'N/A'),
              _buildDetailRow('Order ID', job.orderId ?? 'N/A'),
              _buildPaymentStatusRow(job.paymentStatus ?? 'pending'),
            ],
            if (job.fileUrl.isNotEmpty) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openFile(job.fileUrl, job.fileName),
                      icon: Icon(Icons.open_in_new, size: 16),
                      label: Text(
                        'View File',
                        style: TextStyle(fontFamily: 'Unbounded', fontSize: 10),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _deleteJob(job),
                    child: Icon(Icons.delete, size: 16),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(48, 36),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontFamily: 'Unbounded')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusRow(String status) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        statusText = 'Paid ✓';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusText = 'Failed';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Payment:',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String fileUrl, [String? fileName]) async {
    try {
      // Validate URL is not empty or null
      if (fileUrl.trim().isEmpty) {
        _showErrorSnackBar('Cannot open file: Invalid or empty file URL.');
        return;
      }

      // Validate URL format
      Uri? parsedUri;
      try {
        parsedUri = Uri.parse(fileUrl);
        if (!parsedUri.hasScheme ||
            (!parsedUri.isScheme('http') && !parsedUri.isScheme('https'))) {
          _showErrorSnackBar(
            'Cannot open file: Invalid URL format. URL must start with http:// or https://',
          );
          return;
        }
      } catch (e) {
        _showErrorSnackBar('Cannot open file: Malformed URL');
        return;
      }

      // Check if it's a PDF file by URL extension or content type
      if (fileUrl.toLowerCase().endsWith('.pdf') ||
          fileUrl.contains('application/pdf') ||
          fileUrl.contains('.pdf')) {
        // Open PDF in-app
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(
              url: fileUrl,
              title: fileName ?? 'Document Viewer',
            ),
          ),
        );
      } else {
        // For non-PDF files, still try to launch externally
        final uri = Uri.parse(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar(
            'Cannot open file. No app available to handle this file type.',
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error opening file');
    }
  }

  Future<void> _deleteJob(PrintJob job) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Print Job',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this print job? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Unbounded', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Unbounded')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete', style: TextStyle(fontFamily: 'Unbounded')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Close the job details dialog first
      Navigator.pop(context);

      try {
        final success = await _printService.deletePrintJob(job.id);

        if (success) {
          _showSuccessSnackBar('Print job deleted successfully');
          _loadPrintJobs(); // Refresh the list
        } else {
          _showErrorSnackBar('Failed to delete print job');
        }
      } catch (e, st) {
        logError('Error deleting print job', e, st);
        _showErrorSnackBar('Error deleting job');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Unbounded', fontSize: 12),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Unbounded', fontSize: 12),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
