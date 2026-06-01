class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';

  // Admin
  static const String adminDbTables = '/admin/db/tables';
  static const String adminDbQuery = '/admin/db/query';

  // Categories
  static const String categories = '/categories';

  // Transactions
  static const String transactions = '/transactions';

  // Statistics
  static const String statSummary = '/statistics/summary';
  static const String statByCategory = '/statistics/by-category';
  static const String statTrend = '/statistics/trend';

  // Goals
  static const String goals = '/goals';

  // Households
  static const String households = '/households';

  // Groups
  static const String groups = '/groups';

  // Statistics (family)
  static const String statByMember = '/statistics/by-member';

  // Budgets
  static const String budgets = '/budgets';
}
