import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../theme/velocity_colors.dart';
import '../widgets/glowing_shimmer_text.dart';
import 'options_bottom_sheet.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isInputMultiLine = false;
  bool _showScrollToBottom = false;

  int? _editingMessageIndex;
  final TextEditingController _editController = TextEditingController();
  String? _copiedId;
  Timer? _copyTimer;
  Timer? _initFocusTimer;

  String? _lastSessionId;
  bool _wasLoadingMessages = false;
  int _lastMessageCount = 0;

  final GlobalKey _lastUserPromptKey = GlobalKey();
  bool _justSubmittedPrompt = false;
  bool _isKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    _scrollController.addListener(_onScrollChanged);

    // Fix #3: Open keyboard by default on fresh open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFocusTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted && context.read<ChatProvider>().currentSession == null && context.read<ChatProvider>().messages.isEmpty) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  void _onInputChanged() {
    final isMulti = _inputController.text.contains('\n') || _inputController.text.length > 50;
    if (isMulti != _isInputMultiLine) {
      setState(() {
        _isInputMultiLine = isMulti;
      });
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final isNearBottom = _scrollController.position.maxScrollExtent - _scrollController.position.pixels < 120;
    if (_showScrollToBottom != !isNearBottom) {
      setState(() {
        _showScrollToBottom = !isNearBottom;
      });
    }
  }

  @override
  void dispose() {
    _initFocusTimer?.cancel();
    _inputController.removeListener(_onInputChanged);
    _scrollController.removeListener(_onScrollChanged);
    _copyTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToPromptTop() {
    if (!_scrollController.hasClients) return;

    if (_lastUserPromptKey.currentContext != null) {
      Scrollable.ensureVisible(
        _lastUserPromptKey.currentContext!,
        alignment: 0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleSubmit() {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _inputController.clear();

    _justSubmittedPrompt = true;
    _focusNode.unfocus();

    context.read<ChatProvider>().sendMessage(text);

    // Fix 2: Prompt goes up till the top of display (below the title)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToPromptTop();
    });
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _scrollToPromptTop();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scrollToPromptTop();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _scrollToPromptTop();
        _justSubmittedPrompt = false;
      }
    });
  }

  void _copyToClipboard(String id, String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    _copyTimer?.cancel();
    setState(() {
      _copiedId = id;
    });
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedId = null;
        });
      }
    });
  }

  void _showPromptContextMenu(BuildContext context, ChatMessage msg, int index, Offset tapPosition) async {
    // Fix #2: Medium impact on hold rather than heavy
    HapticFeedback.mediumImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx - 40,
        tapPosition.dy - 10,
        MediaQuery.of(context).size.width - tapPosition.dx,
        MediaQuery.of(context).size.height - tapPosition.dy,
      ),
      color: cardBg,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.copy, size: 15, color: textPrimary),
              const SizedBox(width: 10),
              Text('Copy', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textPrimary)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.pencil, size: 15, color: textPrimary),
              const SizedBox(width: 10),
              Text('Edit Text', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textPrimary)),
            ],
          ),
        ),
      ],
    );

    if (selected == 'copy') {
      _copyToClipboard('user_${msg.id}', msg.content);
    } else if (selected == 'edit') {
      HapticFeedback.selectionClick();
      setState(() {
        _editingMessageIndex = index;
        _editController.text = msg.content;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgScaffold = isDark ? VelocityColors.darkBgPrimary : VelocityColors.lightBgPrimary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;

    final currentSessionId = provider.currentSession?.id;
    if (currentSessionId != _lastSessionId) {
      _lastSessionId = currentSessionId;
      _lastMessageCount = provider.messages.length;
      _scrollToBottom();
      // Fix #2: If opening previous chat, do NOT open keyboard; only open on new chat
      if (provider.currentSession == null && provider.messages.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && provider.currentSession == null && provider.messages.isEmpty) {
            _focusNode.requestFocus();
          }
        });
      } else {
        _focusNode.unfocus();
      }
    } else if (_wasLoadingMessages && !provider.isLoadingMessages) {
      _lastMessageCount = provider.messages.length;
      _scrollToBottom();
      // Fix #2: Ensure keyboard stays dismissed after previous chat messages load
      if (provider.currentSession != null) {
        _focusNode.unfocus();
      }
    } else if (provider.messages.length != _lastMessageCount) {
      // If messages became empty (e.g. New Chat started), request focus
      if (provider.currentSession == null && provider.messages.isEmpty && _lastMessageCount > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && provider.currentSession == null && provider.messages.isEmpty) {
            _focusNode.requestFocus();
          }
        });
      }
      _lastMessageCount = provider.messages.length;
      if (!_justSubmittedPrompt) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.position.pixels;
          if (maxScroll - currentScroll < 120) {
            _scrollToBottom();
          }
        }
      }
    }
    _wasLoadingMessages = provider.isLoadingMessages;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardNowOpen = bottomInset > 0;

    if (isKeyboardNowOpen != _isKeyboardOpen) {
      final wasOpen = _isKeyboardOpen;
      _isKeyboardOpen = isKeyboardNowOpen;

      if (isKeyboardNowOpen && !wasOpen) {
        // Fix 1: When opening keyboard in previous chat, bottom of chat goes UP above keyboard
        if (!_justSubmittedPrompt && provider.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      } else if (!isKeyboardNowOpen && wasOpen) {
        // Fix 1: When closing keyboard, bottom of chat goes DOWN
        if (!_justSubmittedPrompt && provider.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutQuad,
                );
              }
            }
          });
        }
      }
    }

    final showFloatingScrollButton = _showScrollToBottom && !isKeyboardNowOpen && provider.messages.isNotEmpty;

    // Fix #1: Proper top spacing accounting for notch / status bar with reduced bottom padding
    final topPadding = MediaQuery.of(context).padding.top;
    final topSpacer = (topPadding > 0 ? topPadding : 14) + 46.0;

    return Container(
      color: bgScaffold,
      child: Stack(
        children: [
          // 1. Full Body Content
          Positioned.fill(
            child: Column(
              children: [
                // Top Safe Area Spacer for Floating Header below notch
                SizedBox(height: topSpacer),

                // Main Body: Centered greeting when empty, or Messages stream when active
                if (provider.isLoadingMessages)
                  const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                else if (provider.messages.isEmpty)
                  // Fix #5: Greeting stays in the middle of the screen in new chats
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          "What's on your mind today?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Messages Stream
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      controller: _scrollController,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        provider.isGenerating ? MediaQuery.of(context).size.height * 0.75 : 90,
                      ),
                      itemCount: provider.messages.length,
                      itemBuilder: (ctx, idx) {
                        final msg = provider.messages[idx];
                        return _buildMessageTile(ctx, provider, msg, idx, isDark, textPrimary, textMuted);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. Fix #5: Message box sticks to bottom by default, even in new chats, and moves up with keyboard
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: _buildInputCapsule(context, provider, isDark, textPrimary, textMuted),
              ),
            ),
          ),

          // 3. Smart Scroll-to-Bottom Pill
          if (showFloatingScrollButton)
            Positioned(
              right: 20,
              bottom: 76,
              child: Material(
                color: isDark ? VelocityColors.darkBgPill : VelocityColors.lightBgPill,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _scrollToBottom();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(LucideIcons.arrowDown, size: 16, color: textPrimary),
                  ),
                ),
              ),
            ),

          // 4. Floating Header (Fix #1: Below notch with comfortable padding)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeaderBar(context, provider, isDark, textPrimary, textMuted, topPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(
    BuildContext context,
    ChatProvider provider,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    double topPadding,
  ) {
    final isNewChat = provider.messages.isEmpty;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            top: topPadding > 0 ? topPadding + 6 : 14,
            bottom: 6,
            left: 14,
            right: 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xD9000000),
                      const Color(0x66000000),
                      const Color(0x00000000),
                    ]
                  : [
                      const Color(0xD9FFFFFF),
                      const Color(0x66FFFFFF),
                      const Color(0x00FFFFFF),
                    ],
              stops: const [0.0, 0.75, 1.0],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Hamburger Menu Icon
              Builder(
                builder: (ctx) => IconButton(
                  tooltip: 'Menu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: Icon(LucideIcons.menu, size: 20, color: textPrimary),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Scaffold.of(ctx).openDrawer();
                  },
                ),
              ),

              // Center: Chat Title with comfortable padding, perfectly centered
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: provider.isTemporary
                        ? Text(
                            'Temporary Chat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          )
                        : (provider.currentSession == null
                            ? Text(
                                'Velocity',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              )
                            : Text(
                                provider.currentSession!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              )),
                  ),
                ),
              ),

              // Right: Temporary Chat toggle ONLY on New Chat; balanced 40px spacing when in active chat
              if (isNewChat)
                IconButton(
                  tooltip: provider.isTemporary ? 'Temporary Chat Active' : 'Temporary Chat',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: Icon(
                    LucideIcons.ghost,
                    size: 18,
                    color: provider.isTemporary ? textPrimary : textMuted,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    provider.toggleTemporary();
                  },
                )
              else
                const SizedBox(width: 40), // Balances the 40px left hamburger icon
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTile(
    BuildContext context,
    ChatProvider provider,
    ChatMessage msg,
    int index,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    if (msg.isUser) {
      Offset tapPosition = Offset.zero;
      final isLastUser = index == provider.messages.lastIndexWhere((m) => m.isUser);

      if (_editingMessageIndex == index) {
        // Inline Edit Mode
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _editController,
                  maxLines: 4,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _editingMessageIndex = null);
                      },
                      child: Text('Cancel', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: textPrimary,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final text = _editController.text.trim();
                        if (text.isNotEmpty) {
                          HapticFeedback.lightImpact();
                          setState(() => _editingMessageIndex = null);
                          provider.editAndResendPrompt(index, text);
                        }
                      },
                      child: const Text('Save & Submit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      return GestureDetector(
        key: isLastUser ? _lastUserPromptKey : null,
        onTapDown: (details) => tapPosition = details.globalPosition,
        onLongPress: () => _showPromptContextMenu(context, msg, index, tapPosition),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              msg.content,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ),
      );
    } else {
      // Assistant Message
      final isLastAssistant = index == provider.messages.length - 1;
      final showCognitiveShimmer = msg.isStreaming &&
          msg.content.isEmpty &&
          msg.statusText != null &&
          isLastAssistant;

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exact GlowingShimmerText Widget
            if (showCognitiveShimmer)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlowingShimmerText(
                      text: msg.statusText!,
                      isDarkMode: isDark,
                    ),
                  ],
                ),
              ),

            // Collapsible Reasoning Accordion (if reasoning exists)
            if (msg.reasoning != null && msg.reasoning!.isNotEmpty)
              _ReasoningAccordion(
                reasoning: msg.reasoning!,
                isDark: isDark,
                textMuted: textMuted,
                textPrimary: textPrimary,
              ),

            // Streamed Markdown Content
            if (msg.content.isNotEmpty)
              MarkdownBody(
                data: _tightenMarkdownLists(msg.content),
                selectable: true,
                builders: {
                  'code': CustomCodeElementBuilder(isDark: isDark, textMuted: textMuted),
                },
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 15.5, color: textPrimary, height: 1.55, fontWeight: FontWeight.w500),
                  pPadding: const EdgeInsets.only(bottom: 6.0),
                  strong: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
                  h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
                  h1Padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                  h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                  h2Padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
                  h3: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                  code: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.5,
                    color: isDark ? VelocityColors.darkAccentBlue : VelocityColors.lightAccentBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  codeblockDecoration: const BoxDecoration(color: Colors.transparent),
                  blockquote: TextStyle(
                    fontSize: 14,
                    color: isDark ? VelocityColors.darkTextSecondary : VelocityColors.lightTextSecondary,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
                        width: 3.0,
                      ),
                    ),
                  ),
                  blockquotePadding: const EdgeInsets.only(left: 14, top: 4, bottom: 4, right: 8),
                  listBullet: TextStyle(fontSize: 15.5, color: textPrimary, height: 1.25, fontWeight: FontWeight.w500),
                  listIndent: 18.0,
                  blockSpacing: 4.0,
                ),
              ),

            // Assistant Actions: Retry button if error, else Copy and Regenerate buttons (ONLY ICONS, NO TEXT)
            if (!provider.isGenerating && msg.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: (msg.content.startsWith('[Error:') ||
                        msg.content.startsWith('I encountered an issue generating a response:') ||
                        msg.content.startsWith('Error:'))
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            provider.regenerateLastAssistant();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.rotateCcw, size: 13, color: textPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _copyToClipboard('assistant_${msg.id}', msg.content),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                _copiedId == 'assistant_${msg.id}' ? LucideIcons.check : LucideIcons.copy,
                                size: 15,
                                color: _copiedId == 'assistant_${msg.id}' ? textPrimary : textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              provider.regenerateLastAssistant();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(LucideIcons.rotateCcw, size: 15, color: textMuted),
                            ),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildInputCapsule(
    BuildContext context,
    ChatProvider provider,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final inputBg = isDark ? VelocityColors.darkBgInput : VelocityColors.lightBgInput;
    final pillBg = isDark ? VelocityColors.darkBgPill : VelocityColors.lightBgPill;

    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: _isInputMultiLine ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          // Left '+' Button -> opens OptionsBottomSheet
          Material(
            color: pillBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                OptionsBottomSheet.show(context);
              },
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: Icon(LucideIcons.plus, size: 18, color: textPrimary),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Message Input Field
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              autofocus: provider.currentSession == null && provider.messages.isEmpty,
              maxLines: 5,
              minLines: 1,
              textAlignVertical: TextAlignVertical.center,
              cursorHeight: 18,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Message Velocity...',
                hintStyle: TextStyle(color: textMuted, fontSize: 15, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send / Progress Button
          Material(
            color: pillBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: provider.isGenerating ? null : _handleSubmit,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: provider.isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(LucideIcons.arrowUp, size: 18, color: textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasoningAccordion extends StatefulWidget {
  final String reasoning;
  final bool isDark;
  final Color textMuted;
  final Color textPrimary;

  const _ReasoningAccordion({
    required this.reasoning,
    required this.isDark,
    required this.textMuted,
    required this.textPrimary,
  });

  @override
  State<_ReasoningAccordion> createState() => _ReasoningAccordionState();
}

class _ReasoningAccordionState extends State<_ReasoningAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 14,
                    color: widget.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Thinking Process',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.reasoning,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: widget.textMuted,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomCodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final Color textMuted;

  CustomCodeElementBuilder({required this.isDark, required this.textMuted});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final text = element.textContent;
    final className = element.attributes['class'] ?? '';
    final isBlock = className.startsWith('language-') || text.contains('\n');

    if (isBlock) {
      final language = className.replaceFirst('language-', '');
      return CodeBlockWidget(
        code: text,
        language: language,
        isDark: isDark,
        textMuted: textMuted,
      );
    }

    // Inline code snippet
    final inlineColor = isDark ? VelocityColors.darkAccentBlue : VelocityColors.lightAccentBlue;
    final inlineBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: inlineBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: inlineColor,
        ),
      ),
    );
  }
}

class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String language;
  final bool isDark;
  final Color textMuted;

  const CodeBlockWidget({
    super.key,
    required this.code,
    required this.language,
    required this.isDark,
    required this.textMuted,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _copied = true);
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgCol = widget.isDark ? VelocityColors.darkBgCode : VelocityColors.lightBgCode;
    final copyBtnBg = widget.isDark ? const Color(0x4027272A) : const Color(0x66E4E4E7);

    String lang = widget.language.trim().toLowerCase();
    if (lang.isEmpty) lang = 'plaintext';
    if (lang == 'js') lang = 'javascript';
    if (lang == 'ts') lang = 'typescript';
    if (lang == 'py') lang = 'python';
    if (lang == 'sh' || lang == 'shell' || lang == 'zsh') lang = 'bash';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 40, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HighlightView(
                widget.code.trimRight(),
                language: lang,
                theme: widget.isDark ? _codeDarkTheme : _codeLightTheme,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: copyBtnBg,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: _copy,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    _copied ? LucideIcons.check : LucideIcons.copy,
                    size: 13,
                    color: widget.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _tightenMarkdownLists(String input) {
  if (!input.contains('- ') &&
      !input.contains('* ') &&
      !input.contains('+ ') &&
      !RegExp(r'\d+\.').hasMatch(input)) {
    return input;
  }
  final lines = input.split('\n');
  final result = <String>[];
  bool inList = false;
  bool inCodeBlock = false;
  final listPattern = RegExp(r'^(\s*)([-*+]|\d+\.)\s+');

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().startsWith('```')) {
      inCodeBlock = !inCodeBlock;
      inList = false;
      result.add(line);
      continue;
    }
    if (inCodeBlock) {
      result.add(line);
      continue;
    }
    final isListItem = listPattern.hasMatch(line);
    if (isListItem) {
      inList = true;
      result.add(line);
    } else if (line.trim().isEmpty) {
      if (inList) {
        int nextNonEmpty = -1;
        for (int j = i + 1; j < lines.length; j++) {
          if (lines[j].trim().isNotEmpty) {
            nextNonEmpty = j;
            break;
          }
        }
        if (nextNonEmpty != -1 && listPattern.hasMatch(lines[nextNonEmpty])) {
          continue;
        } else {
          inList = false;
          result.add(line);
        }
      } else {
        result.add(line);
      }
    } else {
      if (line.startsWith('  ') || line.startsWith('\t')) {
        result.add(line);
      } else {
        inList = false;
        result.add(line);
      }
    }
  }
  return result.join('\n');
}

const Map<String, TextStyle> _codeDarkTheme = {
  'root': TextStyle(color: Color(0xFFE6EDF3), backgroundColor: Colors.transparent),
  'keyword': TextStyle(color: Color(0xFFFF7B72), fontWeight: FontWeight.w600),
  'built_in': TextStyle(color: Color(0xFF79C0FF)),
  'type': TextStyle(color: Color(0xFFFFA657), fontWeight: FontWeight.w600),
  'literal': TextStyle(color: Color(0xFF79C0FF)),
  'number': TextStyle(color: Color(0xFF79C0FF)),
  'operator': TextStyle(color: Color(0xFFFF7B72)),
  'punctuation': TextStyle(color: Color(0xFF8B949E)),
  'string': TextStyle(color: Color(0xFFA5D6FF)),
  'regexp': TextStyle(color: Color(0xFF7EE787)),
  'subst': TextStyle(color: Color(0xFFC9D1D9)),
  'symbol': TextStyle(color: Color(0xFF79C0FF)),
  'class': TextStyle(color: Color(0xFFFFA657), fontWeight: FontWeight.w600),
  'function': TextStyle(color: Color(0xFFD2A8FF)),
  'title': TextStyle(color: Color(0xFFD2A8FF), fontWeight: FontWeight.w600),
  'comment': TextStyle(color: Color(0xFF6E7681), fontStyle: FontStyle.italic),
};

const Map<String, TextStyle> _codeLightTheme = {
  'root': TextStyle(color: Color(0xFF24292F), backgroundColor: Colors.transparent),
  'keyword': TextStyle(color: Color(0xFFCF222E), fontWeight: FontWeight.w600),
  'built_in': TextStyle(color: Color(0xFF0550AE)),
  'type': TextStyle(color: Color(0xFF953800), fontWeight: FontWeight.w600),
  'literal': TextStyle(color: Color(0xFF0550AE)),
  'number': TextStyle(color: Color(0xFF0550AE)),
  'operator': TextStyle(color: Color(0xFFCF222E)),
  'punctuation': TextStyle(color: Color(0xFF57606A)),
  'string': TextStyle(color: Color(0xFF0A3069)),
  'regexp': TextStyle(color: Color(0xFF116329)),
  'subst': TextStyle(color: Color(0xFF24292F)),
  'symbol': TextStyle(color: Color(0xFF0550AE)),
  'class': TextStyle(color: Color(0xFF953800), fontWeight: FontWeight.w600),
  'function': TextStyle(color: Color(0xFF8250DF)),
  'title': TextStyle(color: Color(0xFF8250DF), fontWeight: FontWeight.w600),
  'comment': TextStyle(color: Color(0xFF6E7781), fontStyle: FontStyle.italic),
};
