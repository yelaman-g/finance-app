import 'package:aifb/app/router/routes.dart';
import 'package:aifb/app/theme/theme_mode_provider.dart';
import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:aifb/shared/widgets/large_title_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final isAdmin =
        auth is AuthAuthenticated && auth.user.roles.contains('ADMIN');
    final mode = ref.watch(themeModeProvider);
    return LargeTitleScaffold(
      title: 'Ещё',
      slivers: [
        InsetSection(
          header: 'Управление',
          children: [
            InsetTile(
              title: 'Семья',
              leading: const Icon(Icons.group_rounded),
              onTap: () => context.push(AppRoutes.family.path),
            ),
            InsetTile(
              title: 'Группы категорий',
              leading: const Icon(Icons.folder_rounded),
              onTap: () => context.push(AppRoutes.groups.path),
            ),
            InsetTile(
              title: 'Правила категоризации',
              leading: const Icon(Icons.auto_awesome_rounded),
              onTap: () => context.push(AppRoutes.rules.path),
            ),
            InsetTile(
              title: 'Категории',
              leading: const Icon(Icons.category_rounded),
              onTap: () => context.push(AppRoutes.categoriesManage.path),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InsetSection(
          header: 'Оформление',
          children: [
            InsetTile(
              title: 'Тема',
              leading: const Icon(Icons.brightness_6_rounded),
              trailing: DropdownButton<ThemeMode>(
                value: mode,
                underline: const SizedBox.shrink(),
                onChanged: (m) {
                  if (m != null) ref.read(themeModeProvider.notifier).set(m);
                },
                items: const [
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text('Система')),
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('Светлая')),
                  DropdownMenuItem(
                      value: ThemeMode.dark, child: Text('Тёмная')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InsetSection(
          children: [
            if (isAdmin)
              InsetTile(
                title: 'Админ-панель',
                leading: const Icon(Icons.admin_panel_settings_rounded),
                onTap: () => context.push(AppRoutes.admin.path),
              ),
            InsetTile(
              title: 'Выйти',
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ],
    );
  }
}
