/// Représente la météo courante d'une ville, telle que renvoyée par
/// l'endpoint `/data/2.5/weather` d'OpenWeatherMap.
class Weather {
  const Weather({
    required this.cityName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
    required this.fetchedAt,
  });

  final String cityName;
  final String country;
  final double latitude;
  final double longitude;

  /// Températures en °C (l'API est interrogée avec `units=metric`).
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;

  /// Humidité en %.
  final int humidity;

  /// Vitesse du vent en m/s (converti en km/h pour l'affichage).
  final double windSpeed;

  /// Description courte fournie par l'API, déjà en français (`lang=fr`).
  final String description;

  /// Code de l'icône OpenWeatherMap, par exemple `04d`.
  final String iconCode;

  /// Instant auquel la donnée a été récupérée, pour afficher « mis à jour à ».
  final DateTime fetchedAt;

  /// URL de l'icône officielle : inutile de dessiner nos propres pictogrammes.
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@4x.png';

  /// Vrai s'il fait jour à l'endroit mesuré (les codes du jour finissent par `d`).
  bool get isDaytime => iconCode.endsWith('d');

  double get windKmh => windSpeed * 3.6;

  /// Coordonnées renvoyées par l'API, par exemple « 48.8534° N · 2.3488° E ».
  String get formattedCoordinates {
    final latHemisphere = latitude >= 0 ? 'N' : 'S';
    final lonHemisphere = longitude >= 0 ? 'E' : 'O';
    return '${latitude.abs().toStringAsFixed(4)}° $latHemisphere'
        '   ·   ${longitude.abs().toStringAsFixed(4)}° $lonHemisphere';
  }

  /// Description avec une majuscule initiale : l'API renvoie « ciel dégagé ».
  String get capitalizedDescription => description.isEmpty
      ? 'Conditions inconnues'
      : description[0].toUpperCase() + description.substring(1);

  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? const {};
    final wind = json['wind'] as Map<String, dynamic>? ?? const {};
    final coord = json['coord'] as Map<String, dynamic>? ?? const {};
    final sys = json['sys'] as Map<String, dynamic>? ?? const {};

    // `weather` est une liste : le premier élément décrit la condition principale.
    final conditions = json['weather'] as List<dynamic>? ?? const [];
    final condition = conditions.isNotEmpty
        ? conditions.first as Map<String, dynamic>
        : const <String, dynamic>{};

    return Weather(
      cityName: json['name'] as String? ?? 'Ville inconnue',
      country: sys['country'] as String? ?? '',
      latitude: _toDouble(coord['lat']),
      longitude: _toDouble(coord['lon']),
      temperature: _toDouble(main['temp']),
      feelsLike: _toDouble(main['feels_like']),
      tempMin: _toDouble(main['temp_min']),
      tempMax: _toDouble(main['temp_max']),
      humidity: (main['humidity'] as num?)?.round() ?? 0,
      windSpeed: _toDouble(wind['speed']),
      description: condition['description'] as String? ?? '',
      // Jamais vide : le code est découpé ailleurs pour choisir le fond, une
      // chaîne vide provoquerait une erreur d'indice.
      iconCode: _nonEmpty(condition['icon'], fallback: '01d'),
      fetchedAt: DateTime.now(),
    );
  }

  static String _nonEmpty(Object? value, {required String fallback}) {
    final text = value is String ? value.trim() : '';
    return text.length >= 2 ? text : fallback;
  }

  /// L'API mélange `int` et `double` selon les champs : on normalise.
  static double _toDouble(Object? value) =>
      value is num ? value.toDouble() : 0.0;
}
