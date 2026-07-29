import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_city.dart';

/// Persistance de la liste des villes favorites.
///
/// Les favoris sont sérialisés en JSON dans les `SharedPreferences`, ce qui
/// les conserve d'un lancement de l'application à l'autre.
class FavoritesStore {
  static const String _key = 'favorite_cities_v1';

  /// Charge les favoris enregistrés ; renvoie une liste vide au premier
  /// lancement ou si les données stockées sont corrompues.
  Future<List<FavoriteCity>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FavoriteCity.fromJson)
          .toList();
    } catch (_) {
      // Format inattendu (ancienne version de l'app) : on repart proprement.
      await prefs.remove(_key);
      return [];
    }
  }

  /// Enregistre l'intégralité de la liste.
  Future<void> save(List<FavoriteCity> cities) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(cities.map((c) => c.toJson()).toList());
    await prefs.setString(_key, payload);
  }
}
