# Velocity Mobile — Architecture, Design System & API Integration Spec

> **For AI Agents & Developers**: This document is the single source of truth for refining or building the Velocity Flutter mobile application to match Velocity Web's latest UI/UX, design system, and backend integration.

---

## 1. Design System & Theming (Flutter)

Velocity follows a **flat, borderless monochrome aesthetic** with high legibility, tactile interactions, and pure typography.

### 1.1 Core Rules
1. **No Borders**: Do NOT use `Border.all()`, outline borders, or divider lines where surface color contrast suffices. Hierarchy is established strictly through layered background surfaces (e.g. `bgPrimary` $\rightarrow$ `bgCard` $\rightarrow$ `bgModalInner`).
2. **Typography**: Use **Satoshi** font family (fallback to `Inter` / system font) with `FontWeight.w500` (Medium) as the base weight and `FontWeight.w600` for titles/headers.
3. **No Unnecessary Icons**: Avoid decorating labels with icons. Let clean typography and subtle badges do the work.
4. **Accent Accents**: Minimal. Subtle blue (`#93C5FD` dark / `#2563EB` light) for inline code & chips; emerald (`#10B981`) and amber (`#F59E0B`) exclusively for status dots.

### 1.2 Color Tokens

```dart
import 'package:flutter/material.dart';

class VelocityColors {
  // Dark Theme (Default)
  static const darkBgPrimary = Color(0xFF000000);
  static const darkBgSidebar = Color(0xFF0A0A0A);
  static const darkBgCard = Color(0xFF141414);
  static const darkBgCardHover = Color(0xFF1C1C20);
  static const darkBgInput = Color(0xFF141414);
  static const darkBgInputHover = Color(0xFF1C1C1E);
  static const darkBgPill = Color(0xFF27272A);
  static const darkBgPillHover = Color(0xFF343438);
  static const darkBgPopover = Color(0xFF1E1E22);
  static const darkBgModal = Color(0xFF141414);
  static const darkBgModalInner = Color(0xFF0A0A0A);
  static const darkBgCode = Color(0xFF0D0D10);
  static const darkBgCodeHeader = Color(0xFF141418);

  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFD4D4D8);
  static const darkTextMuted = Color(0xFFA1A1AA);
  static const darkTextDim = Color(0xFF71717A);
  static const darkAccentBlue = Color(0xFF93C5FD);
  static const darkAccentBlueBg = Color(0x331E293B);

  // Light Theme
  static const lightBgPrimary = Color(0xFFFFFFFF);
  static const lightBgSidebar = Color(0xFFF7F7F8);
  static const lightBgCard = Color(0xFFF4F4F5);
  static const lightBgCardHover = Color(0xFFECECEE);
  static const lightBgInput = Color(0xFFF4F4F5);
  static const lightBgInputHover = Color(0xFFEAEAEB);
  static const lightBgPill = Color(0xFFE4E4E7);
  static const lightBgPillHover = Color(0xFFD4D4D8);
  static const lightBgPopover = Color(0xFFFFFFFF);
  static const lightBgModal = Color(0xFFFFFFFF);
  static const lightBgModalInner = Color(0xFFF4F4F5);
  static const lightBgCode = Color(0xFFF8F8FA);
  static const lightBgCodeHeader = Color(0xFFF0F0F3);

  static const lightTextPrimary = Color(0xFF09090B);
  static const lightTextSecondary = Color(0xFF27272A);
  static const lightTextMuted = Color(0xFF71717A);
  static const lightTextDim = Color(0xFFA1A1AA);
  static const lightAccentBlue = Color(0xFF2563EB);
  static const lightAccentBlueBg = Color(0xFFEFF6FF);

  // Status Indicators
  static const statusOnline = Color(0xFF10B981);   // Emerald
  static const statusDegraded = Color(0xFFF59E0B); // Amber
  static const statusOffline = Color(0xFFEF4444);  // Red
}
```

---

## 2. ChatGPT-Style Flowing Shimmer Text Widget

The web app uses a 2.2-second linear gradient sweep across 200% width (`--text-dim` to `--text-primary` to `--text-dim`). Replicate this 1:1 in Flutter with `ShaderMask`:

```dart
import 'package:flutter/material.dart';

class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
              transform: _SlideGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double percent;
  const _SlideGradientTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Sweeps from -200% to +200%
    final dx = bounds.width * (percent * 4.0 - 2.0);
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}
```

---

## 3. Mobile UI & UX Interaction Patterns

### 3.1 Layout & Navigation (Drawer)
- Use a **Slide-over Drawer** (`Scaffold.drawer`) instead of a persistent sidebar.
- Open via hamburger icon in top `AppBar` or edge swipe gesture.
- **Top of Drawer**: New Chat button (`+ New Chat`), Temporary Chat toggle.
- **Middle of Drawer**: Search bar + scrollable session list grouped by date (Today, Yesterday, Previous 7 Days, Older).
- **Split Footer of Drawer**:
  - **Left**: Minimal status dot (Emerald/Amber/Red). Tapping opens a health details dialog or bottom sheet showing pure typography status of `Backend`, `Database`, `Memory`.
  - **Right**:
    - Brain icon (no text) $\rightarrow$ opens Memory Inspector bottom sheet.
    - Sun/Moon icon $\rightarrow$ toggles Theme.

### 3.2 Centered Hero $\rightarrow$ Docked Transition (Chat Screen)
- **New Chat (Empty State)**:
  - Center the greeting: `"What's on your mind today?"` in Satoshi 24sp w600.
  - Position the input capsule directly underneath the greeting in the middle of the screen (Claude/ChatGPT mobile style).
- **Active Chat (Messages Exist)**:
  - Input capsule docks to the bottom inside a `SafeArea(bottom: true)`.
  - Messages scroll behind the bottom dock with bottom padding so the last message is never obscured.

### 3.3 The Floating `+` Options Menu (Bottom Sheet)
On mobile, do **not** use a floating hover popover. Instead, tapping the `+` button in the input capsule opens a **Modal Bottom Sheet**:
- **Main Sheet**:
  - `effort`: shows current level (`none`, `low`, `medium`, `high`, `xhigh`, `max`).
  - `recall`: shows current level (`low`, `medium`, `high`).
  - `verbosity`: shows current level (`low`, `medium`, `high`).
  - Tapping any row opens the level picker (pill selector) with descriptive text.
- Provide subtle haptic feedback (`HapticFeedback.selectionClick()`) when selecting a level.

### 3.4 Cognitive Status Flow (Single-Line Shimmer)
- When the user sends a message, insert an assistant message placeholder immediately.
- Display a single line containing `ShimmerText`:
  - `Fetching recall` $\rightarrow$ `Fetching mental model` $\rightarrow$ `Thinking` $\rightarrow$ `Searching...`
- **Crucial**: As soon as the first token of the assistant's actual response arrives (`delta` event), **remove the shimmer line completely**. The text begins streaming smoothly in its place.

### 3.5 Smart Scroll-to-Bottom Pill
- When the user scrolls up by $>120\text{px}$ from the bottom:
  - Show a minimal circular button (36x36 dp) with an `ArrowDown` icon.
  - Position: Floating 16dp above the input capsule, centered horizontally or aligned to the right.
  - Tapping smoothly animates the `ScrollController` to the bottom (`0.0` or max extent depending on `reverse` property) and triggers `HapticFeedback.lightImpact()`.
  - Automatically hide the pill when keyboard is open or when user scrolls back to the bottom.

### 3.6 Memory Inspector (Draggable Bottom Sheet)
- Tapping the Brain icon in the drawer opens `DraggableScrollableSheet` (initial size 0.75, max 0.95).
- **Header**: Status dot + `"Hindsight Memory"` + Refresh button + Close button.
- **Category Filter Pills**: Horizontal scrollable list:
  1. `Current Context` (`current-context`)
  2. `User Persona` (`user-persona`)
  3. `Projects & Decisions` (`projects-and-decisions`)
  4. `Goals & Interests` (`goals-and-interests`)
- **Body**: Markdown viewer inside `bgModalInner` container rendering the synthesized memory text for the selected category. While loading, show centered `ShimmerText(text: "Loading memory")`.

### 3.7 Soft Keyboard & Touch Ergonomics
- Set `resizeToAvoidBottomInset: true` on `Scaffold`.
- In message `ListView`, set `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.
- On message long-press (`onLongPress`), show a native context menu / bottom sheet with:
  - `Copy Text`
  - `Retry Turn` (for user messages, calls message truncation and re-streams)
  - `Delete Turn`

---

## 4. API Endpoints Specification

Base URL: Configurable (e.g. `http://10.0.2.2:8000` for Android emulator, `http://localhost:8000` for iOS simulator, or Cloudflare Tunnel URL in production).

### 4.1 Health Check
- **Endpoint**: `GET /health`
- **Response**:
```json
{
  "status": "ok",
  "backend": "healthy",
  "hindsight": "healthy",
  "database": "healthy"
}
```

### 4.2 Sessions
- **List Sessions**: `GET /sessions`
  - Returns `Session[]` sorted by `updated_at` desc.
- **Create Session**: `POST /sessions`
  - Request: `{"name": string?, "recall_budget": string?, "thinking_effort": string?, "verbosity": string?}`
  - Returns: `Session`
- **Get Session Messages**: `GET /sessions/{session_id}`
  - Returns: `{"session": Session, "messages": ChatMessage[]}`
- **Update Session**: `PATCH /sessions/{session_id}`
  - Request: `{"name"?: string, "recall_budget"?: string, "thinking_effort"?: string, "verbosity"?: string}`
  - Returns: `Session`
- **Delete Session**: `DELETE /sessions/{session_id}`
  - Returns: `{"status": "ok"}`
- **Truncate Messages (Edit/Retry)**: `DELETE /sessions/{session_id}/messages?from_message_id={message_id}`
  - Deletes all messages from `message_id` onwards to allow clean re-generation.

### 4.3 Search Messages
- **Endpoint**: `GET /search?q={query}`
- **Response**: `SearchResult[]`

### 4.4 Mental Models (Hindsight)
- **Endpoint**: `GET /memory/mental-models`
- **Response**:
```json
{
  "items": [
    { "id": "current-context", "content": "# Current Context\n...", "is_ready": true },
    { "id": "user-persona", "content": "# User Persona\n...", "is_ready": true },
    { "id": "projects-and-decisions", "content": "# Projects & Decisions\n...", "is_ready": true },
    { "id": "goals-and-interests", "content": "# Goals & Interests\n...", "is_ready": true }
  ]
}
```

---

## 5. SSE Streaming Chat Protocol (`/chat/stream`)

- **Endpoint**: `POST /chat/stream`
- **Headers**: `Content-Type: application/json`, `Accept: text/event-stream`
- **Request Payload**:
```json
{
  "session_id": "uuid-string",
  "message": "User's query",
  "message_id": "optional-uuid-for-retry",
  "recall_budget": "medium",
  "thinking_effort": "medium",
  "verbosity": "low",
  "is_temporary": false
}
```

### 5.1 Server-Sent Events Breakdown

The server streams raw SSE lines (`event: <name>\ndata: <json>\n\n`):

| Event | Data Format | Meaning & UI Action |
| :--- | :--- | :--- |
| `session_renamed` | `{"name": "New Title"}` | Update session title in drawer and app bar. |
| `status` | `{"text": "Consulting memory..."}` | Update the single-line cognitive shimmer text. |
| `agentic_step` | `{"step": "plan", "message": "Planning response"}` | Update cognitive status. |
| `thinking` | `{}` | Set cognitive status to `"Thinking"`. |
| `reasoning_delta` | `{"text": "reasoning tokens..."}` | Append to message `reasoning` field (collapsible accordion). |
| `tool_start` | `{"tool": "tavily_search", "query": "..."}` | If `tavily_search` $\rightarrow$ status: `"Searching"`. If `consult_memory` $\rightarrow$ status: `"Consulting memory"`. If `read_mental_model` $\rightarrow$ status: `"Fetching mental model"`. |
| `tool_done` | `{"tool": "tavily_search", "result": "..."}` | Mark tool execution finished. |
| `delta` | `{"text": "streamed token"}` | **Remove cognitive shimmer line**. Append token to assistant message markdown content. |
| `complete` | `{"text": "full text", "memory_status": "ok", "usage": {...}}` | Finalize message. Save state. |
| `error` | `{"error": "error message"}` | Show error snackbar/pill. |

---

## 6. Dart Data Models

```dart
enum ThinkingEffort { none, low, medium, high, xhigh, max }
enum RecallBudget { low, medium, high }
enum Verbosity { low, medium, high }

class Session {
  final String id;
  final String name;
  final RecallBudget recallBudget;
  final ThinkingEffort thinkingEffort;
  final Verbosity verbosity;
  final String createdAt;
  final String updatedAt;
  final bool isTemporary;

  Session({
    required this.id,
    required this.name,
    this.recallBudget = RecallBudget.medium,
    this.thinkingEffort = ThinkingEffort.medium,
    this.verbosity = Verbosity.low,
    required this.createdAt,
    required this.updatedAt,
    this.isTemporary = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] ?? '',
      name: json['name'] ?? 'New Chat',
      recallBudget: RecallBudget.values.firstWhere(
        (e) => e.name == json['recall_budget'],
        orElse: () => RecallBudget.medium,
      ),
      thinkingEffort: ThinkingEffort.values.firstWhere(
        (e) => e.name == json['thinking_effort'],
        orElse: () => ThinkingEffort.medium,
      ),
      verbosity: Verbosity.values.firstWhere(
        (e) => e.name == json['verbosity'],
        orElse: () => Verbosity.low,
      ),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isTemporary: json['is_temporary'] ?? false,
    );
  }
}

class ChatMessage {
  final String id;
  final String sessionId;
  final String role; // 'user' | 'assistant' | 'system'
  String content;
  final String createdAt;
  String? memoryStatus;
  String? reasoning;
  String? statusText;
  bool isStreaming;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.memoryStatus,
    this.reasoning,
    this.statusText,
    this.isStreaming = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
      memoryStatus: json['memory_status'],
    );
  }
}

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
}

class HealthDetails {
  final String status;
  final String backend;
  final String hindsight;
  final String database;

  HealthDetails({
    required this.status,
    required this.backend,
    required this.hindsight,
    required this.database,
  });

  factory HealthDetails.fromJson(Map<String, dynamic> json) {
    return HealthDetails(
      status: json['status'] ?? 'offline',
      backend: json['backend'] ?? 'unreachable',
      hindsight: json['hindsight'] ?? 'unreachable',
      database: json['database'] ?? 'unreachable',
    );
  }
}
```

---

## 7. Step-by-Step Instructions for Antigravity in Mobile Repo

When you start your session in the Flutter repository:
1. **Drop this file** into the root of your Flutter project as `MOBILE_SPEC.md`.
2. **Prompt Antigravity**:
   > *"Read `MOBILE_SPEC.md` and refine the mobile app to adhere to the design system, the borderless aesthetic, the flowing text shimmer, the drawer navigation with split footer, the bottom sheets for options and memory inspection, and the SSE streaming protocol."*
3. **Verify Packages**: Ensure `flutter_markdown`, `http`, `shared_preferences` (or Hive), and `flutter_animate` (or custom `AnimationController`) are in `pubspec.yaml`.
