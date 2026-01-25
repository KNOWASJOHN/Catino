import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;
import '../../services/storage/file_upload_service.dart';
import '../../services/data/print_service.dart';
import '../../services/payment/payment_service.dart';
import '../../models/print_job.dart';
import '../../utils/pricing_config.dart';

class Upload extends StatefulWidget {
  final VoidCallback? onUploadComplete;

  const Upload({super.key, this.onUploadComplete});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final FileUploadService _fileUploadService = FileUploadService();
  final PrintService _printService = PrintService();
  final PaymentService _paymentService = PaymentService();
  final Connectivity _connectivity = Connectivity();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  PlatformFile? _selectedFile;

  // Print options state
  int _pdfPageCount = 0; // Extracted from PDF
  int _copies = 1; // Number of copies to print
  ColorMode _colorMode = ColorMode.blackAndWhite;
  Sides _sides = Sides.single;
  double _calculatedPrice = 0.0;
  bool _isExtractingPages = false;

  /// Check if device has internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResults = await _connectivity
          .checkConnectivity();

      // Check if any connection is available
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return false;
      }

      // Additional check: try to ping a reliable server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 100, 0, 0),
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          SizedBox(
            width: 300,
            height: 120,
            child: DottedBorder(
              color: _isUploading ? Colors.green : Colors.black45,
              strokeWidth: 1,
              dashPattern: [7, 7],
              borderType: BorderType.RRect,
              radius: Radius.circular(12),
              child: InkWell(
                onTap: _isUploading ? null : _selectFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: _buildUploadContent(),
                ),
              ),
            ),
          ),
          if (_selectedFile != null) ...[
            SizedBox(height: 16),
            _buildFileInfo(),
            SizedBox(height: 20),
            _buildPrintOptions(),
            SizedBox(height: 16),
            _buildPriceDisplay(),
            SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadContent() {
    if (_isUploading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _uploadProgress,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
            strokeWidth: 3,
          ),
          SizedBox(height: 8),
          Text(
            'Uploading...',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w400,
              fontSize: 10,
              color: Colors.green,
            ),
          ),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w600,
              fontSize: 8,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    if (_selectedFile != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 30, color: Colors.green),
          SizedBox(height: 4),
          Text(
            'PDF Selected',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w400,
              fontSize: 10,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload_file, size: 30, color: Colors.black87),
        SizedBox(height: 4),
        Text(
          'Upload Your Document',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w300,
            fontSize: 8,
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 2),
        Text(
          'PDF only, max 10MB',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w300,
            fontSize: 6,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFileInfo() {
    if (_selectedFile == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 50),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFile!.name,
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  FileUploadService.formatFileSize(_selectedFile!.size),
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 8,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearSelection,
            icon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
            constraints: BoxConstraints.tightFor(width: 24, height: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Extract page count from PDF file
  Future<int> _extractPdfPageCount(PlatformFile file) async {
    try {
      if (file.path == null) return 0;

      setState(() {
        _isExtractingPages = true;
      });

      final pdfFile = File(file.path!);
      final bytes = await pdfFile.readAsBytes();

      // Use syncfusion_flutter_pdf to get the page count reliably
      final syncfusionDocument = syncfusion_pdf.PdfDocument(inputBytes: bytes);
      final pageCount = syncfusionDocument.pages.count;
      syncfusionDocument.dispose(); // Dispose the document to free resources

      setState(() {
        _isExtractingPages = false;
      });

      return pageCount;
    } catch (e) {
      print('Error extracting PDF page count: $e');
      setState(() {
        _isExtractingPages = false;
      });
      return 0; // Default to 0 on error
    }
  }

  Widget _buildPrintOptions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      margin: EdgeInsets.symmetric(horizontal: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Print Options',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          // PDF Page Count Display
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'PDF Pages:',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: _isExtractingPages
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00C853),
                          ),
                        ),
                      )
                    : Text(
                        _pdfPageCount > 0 ? '$_pdfPageCount' : 'N/A',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C853),
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Number of Copies Input
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Number of Copies:',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: '$_copies'),
                  decoration: InputDecoration(
                    hintText: '1',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF00C853)),
                    ),
                  ),
                  style: TextStyle(fontFamily: 'Unbounded', fontSize: 10),
                  onChanged: (value) {
                    setState(() {
                      _copies = int.tryParse(value) ?? 1;
                      if (_copies < 1) _copies = 1;
                      _updatePrice();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Color Mode Selector
          Text(
            'Color Mode:',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          SegmentedButton<ColorMode>(
            segments: [
              ButtonSegment(
                value: ColorMode.blackAndWhite,
                label: Text(
                  'B&W',
                  style: TextStyle(fontFamily: 'Unbounded', fontSize: 9),
                ),
                icon: Icon(Icons.filter_b_and_w, size: 16),
              ),
              ButtonSegment(
                value: ColorMode.color,
                label: Text(
                  'Color',
                  style: TextStyle(fontFamily: 'Unbounded', fontSize: 9),
                ),
                icon: Icon(Icons.palette, size: 16),
              ),
            ],
            selected: {_colorMode},
            onSelectionChanged: (Set<ColorMode> selection) {
              setState(() {
                _colorMode = selection.first;
                _updatePrice();
              });
            },
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                TextStyle(fontFamily: 'Unbounded', fontSize: 9),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Sides Selector
          Text(
            'Print Sides:',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          SegmentedButton<Sides>(
            segments: [
              ButtonSegment(
                value: Sides.single,
                label: Text(
                  'Single',
                  style: TextStyle(fontFamily: 'Unbounded', fontSize: 9),
                ),
                icon: Icon(Icons.filter_1, size: 16),
              ),
              ButtonSegment(
                value: Sides.double,
                label: Text(
                  'Double',
                  style: TextStyle(fontFamily: 'Unbounded', fontSize: 9),
                ),
                icon: Icon(Icons.filter_2, size: 16),
              ),
            ],
            selected: {_sides},
            onSelectionChanged: (Set<Sides> selection) {
              setState(() {
                _sides = selection.first;
                _updatePrice();
              });
            },
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                TextStyle(fontFamily: 'Unbounded', fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: EdgeInsets.symmetric(horizontal: 50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00E676)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00C853).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated Price',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 4),
              Text(
                PricingConfig.formatPrice(_calculatedPrice),
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rate: ${PricingConfig.formatPrice(PricingConfig.getRatePerPage(_colorMode, _sides))}/page',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 2),
              Text(
                '$_pdfPageCount pages × $_copies copies',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updatePrice() {
    setState(() {
      _calculatedPrice = PricingConfig.calculatePrice(
        pageCount: _pdfPageCount * _copies, // Total pages = PDF pages × copies
        colorMode: _colorMode,
        sides: _sides,
      );
    });
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadAndCreateJob,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00C853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Print Document',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 12),
        TextButton(
          onPressed: _clearSelection,
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectFile() async {
    try {
      final file = await _fileUploadService.pickPDFFile();
      if (file != null) {
        setState(() {
          _selectedFile = file;
          _isExtractingPages = true;
        });

        // Extract page count from PDF
        final pageCount = await _extractPdfPageCount(file);

        setState(() {
          _pdfPageCount = pageCount;
          _copies = 1; // Reset to default
          _isExtractingPages = false;
          _updatePrice(); // Calculate initial price
        });
      }
    } catch (e) {
      setState(() {
        _isExtractingPages = false;
      });
      _showErrorDialog('File Selection Error', e.toString());
    }
  }

  Future<void> _uploadAndCreateJob() async {
    if (_selectedFile == null || _isUploading)
      return; // Prevent multiple uploads

    // Check internet connectivity first
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      _showNoInternetDialog();
      return;
    }

    // Validate that price is greater than zero
    if (_calculatedPrice <= 0) {
      _showErrorDialog(
        'Invalid Price',
        'Cannot process payment. Please check your print options.',
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Generate unique job ID with microseconds for better uniqueness
      final now = DateTime.now();
      final jobId = '${now.millisecondsSinceEpoch}_${now.microsecond}';

      print('Creating print job with ID: $jobId');

      // Step 1: Process payment first
      print('Starting payment for ₹${_calculatedPrice.toStringAsFixed(2)}');
      final paymentResult = await _paymentService.startPayment(
        amount: _calculatedPrice,
        description: 'Print Job - ${_selectedFile!.name}',
        metadata: {
          'job_id': jobId,
          'file_name': _selectedFile!.name,
          'page_count': _pdfPageCount * _copies,
          'color_mode': _colorMode.toDbString(),
          'sides': _sides.toDbString(),
        },
      );

      // Step 2: Check if payment was successful
      if (!paymentResult.isSuccess) {
        if (paymentResult.isCancelled) {
          _showErrorDialog(
            'Payment Cancelled',
            'You have cancelled the payment process.',
          );
          return;
        }

        throw Exception(
          paymentResult.errorMessage ?? 'Payment failed. Please try again.',
        );
      }

      print('Payment successful! Payment ID: ${paymentResult.paymentId}');

      // Step 3: Simulate upload progress
      _simulateUploadProgress();

      // Step 4: Upload file to Supabase
      final fileUrl = await _fileUploadService.uploadFile(
        _selectedFile!,
        jobId,
      );

      // Step 5: Create print job with file URL, print options, and payment details
      final printJob = PrintJob(
        id: jobId,
        code: _generatePrintCode(),
        fileName: _selectedFile!.name,
        dateTime: DateTime.now(),
        status: PrintStatus.pending,
        pageCount: _pdfPageCount * _copies, // Total pages to print
        fileUrl: fileUrl,
        colorMode: _colorMode,
        sides: _sides,
        price: _calculatedPrice,
        paymentId: paymentResult.paymentId,
        orderId: paymentResult.orderId,
        paymentStatus: 'paid', // Mark as paid since payment was successful
      );

      print('Adding print job to database: ${printJob.id}');
      final success = await _printService.addPrintJob(printJob);

      if (success) {
        _showSuccessDialog();
        _clearSelection();
        widget.onUploadComplete?.call();
      } else {
        throw Exception('Failed to create print job');
      }
    } catch (e) {
      print('Error in upload and payment flow: $e');
      _showErrorDialog('Upload Error', e.toString());
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _simulateUploadProgress() {
    // Simulate upload progress for better UX
    Future.delayed(Duration(milliseconds: 100), () {
      if (_isUploading) {
        setState(() => _uploadProgress = 0.3);
        Future.delayed(Duration(milliseconds: 200), () {
          if (_isUploading) {
            setState(() => _uploadProgress = 0.7);
            Future.delayed(Duration(milliseconds: 300), () {
              if (_isUploading) {
                setState(() => _uploadProgress = 1.0);
              }
            });
          }
        });
      }
    });
  }

  String _generatePrintCode() {
    // Generate 2-digit print code
    final now = DateTime.now();
    return '${(now.millisecond % 90 + 10)}';
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _pdfPageCount = 0;
      _copies = 1;
      _colorMode = ColorMode.blackAndWhite;
      _sides = Sides.single;
      _calculatedPrice = 0.0;
      _isExtractingPages = false;
    });
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'No Internet Connection',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: Text(
          'Please check your internet connection and try again. File upload requires an active internet connection.',
          style: TextStyle(fontFamily: 'Unbounded', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadAndCreateJob(); // Retry the upload
            },
            child: Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: Color(0xFF00C853),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Unbounded', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: Color(0xFF00C853),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text(
              'Upload Successful',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: Text(
          'Your document has been uploaded and added to print queue.',
          style: TextStyle(fontFamily: 'Unbounded', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: Color(0xFF00C853),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
