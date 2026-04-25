import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/prefs_keys.dart';
import '../../data/models/user_model.dart';

/// Logged-in user snapshot restored from [SharedPreferences].
class UserSession {
  const UserSession({
    required this.userId,
    required this.name,
    required this.email,
    this.onboardingComplete = false,
  });

  final String userId;
  final String name;
  final String email;
  final bool onboardingComplete;
}

/// Loads and updates local session (user id + flags) after login/logout.
class SessionNotifier extends AsyncNotifier<UserSession?> {
  @override
  Future<UserSession?> build() => _load();

  Future<UserSession?> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(PrefsKeys.userId);
    if (id == null || id.isEmpty) return null;
    return UserSession(
      userId: id,
      name: prefs.getString(PrefsKeys.userName) ?? '',
      email: prefs.getString(PrefsKeys.userEmail) ?? '',
      onboardingComplete:
          prefs.getBool(PrefsKeys.onboardingComplete) ?? false,
    );
  }

  /// Persists the user returned by the API and refreshes state.
  Future<void> setLoggedInUser(UserModel user, {bool? onboardingComplete}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.userId, user.id);
    await prefs.setString(PrefsKeys.userName, user.name);
    await prefs.setString(PrefsKeys.userEmail, user.email);
    if (onboardingComplete != null) {
      await prefs.setBool(PrefsKeys.onboardingComplete, onboardingComplete);
    }
    state = AsyncData(
      UserSession(
        userId: user.id,
        name: user.name,
        email: user.email,
        onboardingComplete:
            onboardingComplete ??
                (prefs.getBool(PrefsKeys.onboardingComplete) ?? false),
      ),
    );
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.onboardingComplete, value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        UserSession(
          userId: current.userId,
          name: current.name,
          email: current.email,
          onboardingComplete: value,
        ),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefsKeys.userId);
    await prefs.remove(PrefsKeys.userName);
    await prefs.remove(PrefsKeys.userEmail);
    await prefs.remove(PrefsKeys.onboardingComplete);
    state = const AsyncData(null);
  }

  Future<void> refreshFromStorage() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, UserSession?>(SessionNotifier.new);
