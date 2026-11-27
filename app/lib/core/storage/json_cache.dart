import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache clé → JSON pour le mode « cache puis réseau » (F9).
///
/// Ne contient que des données affichables (listes, profil) ; les jetons
/// restent dans [TokenStorage] (stockage sécurisé).
class JsonCache {
  JsonCache(this._prefs);

  final SharedPreferencesAsync _prefs;

  Future<void> write(String key, Object json) => _prefs.setString(key, jsonEncode(json));

  Future<T?> read<T>(String key) async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as T;
    } on Object {
      await _prefs.remove(key); // cache corrompu ou ancien format : on l'oublie
      return null;
    }
  }

  Future<void> clear() => _prefs.clear();
}
