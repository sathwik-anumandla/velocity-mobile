import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/chat_provider.dart';
import '../theme/velocity_colors.dart';
import 'health_details_sheet.dart';
import 'memory_inspector_sheet.dart';
import 'search_dialog.dart';
import 'onboarding_screen.dart';
import '../services/auth_service.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  void _showRenameDialog(BuildContext context, ChatProvider provider, Session session) {
    final controller = TextEditingController(text: session.name);
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Conversation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter conversation title...',
            filled: true,
            fillColor: isDark ? VelocityColors.darkBgInput : VelocityColors.lightBgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) {
            final text = val.trim();
            if (text.isNotEmpty) {
              provider.renameSession(session.id, text);
              HapticFeedback.mediumImpact();
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                provider.renameSession(session.id, text);
                HapticFeedback.mediumImpact();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSession(BuildContext context, ChatProvider provider, Session session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgModal = isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Conversation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${session.name}"? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13.5,
            color: textMuted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              HapticFeedback.mediumImpact();
              provider.deleteSession(session.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: VelocityColors.statusOffline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionContextMenu(
    BuildContext context,
    ChatProvider provider,
    Session session,
    Offset tapPosition,
  ) async {
    HapticFeedback.mediumImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy - 10,
        MediaQuery.of(context).size.width - tapPosition.dx,
        MediaQuery.of(context).size.height - tapPosition.dy,
      ),
      color: cardBg,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          height: 38,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.pencil, size: 14, color: textPrimary),
              const SizedBox(width: 10),
              Text(
                'Rename',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          height: 38,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (selected == 'rename') {
      HapticFeedback.selectionClick();
      if (context.mounted) {
        _showRenameDialog(context, provider, session);
      }
    } else if (selected == 'delete') {
      HapticFeedback.mediumImpact();
      if (context.mounted) {
        _confirmDeleteSession(context, provider, session);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgDrawer = isDark ? VelocityColors.darkBgSidebar : VelocityColors.lightBgSidebar;
    final cardBg = isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard;
    final activeBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE4E4E7);
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;
    final textSecondary = isDark ? VelocityColors.darkTextSecondary : VelocityColors.lightTextSecondary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;

    Color statusColor;
    if (provider.isBackendOnline && provider.isHindsightHealthy) {
      statusColor = VelocityColors.statusOnline;
    } else if (provider.isBackendOnline) {
      statusColor = VelocityColors.statusDegraded;
    } else {
      statusColor = VelocityColors.statusOffline;
    }

    return Drawer(
      backgroundColor: bgDrawer,
      child: SafeArea(
        child: Column(
          children: [
            // Top Section: Brand + Search + New Chat (No temporary chat in drawer)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Velocity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Search (⌘K)',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(LucideIcons.search, size: 18, color: textMuted),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (_) => const SearchDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // New Chat Action
                  Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        provider.startNewChat(isTemporary: false);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(LucideIcons.plus, size: 16, color: textMuted),
                            const SizedBox(width: 10),
                            Text(
                              'New Chat',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle Section: Flat, Simple Conversations List (No time categorization)
            Expanded(
              child: provider.isLoadingSessions
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : RefreshIndicator(
                      color: textPrimary,
                      backgroundColor: cardBg,
                      strokeWidth: 2.0,
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        await provider.refreshSessions();
                      },
                      child: provider.sessions.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) => SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: Center(
                                    child: Text(
                                      'No previous conversations',
                                      style: TextStyle(fontSize: 13, color: textMuted),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              itemCount: provider.sessions.length,
                              itemBuilder: (context, index) {
                                final session = provider.sessions[index];
                                final isSelected = provider.currentSession?.id == session.id;
                                Offset tapPosition = Offset.zero;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Material(
                                    color: isSelected ? activeBg : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTapDown: (details) => tapPosition = details.globalPosition,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        provider.selectSession(session);
                                        Navigator.of(context).pop();
                                      },
                                      onLongPress: () => _showSessionContextMenu(context, provider, session, tapPosition),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                session.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                  color: isSelected ? textPrimary : textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),

            // Split Footer: Left Minimal Status Dot -> Right Brain & Theme Icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Left: Status Dot (Tapping opens Health Details)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      HealthDetailsSheet.show(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.isBackendOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Right: Brain Icon (Memory Inspector)
                  IconButton(
                    tooltip: 'Memory Inspector',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    icon: Icon(LucideIcons.brain, size: 18, color: textMuted),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      MemoryInspectorSheet.show(context);
                    },
                  ),
                  const SizedBox(width: 4),
                  // Right: Sun/Moon Theme Toggle
                  IconButton(
                    tooltip: isDark ? 'Light theme' : 'Dark theme',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    icon: Icon(
                      isDark ? LucideIcons.sun : LucideIcons.moon,
                      size: 18,
                      color: textMuted,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      provider.toggleTheme();
                    },
                  ),
                  const SizedBox(width: 4),
                  // Right: Disconnect / Logout Server
                  IconButton(
                    tooltip: 'Disconnect Server',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    icon: Icon(
                      LucideIcons.logOut,
                      size: 17,
                      color: textMuted,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _confirmDisconnect(context, provider);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, ChatProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgModal = isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Disconnect Server',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        content: Text(
          'This will remove stored Cloudflare Zero Trust credentials. You will need to scan the pairing QR code again to reconnect.',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13.5,
            color: textMuted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Satoshi', color: textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.logout();
              provider.resetState();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Disconnect',
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: VelocityColors.statusOffline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
