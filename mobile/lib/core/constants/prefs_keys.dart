/// Keys used with [SharedPreferences] for lightweight session state.
class PrefsKeys {
  PrefsKeys._();

  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  /// Set to true after preferences survey succeeds (local UX flag).
  static const String onboardingComplete = 'onboarding_complete';
}
