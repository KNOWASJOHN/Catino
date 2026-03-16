import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/toast_helper.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/log.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/print/upload.dart';
import '../components/print/print_history.dart';
import '../models/print_job.dart';
import '../services/data/print_service.dart';
import 'pdf_viewer_page.dart';
import '../theme/theme.dart';

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
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPrintJobs,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Upload(onUploadComplete: _loadPrintJobs),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildLoadingState(),
              )
            else if (_printJobs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyJobsState(),
              )
            else
              SliverToBoxAdapter(
                child: PrintHistory(
                  printJobs: _printJobs,
                  onJobTap: _showJobDetails,
                  shrinkWrap: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading...',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyJobsState() {
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
            'No print jobs yet',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a document above to get started',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 9,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadPrintJobs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(PrintJob job) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppColors.barrierMedium,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, animation, _, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.dialogGradientStart,
                        AppColors.dialogGradientMid,
                        AppColors.dialogGradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -60,
                        left: -30,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        right: 80,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.03),
                          ),
                        ),
                      ),
                      // Card content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Row 1: Logo + Status ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/logo/Catino.png',
                                  height: 26,
                                ),
                                const Spacer(),
                                _buildStatusChip(job.status.displayText),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Job code + Payment IDs ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${job.code}',
                                        style: const TextStyle(
                                          fontFamily: 'Unbounded',
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        job.fileName,
                                        style: TextStyle(
                                          fontFamily: 'Unbounded',
                                          fontSize: 9,
                                          color: Colors.white.withOpacity(0.65),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (job.paymentId != null &&
                                    job.paymentId!.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 130,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildCardCopyField(
                                          'PAY ID',
                                          job.paymentId ?? 'N/A',
                                          ctx,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildCardCopyField(
                                          'ORDER ID',
                                          job.orderId ?? 'N/A',
                                          ctx,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Thin divider ──
                            Container(
                              height: 0.6,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 14),
                            // ── DATE / PAGES / AMOUNT ──
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'DATE',
                                      style: TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 7,
                                        color: Colors.white.withOpacity(0.5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      job.formattedDateTime,
                                      style: const TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'PAGES',
                                      style: TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 7,
                                        color: Colors.white.withOpacity(0.5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${job.pageCount}',
                                      style: const TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'AMOUNT',
                                      style: TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 7,
                                        color: Colors.white.withOpacity(0.5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '₹${job.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // ── Payment badge + QR section ──
                            if (job.paymentId != null &&
                                job.paymentId!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                height: 0.6,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(1),
                                        color: Colors.white,
                                        child: QrImageView(
                                          data:
                                              job.orderId ??
                                              job.paymentId ??
                                              '',
                                          version: QrVersions.auto,
                                          size: 100,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCardPaymentBadge(
                                      job.paymentStatus ?? 'pending',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // ── Divider before actions ──
                            const SizedBox(height: 14),
                            Container(
                              height: 0.6,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 12),
                            // ── Action buttons ──
                            Row(
                              children: [
                                if (job.fileUrl.isNotEmpty) ...[
                                  Expanded(
                                    child: _buildCardButton(
                                      label: 'View',
                                      icon: Icons.open_in_new_rounded,
                                      solid: true,
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _openFile(job.fileUrl, job.fileName);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCardIconButton(
                                    icon: Icons.delete_outline_rounded,
                                    color: Colors.red.shade400,
                                    onTap: () => _deleteJob(job),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: _buildCardButton(
                                    label: 'Close',
                                    icon: Icons.close_rounded,
                                    solid: false,
                                    onTap: () => Navigator.pop(ctx),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardCopyField(String label, String value, BuildContext ctx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 7,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            final fToast = FToast()..init(ctx);
            fToast.showToast(
              toastDuration: const Duration(seconds: 1),
              gravity: ToastGravity.BOTTOM,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      '$label copied',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.copy_rounded,
              size: 12,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPaymentBadge(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'paid':
        color = AppColors.statusSuccess;
        label = 'PAID';
        icon = Icons.check_circle_rounded;
        break;
      case 'failed':
        color = AppColors.statusError;
        label = 'FAILED';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColors.statusWarning;
        label = 'PENDING';
        icon = Icons.schedule_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            'PAYMENT',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 7,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardButton({
    required String label,
    required IconData icon,
    required bool solid,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: solid ? Colors.white.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildStatusChip(String statusText) {
    Color chipColor;
    switch (statusText.toLowerCase()) {
      case 'finished':
      case 'completed':
        chipColor = AppColors.statusSuccess;
        break;
      case 'printing':
        chipColor = Colors.blue;
        break;
      case 'ready':
        chipColor = AppColors.statusReady;
        break;
      case 'cancelled':
      case 'failed':
        chipColor = AppColors.statusError;
        break;
      case 'pending':
        chipColor = AppColors.statusWarning;
        break;
      default:
        chipColor = AppColors.statusPending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.6), width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontFamily: 'Unbounded',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
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
              backgroundColor: AppColors.deleteConfirmButton,
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
    AppToast.show(context, message, isError: true);
  }

  void _showSuccessSnackBar(String message) {
    AppToast.show(context, message);
  }
}
