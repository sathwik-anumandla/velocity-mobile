import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/auth_service.dart';
import '../theme/velocity_colors.dart';
import 'onboarding_screen.dart';

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
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: bgInner,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server Address',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.serverUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit Server Address',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.edit_outlined, size: 16, color: textMuted),
                    onPressed: () => _showEditServerDialog(context, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => _showEditServerDialog(context, provider),
                  child: const Text('Change IP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: VelocityColors.statusOffline,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => _confirmDisconnect(context, provider),
                  child: const Text('Disconnect', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: VelocityColors.statusOffline)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => provider.checkBackendHealth(),
                  child: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServerDialog(BuildContext context, ChatProvider provider) {
    final controller = TextEditingController(text: provider.serverUrl);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgModal = isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;
    final cardBg = isDark ? VelocityColors.darkBgCard : VelocityColors.lightBgCard;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgModal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Server Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the backend URL (e.g. http://192.168.0.140:8000):',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: TextStyle(fontSize: 14, fontFamily: 'JetBrains Mono', color: textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBg,
                hintText: 'http://192.168.0.140:8000',
                hintStyle: TextStyle(color: textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              Navigator.of(ctx).pop();
              if (newUrl.isNotEmpty) {
                await provider.updateServerUrl(newUrl);
              }
            },
            child: Text('Save & Connect', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
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
              Navigator.of(context).pop(); // Close health details sheet
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
