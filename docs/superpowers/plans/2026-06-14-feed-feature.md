# Family Feed Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `lib/features/feed/` Flutter feature (text moments + family likes) with routing from the "Ещё" screen.

**Architecture:** Mirror the existing `shopping`/`polls`/`wishlist` pattern: plain DTOs, abstract repository, `FutureProvider.autoDispose`, `ConsumerStatefulWidget` page. No code generation (no freezed/riverpod_annotation) — plain Dart classes like shopping. Route `/feed` added to `app_router.dart` and `routes.dart`; entry tile in `more_page.dart`.

**Tech Stack:** Flutter 3.22, flutter_riverpod ^2.5.1, go_router ^14.2.7, dio ^5.7.0, intl ^0.19.0, mocktail ^1.0.4 (tests)

---

## File Map

**Create:**
- `frontend/lib/features/feed/data/dto/moment.dart` — plain DTO with fromJson
- `frontend/lib/features/feed/data/data_sources/feed_remote_data_source.dart` — Dio datasource
- `frontend/lib/features/feed/data/repositories/feed_repository_impl.dart` — impl
- `frontend/lib/features/feed/domain/repositories/feed_repository.dart` — abstract interface
- `frontend/lib/features/feed/presentation/providers/feed_providers.dart` — repo + FutureProvider
- `frontend/lib/features/feed/presentation/pages/feed_page.dart` — ConsumerStatefulWidget UI
- `frontend/test/features/feed/feed_repository_test.dart` — mocktail repo tests
- `frontend/test/features/feed/feed_page_test.dart` — widget tests

**Modify:**
- `frontend/lib/core/network/api_endpoints.dart` — add `static const String feed = '/feed';`
- `frontend/lib/app/router/routes.dart` — add `static const feed = _Route('feed', '/feed');`
- `frontend/lib/app/router/app_router.dart` — add GoRoute for /feed
- `frontend/lib/features/more/presentation/pages/more_page.dart` — add «Семейная лента» InsetTile

**Moments stub:** Only `routes.dart` references `AppRoutes.moments` (the path string), but nothing imports from `lib/features/moments/`. The stub is dead code — safe to delete. However, `routes.dart` still has `static const moments = _Route('moments', '/moments')` — leave that entry since removing it could break if something else references the name. The stub files themselves will be deleted.

---

### Task 1: DTO — `moment.dart`

**Files:**
- Create: `frontend/lib/features/feed/data/dto/moment.dart`

- [ ] **Step 1: Create the DTO file**

```dart
// frontend/lib/features/feed/data/dto/moment.dart
class Moment {
  const Moment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    required this.likes,
    required this.likedByMe,
  });

  factory Moment.fromJson(Map<String, dynamic> j) => Moment(
        id: j['id'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        authorName: j['authorName'] as String? ?? '',
        text: j['text'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        likes: j['likes'] as int? ?? 0,
        likedByMe: j['likedByMe'] as bool? ?? false,
      );

  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final int likes;
  final bool likedByMe;
}
```

---

### Task 2: API endpoint constant

**Files:**
- Modify: `frontend/lib/core/network/api_endpoints.dart`

- [ ] **Step 1: Add feed endpoint after `capsules`**

In `api_endpoints.dart`, after `static const String capsules = '/capsules';`, add:

```dart
  // Feed
  static const String feed = '/feed';
```

---

### Task 3: Remote data source

**Files:**
- Create: `frontend/lib/features/feed/data/data_sources/feed_remote_data_source.dart`

- [ ] **Step 1: Create datasource**

```dart
// frontend/lib/features/feed/data/data_sources/feed_remote_data_source.dart
import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/moment.dart';

abstract class FeedRemoteDataSource {
  Future<List<Moment>> list();
  Future<Moment> post(String text);
  Future<void> delete(String id);
  Future<void> like(String id);
  Future<void> unlike(String id);
}

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  FeedRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<Moment>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.feed);
    final data = res.data?['data'];
    if (data is! List) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return data
        .map((e) => Moment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Moment> post(String text) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.feed,
      data: {'text': text},
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return Moment.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.feed}/$id');
  }

  @override
  Future<void> like(String id) async {
    await _dio.post<void>('${ApiEndpoints.feed}/$id/like');
  }

  @override
  Future<void> unlike(String id) async {
    await _dio.delete<void>('${ApiEndpoints.feed}/$id/like');
  }
}
```

---

### Task 4: Domain repository interface

**Files:**
- Create: `frontend/lib/features/feed/domain/repositories/feed_repository.dart`

- [ ] **Step 1: Create interface**

```dart
// frontend/lib/features/feed/domain/repositories/feed_repository.dart
import '../../data/dto/moment.dart';

abstract class FeedRepository {
  Future<List<Moment>> list();
  Future<Moment> post(String text);
  Future<void> delete(String id);
  Future<void> like(String id);
  Future<void> unlike(String id);
}
```

---

### Task 5: Repository impl

**Files:**
- Create: `frontend/lib/features/feed/data/repositories/feed_repository_impl.dart`

- [ ] **Step 1: Create impl**

```dart
// frontend/lib/features/feed/data/repositories/feed_repository_impl.dart
import '../../domain/repositories/feed_repository.dart';
import '../data_sources/feed_remote_data_source.dart';
import '../dto/moment.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._remote);
  final FeedRemoteDataSource _remote;

  @override
  Future<List<Moment>> list() => _remote.list();

  @override
  Future<Moment> post(String text) => _remote.post(text);

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<void> like(String id) => _remote.like(id);

  @override
  Future<void> unlike(String id) => _remote.unlike(id);
}
```

---

### Task 6: Providers

**Files:**
- Create: `frontend/lib/features/feed/presentation/providers/feed_providers.dart`

- [ ] **Step 1: Create providers**

```dart
// frontend/lib/features/feed/presentation/providers/feed_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/feed_remote_data_source.dart';
import '../../data/dto/moment.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/repositories/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(
    FeedRemoteDataSourceImpl(ref.watch(dioProvider)),
  );
});

final feedProvider = FutureProvider.autoDispose<List<Moment>>((ref) {
  return ref.watch(feedRepositoryProvider).list();
});
```

---

### Task 7: Feed page UI

**Files:**
- Create: `frontend/lib/features/feed/presentation/pages/feed_page.dart`

- [ ] **Step 1: Create the page**

```dart
// frontend/lib/features/feed/presentation/pages/feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../../../features/auth/presentation/state/auth_state.dart';
import '../../data/dto/moment.dart';
import '../providers/feed_providers.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  late final TextEditingController _composeController;

  @override
  void initState() {
    super.initState();
    _composeController = TextEditingController();
  }

  @override
  void dispose() {
    _composeController.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} д назад';
    return DateFormat('d MMM', 'ru').format(dt);
  }

  Future<void> _publish() async {
    final text = _composeController.text.trim();
    if (text.isEmpty) return;
    await ref.read(feedRepositoryProvider).post(text);
    if (!mounted) return;
    _composeController.clear();
    ref.invalidate(feedProvider);
  }

  Future<void> _toggleLike(Moment moment) async {
    final repo = ref.read(feedRepositoryProvider);
    if (moment.likedByMe) {
      await repo.unlike(moment.id);
    } else {
      await repo.like(moment.id);
    }
    if (!mounted) return;
    ref.invalidate(feedProvider);
  }

  Future<void> _confirmDelete(Moment moment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить момент?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(feedRepositoryProvider).delete(moment.id);
    if (!mounted) return;
    ref.invalidate(feedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final currentUserId = auth is AuthAuthenticated ? auth.user.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Семейная лента')),
      body: Column(
        children: [
          // ── Compose area ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _composeController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Поделитесь моментом с семьёй…',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _publish,
                  child: const Text('Опубликовать'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Feed list ───────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(feedProvider.future),
              child: ref.watch(feedProvider).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'Ошибка загрузки. Потяните для повтора.',
                          ),
                        ),
                      ],
                    ),
                    data: (moments) {
                      if (moments.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Лента пуста. Поделитесь первым моментом!',
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: moments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _MomentCard(
                          moment: moments[i],
                          currentUserId: currentUserId,
                          relativeTime: _relativeTime(moments[i].createdAt),
                          onLike: () => _toggleLike(moments[i]),
                          onDelete: () => _confirmDelete(moments[i]),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Moment card ──────────────────────────────────────────────────────────────

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    required this.currentUserId,
    required this.relativeTime,
    required this.onLike,
    required this.onDelete,
  });

  final Moment moment;
  final String? currentUserId;
  final String relativeTime;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isOwn = currentUserId != null && moment.authorId == currentUserId;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: author + time + delete ──────────────────────────────
            Row(
              children: [
                Text(
                  moment.authorName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  relativeTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                if (isOwn)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Удалить',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Text ────────────────────────────────────────────────────────
            Text(moment.text),
            const SizedBox(height: 10),

            // ── Like button ─────────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    moment.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: moment.likedByMe
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  tooltip: moment.likedByMe ? 'Убрать лайк' : 'Лайк',
                  onPressed: onLike,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text(
                  '${moment.likes}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 8: Route and navigation wiring

**Files:**
- Modify: `frontend/lib/app/router/routes.dart`
- Modify: `frontend/lib/app/router/app_router.dart`
- Modify: `frontend/lib/features/more/presentation/pages/more_page.dart`

- [ ] **Step 1: Add route constant in routes.dart**

After `static const capsules = _Route('capsules', '/capsules');`, add:
```dart
  static const feed = _Route('feed', '/feed');
```

- [ ] **Step 2: Add GoRoute in app_router.dart**

Add import at top (after the capsules import):
```dart
import '../../features/feed/presentation/pages/feed_page.dart';
```

Add route after the capsules GoRoute block:
```dart
      GoRoute(
        path: AppRoutes.feed.path,
        name: AppRoutes.feed.name,
        pageBuilder: (ctx, state) =>
            fadeThroughPage(key: state.pageKey, child: const FeedPage()),
      ),
```

- [ ] **Step 3: Add InsetTile in more_page.dart**

After the «Капсула времени» tile, add:
```dart
            InsetTile(
              title: 'Семейная лента',
              leading: const Icon(Icons.dynamic_feed_rounded),
              onTap: () => context.push(AppRoutes.feed.path),
            ),
```

---

### Task 9: Repository test

**Files:**
- Create: `frontend/test/features/feed/feed_repository_test.dart`

- [ ] **Step 1: Write and run the test**

```dart
// frontend/test/features/feed/feed_repository_test.dart
import 'package:aifb/features/feed/data/data_sources/feed_remote_data_source.dart';
import 'package:aifb/features/feed/data/dto/moment.dart';
import 'package:aifb/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements FeedRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late FeedRepositoryImpl repo;

  final tMoment = Moment(
    id: 'm1',
    authorId: 'u1',
    authorName: 'Алия',
    text: 'Привет, семья!',
    createdAt: DateTime.parse('2026-06-14T10:00:00Z'),
    likes: 3,
    likedByMe: false,
  );

  setUp(() {
    remote = _MockRemote();
    repo = FeedRepositoryImpl(remote);
  });

  test('list returns moments from datasource', () async {
    when(() => remote.list()).thenAnswer((_) async => [tMoment]);
    final res = await repo.list();
    expect(res, hasLength(1));
    expect(res.first.authorName, 'Алия');
    expect(res.first.likes, 3);
    expect(res.first.likedByMe, isFalse);
    expect(res.first.createdAt, DateTime.parse('2026-06-14T10:00:00Z'));
    verify(() => remote.list()).called(1);
  });

  test('post forwards text and returns moment', () async {
    when(() => remote.post(any())).thenAnswer((_) async => tMoment);
    final res = await repo.post('Привет, семья!');
    expect(res.id, 'm1');
    verify(() => remote.post('Привет, семья!')).called(1);
  });

  test('delete forwards id', () async {
    when(() => remote.delete(any())).thenAnswer((_) async {});
    await repo.delete('m1');
    verify(() => remote.delete('m1')).called(1);
  });

  test('like forwards id', () async {
    when(() => remote.like(any())).thenAnswer((_) async {});
    await repo.like('m1');
    verify(() => remote.like('m1')).called(1);
  });

  test('unlike forwards id', () async {
    when(() => remote.unlike(any())).thenAnswer((_) async {});
    await repo.unlike('m1');
    verify(() => remote.unlike('m1')).called(1);
  });
}
```

Run: `cd frontend && flutter test test/features/feed/feed_repository_test.dart`
Expected: All 5 tests PASS

---

### Task 10: Widget test

**Files:**
- Create: `frontend/test/features/feed/feed_page_test.dart`

- [ ] **Step 1: Write and run the widget test**

```dart
// frontend/test/features/feed/feed_page_test.dart
import 'package:aifb/features/feed/data/dto/moment.dart';
import 'package:aifb/features/feed/domain/repositories/feed_repository.dart';
import 'package:aifb/features/feed/presentation/pages/feed_page.dart';
import 'package:aifb/features/feed/presentation/providers/feed_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements FeedRepository {
  @override
  Future<List<Moment>> list() async => [
        Moment(
          id: 'm1',
          authorId: 'u1',
          authorName: 'Алия',
          text: 'Привет от Алии!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          likes: 2,
          likedByMe: false,
        ),
        Moment(
          id: 'm2',
          authorId: 'u2',
          authorName: 'Берик',
          text: 'Сообщение Берика',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 5,
          likedByMe: true,
        ),
      ];

  @override
  Future<Moment> post(String text) async => Moment(
        id: 'm3',
        authorId: 'u1',
        authorName: 'Алия',
        text: text,
        createdAt: DateTime.now(),
        likes: 0,
        likedByMe: false,
      );

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> like(String id) async {}

  @override
  Future<void> unlike(String id) async {}
}

void main() {
  testWidgets('FeedPage renders 2 moments with author names, text and like counts', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
      child: const MaterialApp(home: FeedPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Семейная лента'), findsOneWidget);
    expect(find.text('Алия'), findsOneWidget);
    expect(find.text('Берик'), findsOneWidget);
    expect(find.text('Привет от Алии!'), findsOneWidget);
    expect(find.text('Сообщение Берика'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // likes count for m1
    expect(find.text('5'), findsOneWidget); // likes count for m2
  });

  testWidgets('FeedPage shows empty hint when list is empty', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(_EmptyRepo()),
      ],
      child: const MaterialApp(home: FeedPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Лента пуста. Поделитесь первым моментом!'), findsOneWidget);
  });
}

class _EmptyRepo implements FeedRepository {
  @override
  Future<List<Moment>> list() async => [];
  @override
  Future<Moment> post(String text) async => Moment(
        id: 'x', authorId: 'u', authorName: 'u', text: text,
        createdAt: DateTime.now(), likes: 0, likedByMe: false);
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> like(String id) async {}
  @override
  Future<void> unlike(String id) async {}
}
```

Run: `cd frontend && flutter test test/features/feed/feed_page_test.dart`
Expected: Both tests PASS

---

### Task 11: Delete dead moments stub (if safe)

**Files:**
- Delete: `frontend/lib/features/moments/` (entire directory — confirmed no imports from app code)

- [ ] **Step 1: Delete stub directory**

```bash
rm -rf frontend/lib/features/moments
```

- [ ] **Step 2: Verify build still passes**

Run: `cd frontend && flutter analyze 2>/dev/null | grep -cE "^\s+error"` → should output `0`

---

### Task 12: Full test suite + analyze + commit

- [ ] **Step 1: Run all tests**

```bash
export PATH="/opt/homebrew/bin:$PATH" && cd /path/to/worktree/frontend && flutter pub get && flutter test
```

Expected: All tests PASS (no failures)

- [ ] **Step 2: Check analyzer**

```bash
flutter analyze 2>/dev/null | grep -cE "^\s+error"
```

Expected: `0`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(feed-fe): экран семейной ленты (текстовые моменты + лайки), маршрут /feed, вход из «Ещё»"
```
