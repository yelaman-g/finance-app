abstract class PushRepository {
  Future<void> registerToken(String token, String platform);
  Future<void> deleteToken(String token);
}
