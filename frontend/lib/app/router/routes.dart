/// Centralized route names + paths. Never use raw strings in widgets.
class AppRoutes {
  AppRoutes._();

  // Bootstrap
  static const splash = _Route('splash', '/');
  static const onboarding = _Route('onboarding', '/onboarding');

  // Auth
  static const login = _Route('login', '/auth/login');
  static const register = _Route('register', '/auth/register');
  static const forgotPassword = _Route('forgot-password', '/auth/forgot');
  static const verifyEmail = _Route('verify-email', '/auth/verify');

  // App shell
  static const dashboard = _Route('dashboard', '/dashboard');
  static const analytics = _Route('analytics', '/analytics');
  static const ai = _Route('ai', '/ai');
  static const moments = _Route('moments', '/moments');
  static const profile = _Route('profile', '/profile');

  // Admin
  static const admin = _Route('admin', '/admin');
}

class _Route {
  const _Route(this.name, this.path);
  final String name;
  final String path;
}
