import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

class HigTextField extends StatelessWidget {
  const HigTextField({
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.textCapitalization = TextCapitalization.sentences,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: TextStyle(fontSize: 17, color: hig.label),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: hig.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hig.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hig.accent, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
