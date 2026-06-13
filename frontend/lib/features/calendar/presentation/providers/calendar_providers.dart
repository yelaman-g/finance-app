import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/event_remote_data_source.dart';
import '../../data/dto/event_dtos.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(EventRemoteDataSourceImpl(ref.watch(dioProvider)));
});

final focusedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final monthEventsProvider = FutureProvider.autoDispose<List<EventOccurrence>>((ref) {
  final m = ref.watch(focusedMonthProvider);
  final from = DateTime(m.year, m.month, 1).subtract(const Duration(days: 7));
  final to = DateTime(m.year, m.month + 1, 0).add(const Duration(days: 7));
  return ref.watch(eventRepositoryProvider).getEvents(from, to);
});
