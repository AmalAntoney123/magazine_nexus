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
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  Future<void> loadPdf() async {
    setState(() => isLoading = true);
    try {
      print('Attempting to load PDF with ID: ${widget.fileId}');
      print('Using bucket ID: 67718396003a69711df7');

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
        print('Storage API Error: $storageError');

        final url = AppwriteService.getFileDownloadUrl(
          bucketId: '67718396003a69711df7',
          fileId: widget.fileId,
        );

        print('Fallback: Attempting to download PDF from: $url');

        final response = await http.get(
          url,
          headers: {
            'X-Appwrite-Project':
                AppwriteService.client.config['project']?.toString() ?? '',
            'Origin': 'http://localhost',
            'X-Requested-With': 'XMLHttpRequest',
          },
        );

        print('Response status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');

        if (response.statusCode != 200) {
          print('Response body: ${response.body}');
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
    } catch (e, stackTrace) {
      print('Error loading PDF: $e');
      print('Stack trace: $stackTrace');
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
        bottom: isReady
            ? PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Page ${currentPage + 1} of $totalPages',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : null,
        actions: [
          if (isReady) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () {
                setState(() {
                  _currentScale = (_currentScale + 0.25).clamp(1.0, 3.0);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () {
                setState(() {
                  _currentScale = (_currentScale - 0.25).clamp(1.0, 3.0);
                });
              },
            ),
          ],
        ],
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
                                        setState(() {
                                          currentPage--;
                                        });
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
                                        setState(() {
                                          currentPage++;
                                        });
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
      floatingActionButton: isReady
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Go to Page',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter page number (1-$totalPages)',
                                ),
                                onSubmitted: (value) {
                                  final page = int.tryParse(value);
                                  if (page != null &&
                                      page > 0 &&
                                      page <= totalPages!) {
                                    setState(() {
                                      currentPage = page - 1;
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Icon(Icons.search),
            )
          : null,
    );
  }
}
