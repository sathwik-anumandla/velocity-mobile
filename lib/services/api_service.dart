import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/session.dart';
import '../models/chat_message.dart';
import '../models/search_result.dart';
import '../models/health_details.dart';
import '../models/mental_model_item.dart';
import 'auth_service.dart';

String _getDefaultBaseUrl() {
  const envUrl = String.fromEnvironment('API_URL');
  if (envUrl.isNotEmpty) return envUrl;
  return 'https://chat.sathwik.work';
}

class ApiService {
  String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? _getDefaultBaseUrl(),
        _client = http.Client();

  /// Injects Cloudflare Zero Trust headers
  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    final cfHeaders = await AuthService.getHeaders();
    if (extra != null) {
      cfHeaders.addAll(extra);
    }
    return cfHeaders;
  }

  /// Quick probe to check if a specific URL is healthy
  Future<bool> probeUrl(String url) async {
    try {
      final clean = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final headers = await _headers();
      final response = await _client
          .get(Uri.parse('$clean/health'), headers: headers)
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['backend'] == 'healthy' || data['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Auto-discovers working backend URL from candidate list
  Future<bool> autoDiscoverBackend() async {
    final authUrl = await AuthService.getBaseUrl();
    final candidates = [
      baseUrl,
      authUrl,
      'https://chat.sathwik.work',
      'http://192.168.0.140:8000',
      'http://localhost:8000',
      'http://10.0.2.2:8000',
    ];

    final seen = <String>{};
    for (final candidate in candidates) {
      if (candidate.isNotEmpty && seen.add(candidate)) {
        if (await probeUrl(candidate)) {
          baseUrl = candidate.endsWith('/') ? candidate.substring(0, candidate.length - 1) : candidate;
          return true;
        }
      }
    }
    return false;
  }

  /// Health Check
  Future<bool> checkHealth() async {
    try {
      final headers = await _headers();
      final response = await _client
          .get(Uri.parse('$baseUrl/health'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['backend'] == 'healthy';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Full System Health Check returning HealthDetails
  Future<HealthDetails> getHealthDetails() async {
    try {
      final headers = await _headers();
      final response = await _client
          .get(Uri.parse('$baseUrl/health'), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return HealthDetails.fromJson(data);
      }
      return HealthDetails(
        status: 'offline',
        backend: 'unreachable',
        hindsight: 'unreachable',
        database: 'unreachable',
      );
    } catch (_) {
      return HealthDetails(
        status: 'offline',
        backend: 'unreachable',
        hindsight: 'unreachable',
        database: 'unreachable',
      );
    }
  }

  /// Legacy map format health check
  Future<Map<String, dynamic>> getSystemHealth() async {
    final details = await getHealthDetails();
    return {
      'status': details.status,
      'backend': details.backend,
      'hindsight': details.hindsight,
      'database': details.database,
    };
  }

  /// Fetch Mental Models from Hindsight
  Future<List<MentalModelItem>> getMentalModels() async {
    try {
      final headers = await _headers();
      final response = await _client
          .get(Uri.parse('$baseUrl/memory/mental-models'), headers: headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items.map((e) => MentalModelItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// List persistent sessions
  Future<List<Session>> listSessions() async {
    final headers = await _headers();
    final response = await _client
        .get(Uri.parse('$baseUrl/sessions'), headers: headers)
        .timeout(const Duration(seconds: 6));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
      return list.map((item) => Session.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load sessions: ${response.statusCode}');
  }

  /// Create a new session
  Future<Session> createSession({
    String? name,
    String recallBudget = 'medium',
    String thinkingEffort = 'medium',
    String verbosity = 'low',
  }) async {
    final headers = await _headers({'Content-Type': 'application/json'});
    final response = await _client.post(
      Uri.parse('$baseUrl/sessions'),
      headers: headers,
      body: json.encode({
        if (name != null && name.isNotEmpty) 'name': name,
        'recall_budget': recallBudget,
        'thinking_effort': thinkingEffort,
        'verbosity': verbosity,
      }),
    );
    if (response.statusCode == 200) {
      return Session.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Failed to create session: ${response.statusCode}');
  }

  /// Update session name or sticky settings
  Future<Session> updateSession(
    String sessionId, {
    String? name,
    String? recallBudget,
    String? thinkingEffort,
    String? verbosity,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (recallBudget != null) body['recall_budget'] = recallBudget;
    if (thinkingEffort != null) body['thinking_effort'] = thinkingEffort;
    if (verbosity != null) body['verbosity'] = verbosity;

    final headers = await _headers({'Content-Type': 'application/json'});
    final response = await _client.patch(
      Uri.parse('$baseUrl/sessions/$sessionId'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return Session.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Failed to update session: ${response.statusCode}');
  }

  /// Delete session
  Future<bool> deleteSession(String sessionId) async {
    final headers = await _headers();
    final response = await _client.delete(Uri.parse('$baseUrl/sessions/$sessionId'), headers: headers);
    return response.statusCode == 200;
  }

  /// Truncate session messages from a given message ID onward
  Future<bool> truncateMessagesFrom(String sessionId, String fromMessageId) async {
    try {
      final uri = Uri.parse('$baseUrl/sessions/$sessionId/messages')
          .replace(queryParameters: {'from_message_id': fromMessageId});
      final headers = await _headers();
      final response = await _client.delete(uri, headers: headers);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get session message history
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    final headers = await _headers();
    final response = await _client.get(Uri.parse('$baseUrl/sessions/$sessionId'), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> msgList = data['messages'] ?? [];
      return msgList.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load messages for session $sessionId');
  }

  /// Search across all sessions using FTS5
  Future<List<SearchResult>> searchMessages(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {'q': query.trim()});
    final headers = await _headers();
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
      return list.map((item) => SearchResult.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to search messages');
  }

  /// SSE Stream Chat Turn according to MOBILE_SPEC.md Section 5
  Future<StreamSubscription<String>> streamChat({
    required String sessionId,
    required String message,
    String? messageId,
    String? recallBudget,
    String? thinkingEffort,
    String? verbosity,
    bool isTemporary = false,
    required Function(String status) onStatusText,
    required Function(String reasoningDelta) onReasoningDelta,
    required Function(String query) onToolStart,
    required Function() onToolDone,
    required Function(String deltaText) onDelta,
    required Function(String fullText, String memoryStatus, Map<String, dynamic> usage) onComplete,
    required Function(String error) onError,
    Function(String title)? onSessionRenamed,
  }) async {
    final request = http.Request('POST', Uri.parse('$baseUrl/chat/stream'));
    final headers = await _headers({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.headers.addAll(headers);
    request.body = json.encode({
      'session_id': sessionId,
      'message': message,
      if (messageId != null) 'message_id': messageId,
      if (recallBudget != null) 'recall_budget': recallBudget,
      if (thinkingEffort != null) 'thinking_effort': thinkingEffort,
      if (verbosity != null) 'verbosity': verbosity,
      'is_temporary': isTemporary,
    });

    final streamClient = http.Client();
    String? currentEvent;
    String fullAssistantText = '';

    try {
      final streamedResponse = await streamClient.send(request);
      final subscription = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.isEmpty) return;

          if (line.startsWith('event: ')) {
            currentEvent = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            try {
              final dataObj = json.decode(dataStr) as Map<String, dynamic>;

              if (currentEvent == 'session_renamed') {
                final name = dataObj['name'] as String?;
                if (name != null && onSessionRenamed != null) {
                  onSessionRenamed(name);
                }
              } else if (currentEvent == 'status') {
                final text = dataObj['text'] as String? ?? 'Thinking';
                onStatusText(text);
              } else if (currentEvent == 'agentic_step') {
                final msg = dataObj['message'] as String? ?? dataObj['step'] as String? ?? 'Planning';
                onStatusText(msg);
              } else if (currentEvent == 'thinking') {
                onStatusText('Thinking');
              } else if (currentEvent == 'reasoning_delta') {
                final rText = dataObj['text'] as String? ?? '';
                onReasoningDelta(rText);
              } else if (currentEvent == 'tool_start') {
                final tool = dataObj['tool'] as String? ?? '';
                final query = dataObj['query'] as String? ?? '';
                if (tool == 'tavily_search') {
                  onStatusText('Searching');
                } else if (tool == 'consult_memory') {
                  onStatusText('Consulting memory');
                } else if (tool == 'read_mental_model') {
                  onStatusText('Fetching mental model');
                } else {
                  onStatusText('Working...');
                }
                onToolStart(query);
              } else if (currentEvent == 'tool_done') {
                onToolDone();
              } else if (currentEvent == 'delta') {
                final text = dataObj['text'] as String? ?? '';
                fullAssistantText += text;
                onDelta(text);
              } else if (currentEvent == 'complete') {
                final text = dataObj['text'] as String? ?? fullAssistantText;
                final memoryStatus = dataObj['memory_status'] as String? ?? 'ok';
                final usage = (dataObj['usage'] as Map<String, dynamic>?) ?? {};
                onComplete(text, memoryStatus, usage);
              } else if (currentEvent == 'error') {
                final err = dataObj['error'] as String? ?? 'Unknown error';
                onError(err);
              }
            } catch (_) {
              if (currentEvent == 'delta') {
                fullAssistantText += dataStr;
                onDelta(dataStr);
              }
            }
          }
        },
        onError: (err) {
          onError(err.toString());
          streamClient.close();
        },
        onDone: () {
          streamClient.close();
        },
        cancelOnError: true,
      );

      return subscription;
    } catch (e) {
      onError(e.toString());
      streamClient.close();
      rethrow;
    }
  }
}
