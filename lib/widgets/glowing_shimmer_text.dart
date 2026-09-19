import 'package:flutter/material.dart';

class GlowingShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final bool isDarkMode;

  const GlowingShimmerText({
    super.key,
    required this.text,
    this.textStyle,
    this.isDarkMode = true,
  });

  @override
  State<GlowingShimmerText> createState() => _GlowingShimmerTextState();
}

class _GlowingShimmerTextState extends State<GlowingShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Exact 2.2-second ease-in-out loop matching web CSS
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exact Velocity Web color tokens
    final baseColor = widget.isDarkMode
        ? const Color(0xFF71717A) // --text-dim
        : const Color(0xFFA1A1AA);
    final glowColor = widget.isDarkMode
        ? const Color(0xFFFFFFFF) // --text-primary (radiant gleam)
        : const Color(0xFF09090B);

    final defaultStyle = TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 15.5,
      fontWeight: FontWeight.w500, // Medium weight carries the light on mobile
      letterSpacing: -0.3,
      color: glowColor,
    );

    final effectiveStyle = defaultStyle.merge(widget.textStyle);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            // Replicates CSS linear-gradient(90deg, dim 0%, dim 20%, primary 50%, dim 80%, dim 100%)
            // Sweeps smoothly across 200% width
            final progress = _animation.value;
            final double left = -bounds.width + (bounds.width * 2 * progress);
            final double right = left + bounds.width * 1.6;

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                baseColor,
                glowColor,
                baseColor,
                baseColor,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ).createShader(Rect.fromLTRB(left, 0, right, bounds.height));
          },
          child: Text(
            widget.text,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
