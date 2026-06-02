import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../controllers/admin_db_controller.dart';
import '../state/admin_db_state.dart';

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
    final hig = HigColors.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: hig.pageBackground,
        appBar: AppBar(
          title: const Text('Database Admin Panel'),
          backgroundColor: hig.accent,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(icon: Icon(Icons.table_chart_rounded), text: 'Tables'),
              Tab(icon: Icon(Icons.code_rounded), text: 'SQL Console'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTablesTab(hig),
            _buildSqlTab(hig),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesTab(HigColors hig) {
    final state = ref.watch(adminDbControllerProvider);

    return Row(
      children: [
        // Sidebar with tables
        Container(
          width: 250,
          color: hig.card,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: hig.pageBackground,
                  border: Border(
                    bottom: BorderSide(color: hig.separator),
                  ),
                ),
                child: Text(
                  'Tables',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hig.secondaryLabel,
                  ),
                ),
              ),
              Expanded(
                child: state.isLoadingTables
                    ? const Center(child: CircularProgressIndicator())
                    : state.tableError != null
                        ? Center(
                            child: Text(
                              state.tableError!,
                              style: TextStyle(color: hig.danger),
                            ),
                          )
                        : ListView.separated(
                            itemCount: state.tables.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: hig.separator,
                              indent: AppSpacing.md,
                            ),
                            itemBuilder: (ctx, i) {
                              final table = state.tables[i];
                              return ListTile(
                                title: Text(
                                  table,
                                  style: TextStyle(color: hig.label),
                                ),
                                leading: Icon(
                                  Icons.table_rows_rounded,
                                  color: hig.accent,
                                  size: 18,
                                ),
                                onTap: () {
                                  _sqlController.text =
                                      'SELECT * FROM $table LIMIT 100';
                                  ref
                                      .read(adminDbControllerProvider.notifier)
                                      .executeQuery(_sqlController.text);
                                  DefaultTabController.of(context).animateTo(1);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        // Right pane placeholder
        Expanded(
          child: Center(
            child: Text(
              'Select a table to view its contents',
              style: TextStyle(color: hig.secondaryLabel, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSqlTab(HigColors hig) {
    final state = ref.watch(adminDbControllerProvider);

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: hig.card,
            border: Border(bottom: BorderSide(color: hig.separator)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _sqlController,
                    maxLines: 5,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: hig.label,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Enter SQL query (e.g., SELECT * FROM users)',
                      hintStyle: TextStyle(color: hig.secondaryLabel),
                      fillColor: hig.pageBackground,
                      filled: true,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: hig.separator),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: hig.separator),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: hig.accent, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton.icon(
                  onPressed: state.isExecutingQuery
                      ? null
                      : () {
                          ref
                              .read(adminDbControllerProvider.notifier)
                              .executeQuery(_sqlController.text);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: hig.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: state.isExecutingQuery
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('Execute'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildQueryResult(state, hig),
        ),
      ],
    );
  }

  Widget _buildQueryResult(AdminDbState state, HigColors hig) {
    if (state.queryResult == null) {
      return Center(
        child: Text(
          'Run a query to see results',
          style: TextStyle(color: hig.secondaryLabel, fontSize: 15),
        ),
      );
    }

    final result = state.queryResult!;

    if (result.error != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: hig.danger.withValues(alpha: 0.1),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              result.error!,
              style: TextStyle(
                color: hig.danger,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final columns = result.columns ?? [];
    final rows = result.rows ?? [];

    if (columns.isEmpty || rows.isEmpty) {
      return Center(
        child: Text(
          'No data returned',
          style: TextStyle(color: hig.secondaryLabel, fontSize: 15),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: hig.pageBackground),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(hig.card),
            dataRowColor: WidgetStateProperty.all(hig.card),
            dividerThickness: 1,
            border: TableBorder(
              horizontalInside: BorderSide(color: hig.separator),
              bottom: BorderSide(color: hig.separator),
            ),
            columns: columns
                .map(
                  (col) => DataColumn(
                    label: Text(
                      col,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hig.label,
                      ),
                    ),
                  ),
                )
                .toList(),
            rows: rows.map((row) {
              return DataRow(
                cells: columns.map((col) {
                  return DataCell(
                    Text(
                      row[col]?.toString() ?? 'null',
                      style: TextStyle(color: hig.label),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
