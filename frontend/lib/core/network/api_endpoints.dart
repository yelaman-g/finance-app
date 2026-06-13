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
  static const String googleSignIn = '/auth/google';

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

  // Categorization
  static const String categorizationRules = '/categorization/rules';
  static const String categorizationSuggest = '/categorization/suggest';

  // Calendar / events
  static const String events = '/events';

  // Push
  static const String pushTokens = '/push/tokens';
  static const String pushTest = '/push/test';

  // AI assistant
  static const String aiChat = '/ai/chat';
  static const String aiInsights = '/ai/insights';
  static const String aiAnalyzeBudget = '/ai/analyze-budget';
  static const String aiSavingsPlan = '/ai/savings-plan';
  static const String aiReminders = '/ai/reminders';
}
