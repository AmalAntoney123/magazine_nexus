class MagazineIssue {
  final String id;
  final String magazineId;
  final String title;
  final String description;
  final String coverUrl;
  final String pdfFileId;
  final int issueNumber;
  final DateTime publishDate;
  final bool isPublished;

  MagazineIssue({
    required this.id,
    required this.magazineId,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.pdfFileId,
    required this.issueNumber,
    required this.publishDate,
    this.isPublished = false,
  });

  Map<String, dynamic> toJson() => {
        'magazineId': magazineId,
        'title': title,
        'description': description,
        'coverUrl': coverUrl,
        'pdfFileId': pdfFileId,
        'issueNumber': issueNumber,
        'publishDate': publishDate.toIso8601String(),
        'isPublished': isPublished,
      };
}
