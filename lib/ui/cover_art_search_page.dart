import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:music_box/generated/app_localizations.dart';

class CoverArtSearchPage extends StatefulWidget {
  final String artist;
  final String title;

  const CoverArtSearchPage({
    super.key,
    required this.artist,
    required this.title,
  });

  @override
  State<CoverArtSearchPage> createState() => _CoverArtSearchPageState();
}

class _CoverArtSearchPageState extends State<CoverArtSearchPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final query = '${widget.artist} ${widget.title} cover art';
    final url = 'https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(query)}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            setState(() => _isLoading = false);
            // Inject click listener for images
            // We use a capture phase listener to intercept clicks on images
            await _controller.runJavaScript('''
              document.addEventListener('click', function(e) {
                // Find nearest anchor or image
                var target = e.target;
                var anchor = target.closest('a');
                var img = target.tagName === 'IMG' ? target : target.closest('img');
                
                var src = null;
                
                // 1. Prioritize explicit IMG tags
                if (img && img.src) {
                  src = img.src;
                } 
                // 2. Check anchor children if no direct image clicked
                else if (anchor) {
                   var childImg = anchor.querySelector('img');
                   if (childImg) src = childImg.src;
                }
                
                // 3. Check for background image on the clicked target
                if (!src) {
                  var style = window.getComputedStyle(target);
                  var bg = style.backgroundImage;
                  if (bg && bg.startsWith('url(')) {
                     src = bg.slice(4, -1).replace(/"/g, "");
                  }
                }

                if (src) {
                  // Prevent navigation to show preview
                  e.preventDefault();
                  e.stopPropagation();
                  ImageClickChannel.postMessage(src);
                }
              }, true);
            ''');
          },
        ),
      )
      ..addJavaScriptChannel(
        'ImageClickChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _showPreviewDialog(message.message);
        },
      )
      ..loadRequest(Uri.parse(url));
  }

  void _showPreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.preview),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Image.network(
                 imageUrl,
                 loadingBuilder: (ctx, child, loadingProgress) {
                   if (loadingProgress == null) return child;
                   return const Center(child: CircularProgressIndicator());
                 },
                 errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image, size: 50),
              ),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.useThisImageQuestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Close dialog, stay on webview
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _downloadAndReturn(imageUrl);
            },
            child: Text(AppLocalizations.of(context)!.useImage),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndReturn(String url) async {
    try {
      // Show loading overlay
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      Uint8List? bytes;

      if (url.startsWith('data:')) {
        // Handle Data URI
        final uri = Uri.parse(url);
        bytes = uri.data?.contentAsBytes();
      } else {
        // Handle standard URL
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          bytes = response.bodyBytes;
        }
      }
      
      if (mounted) Navigator.pop(context); // Dismiss loading

      if (bytes != null && bytes.isNotEmpty) {
        if (mounted) Navigator.pop(context, bytes);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(AppLocalizations.of(context)!.error)),
           );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Dismiss loading if error
      debugPrint('Error downloading image: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.artist} - ${widget.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
