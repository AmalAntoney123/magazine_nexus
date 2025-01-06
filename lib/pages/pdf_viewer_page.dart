import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../services/appwrite_service.dart';

class PdfViewerPage extends StatefulWidget {
  final String fileId;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.fileId,
    required this.title,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  bool isLoading = true;
  int? totalPages;
  int currentPage = 0;
  bool isReady = false;
  PDFViewController? pdfController;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    setState(() => isLoading = true);
    try {
      try {
        final bytes = await AppwriteService.storage.getFileDownload(
          bucketId: '67718396003a69711df7',
          fileId: widget.fileId,
        );

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.fileId}.pdf');
        await file.writeAsBytes(bytes);

        if (mounted) {
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        }
      } catch (storageError) {
        final url = AppwriteService.getFileDownloadUrl(
          bucketId: '67718396003a69711df7',
          fileId: widget.fileId,
        );

        final response = await http.get(
          url,
          headers: {
            'X-Appwrite-Project':
                AppwriteService.client.config['project']?.toString() ?? '',
            'Origin': 'http://localhost',
            'X-Requested-With': 'XMLHttpRequest',
          },
        );

        if (response.statusCode != 200) {
          throw Exception(
              'Failed to download PDF: ${response.statusCode} - ${response.body}');
        }

        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.fileId}.pdf');
        await file.writeAsBytes(bytes);

        if (mounted) {
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading PDF: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: loadPdf,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            )
          : localPath == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load PDF'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: loadPdf,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    PDFView(
                      filePath: localPath!,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      defaultPage: currentPage,
                      onRender: (pages) {
                        setState(() {
                          totalPages = pages;
                          isReady = true;
                        });
                      },
                      onViewCreated: (PDFViewController controller) {
                        pdfController = controller;
                      },
                      onPageChanged: (page, total) {
                        setState(() {
                          currentPage = page ?? 0;
                        });
                      },
                      onError: (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        }
                      },
                      onPageError: (page, error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error on page $page: $error'),
                            ),
                          );
                        }
                      },
                    ),
                    if (isReady)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FloatingActionButton(
                                heroTag: 'prev',
                                mini: true,
                                onPressed: currentPage > 0
                                    ? () {
                                        pdfController?.setPage(currentPage - 1);
                                      }
                                    : null,
                                child: const Icon(Icons.navigate_before),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Page ${currentPage + 1} of $totalPages',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              FloatingActionButton(
                                heroTag: 'next',
                                mini: true,
                                onPressed: totalPages != null &&
                                        currentPage < totalPages! - 1
                                    ? () {
                                        pdfController?.setPage(currentPage + 1);
                                      }
                                    : null,
                                child: const Icon(Icons.navigate_next),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
