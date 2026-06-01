import 'package:flutter/material.dart';

/// TODO(domain): replace with entities from features/finance, ai, goals, family.
/// Kept inline + typed so the UI contract is stable when real data lands.

class TxItem {
  const TxItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });
  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isIncome;
}

class InsightItem {
  const InsightItem({
    required this.title,
    required this.body,
    required this.icon,
    required this.tint,
  });
  final String title;
  final String body;
  final IconData icon;
  final Color tint;
}

class GoalItem {
  const GoalItem({
    required this.title,
    required this.current,
    required this.target,
    required this.color,
  });
  final String title;
  final double current;
  final double target;
  final Color color;
  double get progress => (current / target).clamp(0, 1);
}

class FamilyMemberItem {
  const FamilyMemberItem({
    required this.name,
    required this.role,
    required this.color,
    required this.lastAction,
  });
  final String name;
  final String role;
  final Color color;
  final String lastAction;
}
