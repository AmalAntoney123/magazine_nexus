class Magazine {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String pdfFileId;
  final double price;
  final String frequency; // weekly, monthly, etc.
  final DateTime publishDate;
  final int issueNumber;
  final String category;
  final bool isActive;

  Magazine({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.pdfFileId,
    required this.price,
    required this.frequency,
    required this.publishDate,
    required this.issueNumber,
    required this.category,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'coverUrl': coverUrl,
        'pdfFileId': pdfFileId,
        'price': price,
        'frequency': frequency,
        'publishDate': publishDate.toIso8601String(),
        'issueNumber': issueNumber,
        'category': category,
        'isActive': isActive,
      };
}
