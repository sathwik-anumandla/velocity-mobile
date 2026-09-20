class ChatMessage {
  final String id;
  String sessionId;
  final String role; // 'user' | 'assistant' | 'system'
  String content;
  final DateTime createdAt;
  String? memoryStatus;
  String? reasoning;
  String? statusText;
  bool isStreaming;
  double? durationSeconds;
  String? recallBudget;
  String? thinkingEffort;
  List<String> toolCalls;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.memoryStatus = 'ok',
    this.reasoning,
    this.statusText,
    this.isStreaming = false,
    this.durationSeconds,
    this.recallBudget,
    this.thinkingEffort,
    this.toolCalls = const [],
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      memoryStatus: json['memory_status'] as String? ?? 'ok',
      reasoning: json['reasoning'] as String?,
      statusText: json['status_text'] as String?,
      isStreaming: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      if (memoryStatus != null) 'memory_status': memoryStatus,
      if (reasoning != null) 'reasoning': reasoning,
      if (statusText != null) 'status_text': statusText,
    };
  }
}
