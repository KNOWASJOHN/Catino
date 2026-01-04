import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

class PDFViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const PDFViewerPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  String? localFilePath;
  bool isLoading = true;
  bool isDownloading = false;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 0;
  PDFViewController? controller;

  @override
  void initState() {
    super.initState();
    _downloadAndDisplayPDF();
  }

  Future<void> _downloadAndDisplayPDF() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Download the PDF file
      final response = await http.get(Uri.parse(widget.url));
      
      if (response.statusCode == 200) {
        // Get application documents directory
        final dir = await getApplicationDocumentsDirectory();
        final fileName = widget.url.split('/').last;
        final file = File('${dir.path}/$fileName');
        
        // Write the PDF data to a local file
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() {
          localFilePath = file.path;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to download PDF. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error downloading PDF: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Unbounded'),
          ),
          backgroundColor: isError ? Colors.red : const Color(0xFF00C853),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 10 and below (API < 30), request storage permission
        // Android 11+ (API 30+) uses scoped storage and doesn't require permission
        // for accessing Downloads folder or app-specific directories
        
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            // Still allow download to app directory without permission
            return true;
          }
        }
      }
      return true;
    } catch (e) {
      // If permission request fails, continue with app directory download
      print('Permission request error: $e');
      return true;
    }
  }

  Future<void> _downloadToCustomLocation() async {
    try {
      setState(() => isDownloading = true);

      // Request appropriate storage permission based on Android version
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showMessage('Storage permission denied', isError: true);
        return;
      }

      // Let user choose download location
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory == null) {
        _showMessage('Download cancelled', isError: false);
        return;
      }

      // Download the PDF
      final response = await http.get(Uri.parse(widget.url));
      
      if (response.statusCode == 200) {
        final fileName = widget.title.isNotEmpty 
            ? '${widget.title}.pdf' 
            : widget.url.split('/').last;
        
        final file = File('$selectedDirectory/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        _showMessage('PDF downloaded to: ${file.path}', isError: false);
      } else {
        _showMessage('Failed to download PDF', isError: true);
      }
    } catch (e) {
      _showMessage('Error downloading: ${e.toString()}', isError: true);
    } finally {
      setState(() => isDownloading = false);
    }
  }

  Future<void> _downloadToDownloads() async {
    try {
      setState(() => isDownloading = true);

      // Download the PDF
      final response = await http.get(Uri.parse(widget.url));
      
      if (response.statusCode == 200) {
        final fileName = widget.title.isNotEmpty 
            ? '${widget.title}.pdf' 
            : widget.url.split('/').last;
        
        Directory? targetDirectory;
        String locationMessage = '';
        
        if (Platform.isAndroid) {
          try {
            // For Android 11+ (API 30+), use app-specific external storage
            // This doesn't require permissions and is accessible via file managers
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              // Create a Downloads folder in app's external directory
              targetDirectory = Directory('${externalDir.path}/Downloads');
              if (!await targetDirectory.exists()) {
                await targetDirectory.create(recursive: true);
              }
              locationMessage = 'Android/data/cantino/files/Downloads';
            }
          } catch (e) {
            print('Error accessing external storage: $e');
          }
        }
        
        // Fallback to app documents directory
        if (targetDirectory == null) {
          targetDirectory = await getApplicationDocumentsDirectory();
          locationMessage = 'app documents folder';
        }
        
        final file = File('${targetDirectory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        _showMessage('PDF saved to $locationMessage', isError: false);
      } else {
        _showMessage('Failed to download PDF', isError: true);
      }
    } catch (e) {
      _showMessage('Error downloading: ${e.toString()}', isError: true);
    } finally {
      setState(() => isDownloading = false);
    }
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF00C853).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFF00C853)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: isEnabled
                ? const Color(0xFF00C853)
                : Colors.grey.withOpacity(0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Viewing Options',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.download_rounded,
              title: 'Quick Download',
              subtitle: 'Save to app folder',
              onTap: () {
                Navigator.pop(context);
                _downloadToDownloads();
              },
            ),
            _buildOptionTile(
              icon: Icons.file_download_rounded,
              title: 'Download PDF',
              subtitle: 'Save to custom location',
              onTap: () {
                Navigator.pop(context);
                _downloadToCustomLocation();
              },
            ),
            _buildOptionTile(
              icon: Icons.info_rounded,
              title: 'Document Info',
              subtitle: 'View document details',
              onTap: () {
                Navigator.pop(context);
                _showDocumentInfo();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00C853),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Document Information',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('Name', widget.title),
            _buildInfoRow('Status', localFilePath != null ? 'Loaded' : 'Loading...'),
            if (totalPages > 0) ...[
              _buildInfoRow('Pages', '$totalPages'),
              _buildInfoRow('Current Page', '${currentPage + 1}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: const Color(0xFF00C853),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: isDownloading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.file_download_rounded),
            tooltip: 'Download to custom location',
            onPressed: isDownloading ? null : _downloadToCustomLocation,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: totalPages > 0
          ? Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: currentPage > 0
                        ? () async => await controller!.setPage(currentPage - 1)
                        : null,
                    isEnabled: currentPage > 0,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Page ${currentPage + 1} of $totalPages',
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: currentPage < totalPages - 1
                        ? () async => await controller!.setPage(currentPage + 1)
                        : null,
                    isEnabled: currentPage < totalPages - 1,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error Loading PDF',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      errorMessage = null;
                    });
                    _downloadAndDisplayPDF();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Main PDF viewing area
    return Container(
      color: const Color(0xFF1A1A1A),
      child: localFilePath != null
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
                  child: PDFView(
                    filePath: localFilePath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageSnap: true,
                    pageFling: true,
                    backgroundColor: Colors.white,
                    onRender: (pages) {
                      setState(() => totalPages = pages!);
                    },
                    onViewCreated: (PDFViewController pdfViewController) {
                      controller = pdfViewController;
                    },
                    onPageChanged: (page, total) {
                      setState(() => currentPage = page!);
                    },
                  ),
                )
              : Center(
                  child: Text(
                    'No PDF to display',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
    );
  }
}