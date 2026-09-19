import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/velocity_colors.dart';

class HealthDetailsSheet extends StatelessWidget {
  const HealthDetailsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const HealthDetailsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgModal = isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal;
    final bgInner = isDark ? VelocityColors.darkBgModalInner : VelocityColors.lightBgModalInner;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;

    final details = provider.healthDetails;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgModal,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Health',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(Icons.close, size: 18, color: textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: bgInner,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHealthRow(
                    label: 'Backend Server',
                    status: details?.backend ?? (provider.isBackendOnline ? 'healthy' : 'unreachable'),
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 12),
                  _buildHealthRow(
                    label: 'Database (SQLite FTS5)',
                    status: details?.database ?? (provider.isBackendOnline ? 'healthy' : 'unreachable'),
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 12),
                  _buildHealthRow(
                    label: 'Memory (Hindsight)',
                    status: details?.hindsight ?? (provider.isHindsightHealthy ? 'healthy' : 'degraded'),
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => provider.checkBackendHealth(),
                  child: const Text('Refresh Status', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRow({
    required String label,
    required String status,
    required Color textPrimary,
    required Color textMuted,
  }) {
    Color statusColor;
    if (status == 'healthy' || status == 'ok') {
      statusColor = VelocityColors.statusOnline;
    } else if (status == 'degraded') {
      statusColor = VelocityColors.statusDegraded;
    } else {
      statusColor = VelocityColors.statusOffline;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          status.toUpperCase(),
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}
