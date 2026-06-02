import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

/// Сгруппированная inset-секция в стиле iOS grouped list.
class InsetSection extends StatelessWidget {
  const InsetSection({required this.children, this.header, super.key});

  final String? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(height: 0.5, thickness: 0.5, indent: 16, color: hig.separator));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              header!.toUpperCase(),
              style: TextStyle(fontSize: 13, color: hig.secondaryLabel, letterSpacing: 0.2),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: hig.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

/// Строка для [InsetSection].
class InsetTile extends StatelessWidget {
  const InsetTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 17, color: hig.label)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(fontSize: 13, color: hig.secondaryLabel)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right, color: hig.secondaryLabel, size: 20),
          ],
        ),
      ),
    );
  }
}
