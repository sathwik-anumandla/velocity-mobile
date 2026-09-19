import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/search_result.dart';
import '../theme/velocity_colors.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg = isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal;
    final inputBg = isDark ? VelocityColors.darkBgInput : VelocityColors.lightBgInput;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
      },
      child: Dialog(
        backgroundColor: dialogBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.search, size: 18, color: textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Search Messages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(LucideIcons.x, size: 18, color: textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(LucideIcons.search, size: 16, color: textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    provider.search(val);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.isSearching
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : provider.searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _controller.text.isEmpty
                                  ? 'Type a query to search across all sessions'
                                  : 'No matching messages found',
                              style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          )
                        : ListView.separated(
                            itemCount: provider.searchResults.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (ctx, idx) {
                              final item = provider.searchResults[idx];
                              return _buildResultTile(context, provider, item, isDark, textPrimary, textMuted);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultTile(
    BuildContext context,
    ChatProvider provider,
    SearchResult result,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final cleanSnippet = result.snippet.replaceAll('<mark>', '**').replaceAll('</mark>', '**');
    final tileBg = isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final session = provider.sessions.firstWhere(
          (s) => s.id == result.sessionId,
          orElse: () => provider.currentSession!,
        );
        await provider.selectSession(session);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.role == 'user' ? LucideIcons.pencil : LucideIcons.sparkles,
                  size: 14,
                  color: textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  result.role == 'user' ? 'You' : 'Velocity',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  result.sessionName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              cleanSnippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
