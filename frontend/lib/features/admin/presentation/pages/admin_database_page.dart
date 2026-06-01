import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../controllers/admin_db_controller.dart';

class AdminDatabasePage extends ConsumerStatefulWidget {
  const AdminDatabasePage({super.key});

  @override
  ConsumerState<AdminDatabasePage> createState() => _AdminDatabasePageState();
}

class _AdminDatabasePageState extends ConsumerState<AdminDatabasePage> {
  final _sqlController = TextEditingController();

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Database Admin Panel'),
          backgroundColor: AppColors.brand500,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.table_chart_rounded), text: 'Tables'),
              Tab(icon: Icon(Icons.code_rounded), text: 'SQL Console'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTablesTab(),
            _buildSqlTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesTab() {
    final state = ref.watch(adminDbControllerProvider);
    
    return Row(
      children: [
        // Sidebar with tables
        Container(
          width: 250,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.graphite300)),
          ),
          child: state.isLoadingTables
              ? const Center(child: CircularProgressIndicator())
              : state.tableError != null
                  ? Center(child: Text(state.tableError!, style: const TextStyle(color: AppColors.danger)))
                  : ListView.builder(
                      itemCount: state.tables.length,
                      itemBuilder: (ctx, i) {
                        final table = state.tables[i];
                        return ListTile(
                          title: Text(table),
                          leading: const Icon(Icons.table_rows_rounded),
                          onTap: () {
                            _sqlController.text = 'SELECT * FROM $table LIMIT 100';
                            ref.read(adminDbControllerProvider.notifier).executeQuery(_sqlController.text);
                            DefaultTabController.of(context).animateTo(1);
                          },
                        );
                      },
                    ),
        ),
        // Instructions
        const Expanded(
          child: Center(
            child: Text(
              'Select a table to view its contents',
              style: AppTypography.title,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSqlTab() {
    final state = ref.watch(adminDbControllerProvider);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.graphite300)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _sqlController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Enter SQL query (e.g., SELECT * FROM users)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: state.isExecutingQuery
                    ? null
                    : () {
                        ref.read(adminDbControllerProvider.notifier).executeQuery(_sqlController.text);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
                icon: state.isExecutingQuery ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
                label: const Text('Execute'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildQueryResult(state),
        ),
      ],
    );
  }

  Widget _buildQueryResult(state) {
    if (state.queryResult == null) {
      return const Center(child: Text('Run a query to see results'));
    }

    final result = state.queryResult!;

    if (result.error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        color: AppColors.danger.withOpacity(0.1),
        child: Text(
          result.error!,
          style: const TextStyle(color: AppColors.danger, fontFamily: 'monospace', fontSize: 14),
        ),
      );
    }

    final columns = result.columns ?? [];
    final rows = result.rows ?? [];

    if (columns.isEmpty || rows.isEmpty) {
      return const Center(child: Text('No data returned'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns.map((col) => DataColumn(label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          rows: rows.map((row) {
            return DataRow(
              cells: columns.map((col) {
                return DataCell(Text(row[col]?.toString() ?? 'null'));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
