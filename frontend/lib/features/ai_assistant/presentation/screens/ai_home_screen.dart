import 'package:flutter/material.dart';

import 'ai_assistant_screen.dart';
import 'budget_analysis_tab.dart';
import 'reminders_tab.dart';

class AiHomeScreen extends StatelessWidget {
  const AiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ИИ-помощник'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Чат'),
            Tab(text: 'Анализ'),
            Tab(text: 'Напоминания'),
          ]),
        ),
        body: const TabBarView(children: [
          AiAssistantScreen(),
          BudgetAnalysisTab(),
          RemindersTab(),
        ]),
      ),
    );
  }
}
