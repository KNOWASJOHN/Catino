import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/file_upload_service.dart';
import '../services/print_service.dart';
import 'print_history.dart';

class Upload extends StatefulWidget {
  final VoidCallback? onUploadComplete;
  
  const Upload({super.key, this.onUploadComplete});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final FileUploadService _fileUploadService = FileUploadService();
  final PrintService _printService = PrintService();
  final Connectivity _connectivity = Connectivity();
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  PlatformFile? _selectedFile;

  /// Check if device has internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      
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
          Icon(
            Icons.check_circle,
            size: 30,
            color: Colors.green,
          ),
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
        Icon(
          Icons.upload_file,
          size: 30,
          color: Colors.black87,
        ),
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
        });
      }
    } catch (e) {
      _showErrorDialog('File Selection Error', e.toString());
    }
  }

  Future<void> _uploadAndCreateJob() async {
    if (_selectedFile == null || _isUploading) return; // Prevent multiple uploads

    // Check internet connectivity first
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      _showNoInternetDialog();
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
      
      // Simulate upload progress
      _simulateUploadProgress();
      
      // Upload file to Supabase
      final fileUrl = await _fileUploadService.uploadFile(_selectedFile!, jobId);
      
      // Create print job with file URL
      final printJob = PrintJob(
        id: jobId,
        code: _generatePrintCode(),
        fileName: _selectedFile!.name,
        dateTime: DateTime.now(),
        status: PrintStatus.pending,
        pageCount: 1, // TODO: Extract from PDF
        fileUrl: fileUrl,
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
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 12,
          ),
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
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 12,
          ),
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
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 12,
          ),
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
