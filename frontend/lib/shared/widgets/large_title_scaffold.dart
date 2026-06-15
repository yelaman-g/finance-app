import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

/// Scaffold с крупным сворачивающимся заголовком (HIG large title).
class LargeTitleScaffold extends StatelessWidget {
  const LargeTitleScaffold({
    required this.title,
    required this.slivers,
    this.actions,
    this.floatingActionButton,
    this.onRefresh,
    super.key,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  /// Если задан — включает pull-to-refresh поверх контента.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    final scrollView = CustomScrollView(
      physics: onRefresh != null ? const AlwaysScrollableScrollPhysics() : null,
      slivers: [
        SliverAppBar.large(
          title: Text(title),
          actions: actions,
          backgroundColor: hig.pageBackground,
          surfaceTintColor: Colors.transparent,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(delegate: SliverChildListDelegate(slivers)),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: hig.pageBackground,
      floatingActionButton: floatingActionButton,
      body: onRefresh != null
          ? RefreshIndicator(onRefresh: onRefresh!, child: scrollView)
          : scrollView,
    );
  }
}
