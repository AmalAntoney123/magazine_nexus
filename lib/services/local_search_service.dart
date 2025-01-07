import 'package:appwrite/appwrite.dart';
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';

class SearchResult {
  final String magazineId;
  final String magazineTitle;
  final int issueNumber;
  final String pdfFileId;

  final String issueId;
  final String fileId;
  final String coverUrl;
  final String context;
  final int pageNumber;
  final int lineNumber;
  final String matchedText;
  final String magazineDescription;
  final double magazinePrice;
  final DateTime publishDate;
  final String frequency;

  SearchResult({
    required this.magazineId,
    required this.magazineTitle,
    required this.issueNumber,
    required this.issueId,
    required this.fileId,
    required this.coverUrl,
    required this.pdfFileId,
    required this.context,
    required this.pageNumber,
    required this.lineNumber,
    required this.matchedText,
    required this.magazineDescription,
    required this.magazinePrice,
    required this.publishDate,
    required this.frequency,
  });
}

class LocalSearchService {
  static final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('676fc20b003ccf154826');

  static final storage = Storage(client);
  static final dio = Dio();

  static Future<List<SearchResult>> searchMagazines(String keyword) async {
    List<SearchResult> results = [];

    // Get magazine and issue data from Firebase
    final magazinesSnapshot =
        await FirebaseDatabase.instance.ref().child('magazines').get();

    final issuesSnapshot =
        await FirebaseDatabase.instance.ref().child('magazine_issues').get();

    final magazines = Map<String, dynamic>.from(magazinesSnapshot.value as Map);
    final issues = Map<String, dynamic>.from(issuesSnapshot.value as Map);

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
              final lines = pageText.split('\n');
              for (int lineNum = 0; lineNum < lines.length; lineNum++) {
                final line = lines[lineNum];
                if (line.toLowerCase().contains(keyword.toLowerCase())) {
                  // Find corresponding magazine and issue data
                  final issue = issues.entries
                      .firstWhere((e) => e.value['pdfFileId'] == file.$id);
                  final magazine = magazines[issue.value['magazineId']];

                  results.add(SearchResult(
                    magazineId: issue.value['magazineId'],
                    magazineTitle: magazine['title'],
                    issueNumber: issue.value['issueNumber'] ?? 1,
                    issueId: issue.key,
                    fileId: file.$id,
                    pdfFileId: issue.value['pdfFileId'] ?? '',
                    coverUrl: issue.value['coverUrl'] ?? '',
                    context: line.trim(),
                    pageNumber: i + 1,
                    lineNumber: lineNum + 1,
                    matchedText: keyword,
                    magazineDescription: magazine['description'],
                    magazinePrice: (magazine['price'] as num).toDouble(),
                    publishDate: DateTime.parse(issue.value['publishDate']),
                    frequency: magazine['frequency'] ?? 'monthly',
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
