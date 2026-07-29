import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/app_failure.dart';
import '../models/weather.dart';

/// Accès à l'API OpenWeatherMap.
///
/// Toutes les erreurs techniques (socket, timeout, code HTTP, JSON illisible)
/// sont converties en [AppFailure] avec un message en français : l'interface
/// n'a donc jamais à interpréter un code d'erreur.
class WeatherApi {
  /// [client] et [apiKey] ne sont surchargés que par les tests ; en production
  /// la clé provient du `--dart-define` lu dans `config.dart`.
  WeatherApi({http.Client? client, String apiKey = kOwmApiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey.trim();

  final http.Client _client;
  final String _apiKey;

  static const String _host = 'api.openweathermap.org';
  static const String _path = '/data/2.5/weather';
  static const Duration _timeout = Duration(seconds: 12);

  /// Météo courante d'une ville saisie au clavier.
  Future<Weather> fetchByCity(String rawCity) {
    final city = rawCity.trim();
    if (city.isEmpty) {
      throw const AppFailure(
        'Saisissez le nom d\'une ville avant de lancer la recherche.',
        kind: FailureKind.emptyInput,
      );
    }
    return _fetch({'q': city});
  }

  /// Météo courante à des coordonnées GPS (position de l'appareil ou favori).
  Future<Weather> fetchByCoordinates(double latitude, double longitude) =>
      _fetch({'lat': '$latitude', 'lon': '$longitude'});

  Future<Weather> _fetch(Map<String, String> query) async {
    if (_apiKey.isEmpty) {
      throw const AppFailure(
        'Aucune clé API n\'a été fournie au lancement de l\'application. '
        'Démarrez-la avec : flutter run --dart-define-from-file=.env',
        kind: FailureKind.apiKey,
      );
    }

    final uri = Uri.https(_host, _path, {
      ...query,
      'appid': _apiKey,
      'units': kOwmUnits, // températures en °C
      'lang': kOwmLang, // descriptions en français
    });

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const AppFailure(
        'Le serveur météo met trop de temps à répondre. '
        'Vérifiez votre connexion puis réessayez.',
        kind: FailureKind.network,
      );
    } catch (_) {
      // SocketException, ClientException, erreur DNS, coupure Wi-Fi...
      throw const AppFailure(
        'Impossible de joindre le service météo. '
        'Vous semblez hors ligne : vérifiez votre connexion Internet.',
        kind: FailureKind.network,
      );
    }

    return switch (response.statusCode) {
      200 => _parse(response.body),
      401 => throw const AppFailure(
        'La clé API a été refusée. Vérifiez qu\'elle est correcte : '
        'une clé fraîchement créée peut mettre jusqu\'à 2 heures à s\'activer.',
        kind: FailureKind.apiKey,
      ),
      404 => throw const AppFailure(
        'Cette ville est introuvable. Vérifiez l\'orthographe, ou précisez '
        'le pays (par exemple « Rennes, FR »).',
        kind: FailureKind.cityNotFound,
      ),
      429 => throw const AppFailure(
        'Trop de recherches en peu de temps : le quota gratuit est atteint. '
        'Patientez une minute avant de réessayer.',
        kind: FailureKind.rateLimited,
      ),
      _ => throw AppFailure(
        'Le service météo a répondu une erreur ${response.statusCode}. '
        'Réessayez dans quelques instants.',
      ),
    };
  }

  Weather _parse(String body) {
    try {
      return Weather.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } catch (_) {
      throw const AppFailure(
        'La réponse du service météo est illisible. Réessayez dans un instant.',
      );
    }
  }

  void dispose() => _client.close();
}
