import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/chat_provider.dart';
import '../theme/velocity_colors.dart';
import '../widgets/velocity_mark.dart';
import 'health_details_sheet.dart';
import 'memory_inspector_sheet.dart';
import 'search_dialog.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  void _showRenameDialog(BuildContext context, ChatProvider provider, Session session) {
    final controller = TextEditingController(text: session.name);
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
            if (val.trim().isNotEmpty) {
              provider.renameSession(session.id, val.trim());
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
              if (controller.text.trim().isNotEmpty) {
                provider.renameSession(session.id, controller.text.trim());
                HapticFeedback.mediumImpact();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
                      VelocityBrandLogo(
                        markSize: 18,
                        fontSize: 20,
                        color: textPrimary,
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
                  : provider.sessions.isEmpty
                      ? Center(
                          child: Text(
                            'No previous conversations',
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          itemCount: provider.sessions.length,
                          itemBuilder: (context, index) {
                            final session = provider.sessions[index];
                            final isSelected = provider.currentSession?.id == session.id;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Material(
                                color: isSelected ? activeBg : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    provider.selectSession(session);
                                    Navigator.of(context).pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12, right: 4, top: 9, bottom: 9),
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
                                        PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          color: cardBg,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          onSelected: (val) {
                                            if (val == 'rename') {
                                              HapticFeedback.selectionClick();
                                              _showRenameDialog(context, provider, session);
                                            } else if (val == 'delete') {
                                              HapticFeedback.mediumImpact();
                                              provider.deleteSession(session.id);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem(
                                              value: 'rename',
                                              height: 36,
                                              child: Row(
                                                children: [
                                                  Icon(LucideIcons.pencil, size: 14, color: textPrimary),
                                                  const SizedBox(width: 8),
                                                  Text('Rename', style: TextStyle(fontSize: 13, color: textPrimary)),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              height: 36,
                                              child: Row(
                                                children: [
                                                  Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                                                ],
                                              ),
                                            ),
                                          ],
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(
                                              LucideIcons.moreVertical,
                                              size: 15,
                                              color: textMuted,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
