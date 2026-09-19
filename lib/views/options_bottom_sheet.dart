import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/velocity_colors.dart';

class OptionsBottomSheet extends StatefulWidget {
  const OptionsBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OptionsBottomSheet(),
    );
  }

  @override
  State<OptionsBottomSheet> createState() => _OptionsBottomSheetState();
}

class _OptionsBottomSheetState extends State<OptionsBottomSheet> {
  String? _activeSubMenu; // null, 'effort', 'recall', 'verbosity'

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgModal = isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal;
    final bgInner = isDark ? VelocityColors.darkBgModalInner : VelocityColors.lightBgModalInner;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;
    final activePillBg = isDark ? VelocityColors.darkBgPill : VelocityColors.lightBgPill;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgModal,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _activeSubMenu == null
              ? _buildMainMenu(context, provider, textPrimary, textMuted, bgInner)
              : _buildSubMenu(context, provider, textPrimary, textMuted, bgInner, activePillBg),
        ),
      ),
    );
  }

  Widget _buildMainMenu(
    BuildContext context,
    ChatProvider provider,
    Color textPrimary,
    Color textMuted,
    Color bgInner,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Text(
            'Generation Parameters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: bgInner,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _buildRow(
                title: 'effort',
                value: provider.thinkingEffort,
                onTap: () {
                  setState(() => _activeSubMenu = 'effort');
                  HapticFeedback.selectionClick();
                },
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildRow(
                title: 'recall',
                value: provider.recallBudget,
                onTap: () {
                  setState(() => _activeSubMenu = 'recall');
                  HapticFeedback.selectionClick();
                },
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _buildRow(
                title: 'verbosity',
                value: provider.verbosity,
                onTap: () {
                  setState(() => _activeSubMenu = 'verbosity');
                  HapticFeedback.selectionClick();
                },
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required String title,
    required String value,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                value.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenu(
    BuildContext context,
    ChatProvider provider,
    Color textPrimary,
    Color textMuted,
    Color bgInner,
    Color activePillBg,
  ) {
    String title;
    String currentValue;
    ValueChanged<String> onChanged;
    String description;
    List<String> options;

    if (_activeSubMenu == 'effort') {
      title = 'effort';
      currentValue = provider.thinkingEffort;
      onChanged = (lvl) => provider.setThinkingEffort(lvl);
      options = ['none', 'low', 'medium', 'high', 'xhigh', 'max'];
      if (currentValue == 'none') {
        description = 'No reasoning effort. Fastest, lowest latency responses.';
      } else if (currentValue == 'low') {
        description = 'Minimal reasoning for faster, direct responses.';
      } else if (currentValue == 'high') {
        description = 'Deep reasoning effort for complex logic and coding.';
      } else if (currentValue == 'xhigh') {
        description = 'Extra high reasoning for complex architecture and analysis.';
      } else if (currentValue == 'max') {
        description = 'Maximum reasoning depth for the hardest reasoning problems.';
      } else {
        description = 'Balanced reasoning for general tasks (default).';
      }
    } else if (_activeSubMenu == 'recall') {
      title = 'recall';
      currentValue = provider.recallBudget;
      onChanged = (lvl) => provider.setRecallBudget(lvl);
      options = ['low', 'medium', 'high'];
      description = currentValue == 'low'
          ? 'Focuses on immediate context with fast recall.'
          : currentValue == 'high'
              ? 'Deep memory recall across all past conversations.'
              : 'Standard memory recall from Hindsight (default).';
    } else {
      title = 'verbosity';
      currentValue = provider.verbosity;
      onChanged = (lvl) => provider.setVerbosity(lvl);
      options = ['low', 'medium', 'high'];
      description = currentValue == 'high'
          ? 'Thorough, exhaustive explanations and complete code.'
          : currentValue == 'medium'
              ? 'Balanced detail and standard explanations.'
              : 'Concise, direct, and punchy responses (default).';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: textMuted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 30),
              ),
              onPressed: () {
                setState(() => _activeSubMenu = null);
                HapticFeedback.selectionClick();
              },
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Text(
              currentValue.toUpperCase(),
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgInner,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: options.map((opt) {
              final isSelected = opt == currentValue;
              return Material(
                color: isSelected ? activePillBg : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    onChanged(opt);
                    HapticFeedback.selectionClick();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(
                      opt.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? textPrimary : textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
