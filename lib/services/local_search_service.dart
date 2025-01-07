import 'package:appwrite/appwrite.dart';
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SearchResult {
  final String magazineId;
  final String magazineTitle;
  final String fileId;
  final String context;
  final int pageNumber;
  final String matchedText;

  SearchResult({
    required this.magazineId,
    required this.magazineTitle,
    required this.fileId,
    required this.context,
    required this.pageNumber,
    required this.matchedText,
  });
}

class LocalSearchService {
  static final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('676fc20b003ccf154826');

  static final storage = Storage(client);
  static final dio = Dio();

  static Future<List<SearchResult>> searchMagazines(String keyword) async {
    final List<SearchResult> results = [];

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Fetch files from Appwrite
      final files = await storage.listFiles(
        bucketId: '67718396003a69711df7',
      );

      for (var file in files.files) {
        // Download PDF file
        final filePath = '${tempDir.path}/${file.$id}.pdf';
        final pdfFile = File(filePath);

        // Only download if file doesn't exist
        if (!pdfFile.existsSync()) {
          final response = await dio.download(
            '${client.endPoint}/storage/buckets/67718396003a69711df7/files/${file.$id}/download',
            filePath,
            options: Options(
              headers: {
                'X-Appwrite-Project': '676fc20b003ccf154826',
              },
            ),
          );

          if (response.statusCode != 200) {
            continue;
          }
        }

        try {
          // Read and search PDF content using SyncfusionFlutterPdf
          final document = PdfDocument(inputBytes: await pdfFile.readAsBytes());

          for (var i = 0; i < document.pages.count; i++) {
            final PdfTextExtractor extractor = PdfTextExtractor(document);
            final pageText = extractor.extractText(startPageIndex: i);

            if (pageText.toLowerCase().contains(keyword.toLowerCase())) {
              // Find the line containing the keyword
              final lines = pageText.split('\n');
              for (var line in lines) {
                if (line.toLowerCase().contains(keyword.toLowerCase())) {
                  results.add(SearchResult(
                    magazineId: file.$id,
                    magazineTitle: file.name,
                    fileId: file.$id,
                    context: line.trim(),
                    matchedText: keyword,
                    pageNumber: i + 1,
                  ));
                }
              }
            }
          }

          // Dispose the document
          document.dispose();
        } catch (e) {
          print('Error processing PDF ${file.name}: $e');
          continue;
        }
      }

      return results;
    } catch (e) {
      print('Error searching magazines: $e');
      throw Exception('Failed to search magazines: $e');
    }
  }
}
