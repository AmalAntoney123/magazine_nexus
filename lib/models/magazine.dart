class Magazine {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final double price;
  final String frequency; // weekly, monthly, etc.
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime nextIssueDate;

  Magazine({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.price,
    required this.frequency,
    required this.category,
    required this.nextIssueDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'coverUrl': coverUrl,
        'price': price,
        'frequency': frequency,
        'category': category,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'nextIssueDate': nextIssueDate.toIso8601String(),
      };
}
