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
  static const transactions = _Route('transactions', '/transactions');
  static const goals = _Route('goals', '/goals');
  static const family = _Route('family', '/family');
  static const groups = _Route('groups', '/groups');
  static const budgets = _Route('budgets', '/budgets');
  static const more = _Route('more', '/more');

  // Categorization
  static const rules = _Route('rules', '/rules');

  // Categories management
  static const categoriesManage = _Route('categories-manage', '/categories-manage');

  // Admin
  static const admin = _Route('admin', '/admin');
  static const calendar = _Route('calendar', '/calendar');
  static const shopping = _Route('shopping', '/shopping');
  static const wishlist = _Route('wishlist', '/wishlist');
  static const polls = _Route('polls', '/polls');
  static const capsules = _Route('capsules', '/capsules');
}

class _Route {
  const _Route(this.name, this.path);
  final String name;
  final String path;
}
