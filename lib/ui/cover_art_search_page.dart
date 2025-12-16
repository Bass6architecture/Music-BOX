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
                var target = e.target;
                var img = target.tagName === 'IMG' ? target : target.closest('img');
                
                if (img && img.src) {
                  // Prevent default behavior (opening result) to show our preview first
                  e.preventDefault();
                  e.stopPropagation();
                  ImageClickChannel.postMessage(img.src);
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

      final response = await http.get(Uri.parse(url));
      
      if (mounted) Navigator.pop(context); // Dismiss loading

      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context, response.bodyBytes);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(AppLocalizations.of(context)!.error)),
           );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading if error
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
