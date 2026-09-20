# Velocity Mobile

Velocity Mobile is the official Flutter client for the Velocity Personal AI Assistant. It features a borderless monochrome aesthetic, true OLED pitch black theming, real-time Server-Sent Events (SSE) streaming, tactile haptics, Cloudflare Zero Trust authentication via QR code pairing, and deep memory integration powered by Hindsight.

---

## Features

- **Borderless Design System**: A pure dark interface utilizing true pitch black (#000000) for OLED displays and layered surface hierarchy without harsh divider lines or outlines.
- **Cloudflare Zero Trust Authentication**: 1-second camera QR code pairing from `chat.sathwik.work/mobile` with secure hardware-backed keychain/keystore storage (`flutter_secure_storage`) and manual JSON payload fallback.
- **Real-Time SSE Streaming**: Live token-by-token streaming response delivery with Server-Sent Events.
- **Cognitive Status Shimmer**: GlowingShimmerText widget with a 2.2-second ease-in-out radiant gradient wave indicating real-time cognitive phases (Fetching recall, Fetching mental model, Thinking, Searching...).
- **Slide-Over Navigation Drawer**: Flat list of past conversations with in-place rename (with automatic text pre-selection and keyboard Done submission) and permanent deletion confirmation dialog.
- **Mobile Ergonomics**:
  - Input capsule docked to the bottom by default, floating smoothly above the software keyboard when active.
  - Automatic keyboard focus on fresh app launch and new chat creation.
  - Keyboard automatically dismissed when opening previous chats or after sending a prompt.
  - Prompt scrolls smoothly to the top of the chat area upon submission with the assistant response streaming underneath.
  - Prompt long-press context menu positioned directly near the bubble with Copy and inline Edit Text.
  - Icon-only Copy and Regenerate buttons for assistant responses.
  - Inline Retry action on failed assistant messages.
  - Fluid bouncing scroll physics across chat messages and navigation drawer lists.
  - Smart floating scroll-to-bottom button when scrolled up.
- **Generation Parameters**: Modal bottom sheet for configuring reasoning effort (none to max), memory recall budget (low to high), and response verbosity (low to high) with tactile haptic feedback.
- **Memory Inspector**: Draggable bottom sheet for inspecting synthesized Hindsight mental models across categories (Current Context, User Persona, Projects & Decisions, Goals & Interests).
- **System Health Monitor**: Typography-driven status sheet inspecting backend, database (SQLite FTS5), and memory health.
- **Global Search**: Full-text search (FTS5) dialog across all conversation histories with search term highlight styling.

---

## Architecture and Directory Structure

```text
lib/
├── main.dart                      # App entry point, MultiProvider setup, theme configuration
├── models/
│   ├── chat_message.dart          # Chat message model with reasoning and streaming status
│   ├── health_details.dart        # System health status model
│   ├── mental_model_item.dart     # Hindsight mental model item model
│   ├── search_result.dart         # FTS5 search result model
│   └── session.dart               # Conversation session model with date grouping helpers
├── providers/
│   └── chat_provider.dart         # Core state management (sessions, streaming, parameters, theme)
├── services/
│   ├── api_service.dart           # HTTP & SSE client with Cloudflare Zero Trust headers
│   └── auth_service.dart          # Secure credential storage and QR payload handling
├── theme/
│   └── velocity_colors.dart       # Comprehensive dark/light color tokens
├── views/
│   ├── chat_view.dart             # Main chat interface, message stream, and docked input capsule
│   ├── health_details_sheet.dart  # System health details modal sheet
│   ├── main_screen.dart           # Root scaffold holding the slide-over drawer and chat view
│   ├── memory_inspector_sheet.dart# Draggable bottom sheet for Hindsight mental models
│   ├── onboarding_screen.dart     # QR code scanner onboarding with manual paste fallback
│   ├── options_bottom_sheet.dart  # Modal bottom sheet for generation parameters
│   ├── search_dialog.dart         # Full-text search dialog with match highlighting
│   └── sidebar_drawer.dart        # Slide-over navigation drawer with delete confirmations
└── widgets/
    ├── glowing_shimmer_text.dart  # Flowing gradient shimmer text widget
    ├── shimmer_text.dart          # Shimmer widget export
    └── velocity_mark.dart         # VelocityMark custom paint widget and brand mark
```

---

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0 < 4.0.0)
- Android SDK / Xcode for mobile compilation
- Velocity backend server running

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/sathwik-anumandla/velocity-mobile.git
   cd velocity-mobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

### Building the APK

To generate a release APK:
```bash
flutter build apk --release
```

The output file will be located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

To generate a debug APK:
```bash
flutter build apk --debug
```

The output file will be located at:
```text
build/app/outputs/flutter-apk/app-debug.apk
```

---

## Typography

- Primary Font: Satoshi (Weights: 400, 500, 700, 900)
- Monospace Font: JetBrains Mono (Weights: 400, 500, 700)

---

## License

Private and proprietary. All rights reserved.
