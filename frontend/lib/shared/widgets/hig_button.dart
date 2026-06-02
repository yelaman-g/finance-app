import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

enum HigButtonStyle { filled, tinted, plain }

class HigButton extends StatelessWidget {
  const HigButton({
    required this.label,
    required this.onPressed,
    this.style = HigButtonStyle.filled,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final HigButtonStyle style;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    final bg = switch (style) {
      HigButtonStyle.filled => hig.accent,
      HigButtonStyle.tinted => hig.accent.withValues(alpha: 0.15),
      HigButtonStyle.plain => Colors.transparent,
    };
    final fg = style == HigButtonStyle.filled ? Colors.white : hig.accent;
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Text(
                    label,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg),
                  ),
          ),
        ),
      ),
    );
  }
}
