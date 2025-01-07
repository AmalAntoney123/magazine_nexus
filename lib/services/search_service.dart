import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchResult {
  final String magazineId;
  final String magazineTitle;
  final String fileId;
  final int pageNumber;
  final int lineNumber;
  final String context;
  final String issueId;

  SearchResult({
    required this.magazineId,
    required this.magazineTitle,
    required this.fileId,
    required this.pageNumber,
    required this.lineNumber,
    required this.context,
    required this.issueId,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      magazineId: json['magazine_id'],
      magazineTitle: json['magazine_title'],
      fileId: json['file_id'],
      pageNumber: json['page_number'],
      lineNumber: json['line_number'],
      context: json['context'],
      issueId: json['issue_id'],
    );
  }
}

class SearchService {
  static const String baseUrl =
      'https://fast-api-nexus-eum7r6fi7-amal-antoneys-projects.vercel.app/api';

  static Future<List<SearchResult>> searchMagazines(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((result) => SearchResult.fromJson(result))
            .toList();
      } else {
        throw Exception('Failed to search magazines');
      }
    } catch (e) {
      throw Exception('Error searching magazines: $e');
    }
  }
}
