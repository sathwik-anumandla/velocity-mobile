class MentalModelItem {
  final String id;
  final String content;
  final bool isReady;

  MentalModelItem({
    required this.id,
    required this.content,
    required this.isReady,
  });

  factory MentalModelItem.fromJson(Map<String, dynamic> json) {
    return MentalModelItem(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      isReady: json['is_ready'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_ready': isReady,
    };
  }
}
