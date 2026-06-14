import '../../data/dto/capsule.dart';

abstract class CapsuleRepository {
  Future<List<Capsule>> list();
  Future<Capsule> create(String title, String message, DateTime openDate);
  Future<void> delete(String id);
}
