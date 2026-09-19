import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/velocity_colors.dart';
import '../widgets/shimmer_text.dart';

class MemoryInspectorSheet extends StatefulWidget {
  const MemoryInspectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MemoryInspectorSheet(),
    );
  }

  @override
  State<MemoryInspectorSheet> createState() => _MemoryInspectorSheetState();
}

class _MemoryInspectorSheetState extends State<MemoryInspectorSheet> {
  String _selectedCategory = 'current-context';

  final List<Map<String, String>> _categories = const [
    {'id': 'current-context', 'label': 'Current Context'},
    {'id': 'user-persona', 'label': 'User Persona'},
    {'id': 'projects-and-decisions', 'label': 'Projects & Decisions'},
    {'id': 'goals-and-interests', 'label': 'Goals & Interests'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      if (provider.mentalModels.isEmpty) {
        provider.loadMentalModels();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgModal = isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal;
    final bgInner = isDark ? VelocityColors.darkBgModalInner : VelocityColors.lightBgModalInner;
    final pillBg = isDark ? VelocityColors.darkBgPill : VelocityColors.lightBgPill;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;
    final textDim = isDark ? VelocityColors.darkTextDim : VelocityColors.lightTextDim;

    // Find current model content
    final currentModel = provider.mentalModels.where((m) => m.id == _selectedCategory).firstOrNull;
    final content = currentModel?.content ?? '# No data\nNo synthesized memory found for this category.';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgModal,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Status dot + "Hindsight Memory" + Refresh + Close
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: provider.isHindsightHealthy
                            ? VelocityColors.statusOnline
                            : VelocityColors.statusDegraded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hindsight Memory',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(LucideIcons.rotateCcw, size: 16, color: textMuted),
                      onPressed: () => provider.loadMentalModels(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(LucideIcons.x, size: 18, color: textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Horizontal Category Filter Pills
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSelected = cat['id'] == _selectedCategory;

                    return Material(
                      color: isSelected ? pillBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['id']!;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Center(
                            child: Text(
                              cat['label']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? textPrimary : textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Body: Markdown viewer inside bgModalInner container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgInner,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: provider.isLoadingMentalModels
                      ? Center(
                          child: ShimmerText(
                            text: 'Loading memory...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textDim,
                            ),
                            baseColor: textDim,
                            highlightColor: textPrimary,
                          ),
                        )
                      : Markdown(
                          controller: scrollController,
                          data: content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: 14, color: textPrimary, height: 1.5, fontWeight: FontWeight.w500),
                            h1: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
                            h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                            h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                            code: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              color: isDark ? VelocityColors.darkAccentBlue : VelocityColors.lightAccentBlue,
                            ),
                            listBullet: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500),
                            blockSpacing: 8,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
