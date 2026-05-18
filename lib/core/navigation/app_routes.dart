abstract final class AppRoutes {
  static const String today = '/today';
  static const String history = '/history';
  static const String calendar = '/calendar';
  static const String insights = '/insights';
  static const String settings = '/settings';

  static const String log = '/today/log';
  static const String entryDetail = '/entry';
  static const String entryEdit = '/entry/:id/edit';

  static const String onboarding = '/onboarding';
  static const String about = '/settings/about';

  static String entryDetailFor(String id) => '/entry/$id';
  static String entryEditFor(String id) => '/entry/$id/edit';
}
