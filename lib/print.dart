import 'package:flutter/material.dart';
import 'components/upload.dart';
import 'components/print_history.dart';
import 'services/print_service.dart';

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
    } catch (e) {
      print('Error loading print jobs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            const Upload(),
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
                              Icon(Icons.print_disabled,
                                  size: 64, color: Colors.grey[300]),
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
    );
  }

  void _showJobDetails(PrintJob job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Print Job #${job.code}',
          style: TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('File', job.fileName),
            _buildDetailRow('Date', job.formattedDateTime),
            _buildDetailRow('Status', job.status.displayText),
            _buildDetailRow('Pages', '${job.pageCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(fontFamily: 'Unbounded'),
            ),
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
}
