import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import '../../utils/config.dart';

class AttachmentViewer extends StatefulWidget {
  final Map<String, dynamic> attachment;
  final String title;

  const AttachmentViewer({
    super.key,
    required this.attachment,
    this.title = '',
  });

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  String get _fullUrl {
    final relativeUrl = widget.attachment['url']?.toString() ?? '';
    if (relativeUrl.startsWith('http')) {
      return relativeUrl;
    }
    return '${AppConfig.baseUrl}$relativeUrl';
  }

  String get _filename {
    return widget.attachment['filename']?.toString() ?? 'Attachment';
  }

  String get _mimetype {
    return widget.attachment['mimetype']?.toString() ?? '';
  }

  bool get _isImage {
    return _mimetype.startsWith('image/');
  }

  bool get _isPdf {
    return _mimetype == 'application/pdf';
  }

  bool _isRTL(BuildContext context) {
    final locale = context.locale;
    return ['ar', 'ckb', 'ku', 'bhn', 'arc', 'bad', 'bdi', 'sdh', 'kmr'].contains(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _isRTL(context);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(isRTL ? CupertinoIcons.forward : CupertinoIcons.back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.title.isNotEmpty ? widget.title : _filename,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isImage) {
      return _buildImageViewer();
    } else if (_isPdf) {
      return _buildPdfViewer();
    } else {
      return _buildUnsupportedViewer();
    }
  }

  Widget _buildImageViewer() {
    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              _fullUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  // Image loaded successfully
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _isLoading) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  });
                  return child;
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(
                        radius: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      if (loadingProgress.expectedTotalBytes != null)
                        Text(
                          '${((loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget('Failed to load image');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfViewer() {
    // For PDFs, we'll show an embedded WebView-like preview
    // Since we don't have a PDF viewer package, we'll use a simple web approach
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.doc_fill,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _filename,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'PDF Document',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          // Open in browser button
          ElevatedButton.icon(
            onPressed: () => _openInBrowser(),
            icon: const Icon(CupertinoIcons.globe),
            label: Text('common.open_in_browser'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.doc,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _filename,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _mimetype.isNotEmpty ? _mimetype : 'Unknown file type',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openInBrowser(),
            icon: const Icon(CupertinoIcons.globe),
            label: Text('common.open_in_browser'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.red,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(CupertinoIcons.refresh),
            label: Text('common.retry'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_fullUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
