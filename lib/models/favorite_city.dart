import 'weather.dart';

/// Ville mise en favori.
///
/// On ne mémorise **que** son identité (nom, pays, coordonnées) et jamais la
/// température : au clic, l'application réinterroge l'API pour afficher la
/// météo actuelle et non une donnée figée.
class FavoriteCity {
  const FavoriteCity({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String country;
  final double latitude;
  final double longitude;

  /// Construit un favori à partir de la météo actuellement affichée.
  factory FavoriteCity.fromWeather(Weather weather) => FavoriteCity(
    name: weather.cityName,
    country: weather.country,
    latitude: weather.latitude,
    longitude: weather.longitude,
  );

  factory FavoriteCity.fromJson(Map<String, dynamic> json) => FavoriteCity(
    name: json['name'] as String? ?? '',
    country: json['country'] as String? ?? '',
    latitude: (json['lat'] as num?)?.toDouble() ?? 0,
    longitude: (json['lon'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'lat': latitude,
    'lon': longitude,
  };

  /// « Paris, FR » — ou juste « Paris » si l'API n'a pas renvoyé de pays.
  String get label => country.isEmpty ? name : '$name, $country';

  /// Identifiant stable servant à éviter les doublons dans la liste.
  String get id => '${name.toLowerCase()}|${country.toLowerCase()}';

  @override
  bool operator ==(Object other) => other is FavoriteCity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
