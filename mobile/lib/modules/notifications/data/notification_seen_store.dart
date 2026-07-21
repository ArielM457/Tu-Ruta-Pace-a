import 'package:shared_preferences/shared_preferences.dart';

class NotificationSeenStore {
  static const _prefsKey = 'notifications_seen_ids';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey)?.toSet() ?? <String>{};
  }

  Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.toList());
  }
}
