import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/auth_service.dart';
import '../theme/velocity_colors.dart';
import '../widgets/velocity_mark.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handlePayload(String raw) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final success = await AuthService.saveFromQrPayload(raw);
    if (success) {
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final provider = context.read<ChatProvider>();
      await provider.onCredentialsConfigured();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      HapticFeedback.lightImpact();
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: VelocityColors.darkBgCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'Invalid QR code. Please scan the QR code from chat.sathwik.work/mobile',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: VelocityColors.darkTextPrimary,
              ),
            ),
          ),
        );
      }
    }
  }

  void _showManualPayloadSheet() {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgModal = isDark ? VelocityColors.darkBgModal : VelocityColors.lightBgModal;
    final bgInner = isDark ? VelocityColors.darkBgModalInner : VelocityColors.lightBgModalInner;
    final textPrimary = isDark ? VelocityColors.darkTextPrimary : VelocityColors.lightTextPrimary;
    final textMuted = isDark ? VelocityColors.darkTextMuted : VelocityColors.lightTextMuted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgModal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paste Connection Payload',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
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
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Copy the JSON payload from chat.sathwik.work/mobile and paste it below:',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    color: textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.5,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: bgInner,
                    hintText: '{\n  "url": "https://chat.sathwik.work",\n  "client_id": "...",\n  "client_secret": "..."\n}',
                    hintStyle: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      color: textMuted.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final text = textController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.of(ctx).pop();
                        _handlePayload(text);
                      }
                    },
                    child: const Text(
                      'Connect',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scanSize = (constraints.maxWidth * 0.72).clamp(220.0, 290.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Brand Mark & Title
                  const VelocityMark(
                    size: 32,
                    strokeWidth: 3.6,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Link to Velocity',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Visit chat.sathwik.work/mobile on your computer to scan your connection QR code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: VelocityColors.darkTextMuted,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Camera Scanner with Cutout Frame
                  Center(
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            errorBuilder: (context, error, child) {
                              return Container(
                                color: VelocityColors.darkBgCard,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      LucideIcons.cameraOff,
                                      size: 36,
                                      color: VelocityColors.darkTextMuted,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Camera access needed to scan QR code',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: VelocityColors.darkTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextButton(
                                      onPressed: _showManualPayloadSheet,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: const Color(0xFF27272A),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      child: const Text(
                                        'Paste code instead',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDetect: (capture) {
                              for (final barcode in capture.barcodes) {
                                final raw = barcode.rawValue;
                                if (raw != null && raw.trim().isNotEmpty) {
                                  _handlePayload(raw.trim());
                                  break;
                                }
                              }
                            },
                          ),

                          // Subtle corner markers
                          CustomPaint(
                            painter: _ScannerCornersPainter(
                              color: Colors.white,
                              cornerLength: 22,
                              strokeWidth: 3.0,
                            ),
                          ),

                          // Processing indicator
                          if (_isProcessing)
                            Container(
                              color: Colors.black.withValues(alpha: 0.6),
                              child: const Center(
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Torch Toggle Button
                  IconButton(
                    tooltip: _isTorchOn ? 'Turn off flash' : 'Turn on flash',
                    icon: Icon(
                      _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                      size: 18,
                      color: _isTorchOn ? Colors.white : VelocityColors.darkTextMuted,
                    ),
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      await _scannerController.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                  ),

                  const Spacer(flex: 2),

                  // Fallback: Manual paste
                  TextButton(
                    onPressed: _showManualPayloadSheet,
                    style: TextButton.styleFrom(
                      foregroundColor: VelocityColors.darkTextMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text(
                      'Or paste connection payload',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: VelocityColors.darkTextMuted,
                        decoration: TextDecoration.underline,
                        decorationColor: VelocityColors.darkTextMuted,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Draws corner reticle accents around the scanner frame
class _ScannerCornersPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;

  _ScannerCornersPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    const r = 16.0;

    // Top-left
    canvas.drawLine(const Offset(r, 0), Offset(r + cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, r), Offset(0, r + cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(w - r, 0), Offset(w - r - cornerLength, 0), paint);
    canvas.drawLine(Offset(w, r), Offset(w, r + cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(r, h), Offset(r + cornerLength, h), paint);
    canvas.drawLine(Offset(0, h - r), Offset(0, h - r - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(w - r, h), Offset(w - r - cornerLength, h), paint);
    canvas.drawLine(Offset(w, h - r), Offset(w, h - r - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerCornersPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.cornerLength != cornerLength ||
      oldDelegate.strokeWidth != strokeWidth;
}
