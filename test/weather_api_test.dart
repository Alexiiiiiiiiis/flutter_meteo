import 'dart:async';
import 'dart:convert';

import 'package:flutter_meteo/models/app_failure.dart';
import 'package:flutter_meteo/services/weather_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Réponse minimale mais valide de l'API, réutilisée par plusieurs tests.
final String _validBody = jsonEncode({
  'coord': {'lon': 2.35, 'lat': 48.85},
  'weather': [
    {'description': 'ciel dégagé', 'icon': '01d'},
  ],
  'main': {'temp': 21.4, 'humidity': 62},
  'wind': {'speed': 3.0},
  'sys': {'country': 'FR'},
  'name': 'Paris',
});

/// Vérifie qu'une requête lève bien une [AppFailure] de la nature attendue.
Matcher _failsWith(FailureKind kind) => throwsA(
  isA<AppFailure>()
      .having((f) => f.kind, 'kind', kind)
      // Le message doit être rédigé, pas un code technique.
      .having((f) => f.message.length, 'message non vide', greaterThan(20)),
);

void main() {
  group('WeatherApi — cas nominal', () {
    test('construit l\'URL avec °C, le français et la clé', () async {
      late Uri captured;
      final api = WeatherApi(
        apiKey: 'cle-de-test',
        client: MockClient((request) async {
          captured = request.url;
          return http.Response(_validBody, 200);
        }),
      );

      final weather = await api.fetchByCity('  Paris  ');

      expect(captured.queryParameters['q'], 'Paris'); // espaces retirés
      expect(captured.queryParameters['units'], 'metric');
      expect(captured.queryParameters['lang'], 'fr');
      expect(captured.queryParameters['appid'], 'cle-de-test');
      expect(weather.cityName, 'Paris');
      expect(weather.temperature, 21.4);
    });

    test('interroge l\'API par coordonnées GPS', () async {
      late Uri captured;
      final api = WeatherApi(
        apiKey: 'cle-de-test',
        client: MockClient((request) async {
          captured = request.url;
          return http.Response(_validBody, 200);
        }),
      );

      await api.fetchByCoordinates(48.85, 2.35);

      expect(captured.queryParameters['lat'], '48.85');
      expect(captured.queryParameters['lon'], '2.35');
      expect(captured.queryParameters.containsKey('q'), isFalse);
    });
  });

  group('WeatherApi — gestion des erreurs', () {
    WeatherApi apiReturning(int status) => WeatherApi(
      apiKey: 'cle-de-test',
      client: MockClient((_) async => http.Response('{"message":"ko"}', status)),
    );

    test('champ vide : aucun appel réseau n\'est déclenché', () {
      var called = false;
      final api = WeatherApi(
        apiKey: 'cle-de-test',
        client: MockClient((_) async {
          called = true;
          return http.Response(_validBody, 200);
        }),
      );

      expect(() => api.fetchByCity('   '), _failsWith(FailureKind.emptyInput));
      expect(called, isFalse);
    });

    test('clé API absente', () {
      final api = WeatherApi(apiKey: '');
      expect(() => api.fetchByCity('Paris'), _failsWith(FailureKind.apiKey));
    });

    test('401 : clé refusée', () {
      expect(
        () => apiReturning(401).fetchByCity('Paris'),
        _failsWith(FailureKind.apiKey),
      );
    });

    test('404 : ville inconnue', () {
      expect(
        () => apiReturning(404).fetchByCity('Zzzzz'),
        _failsWith(FailureKind.cityNotFound),
      );
    });

    test('429 : quota dépassé', () {
      expect(
        () => apiReturning(429).fetchByCity('Paris'),
        _failsWith(FailureKind.rateLimited),
      );
    });

    test('500 : erreur serveur', () {
      expect(
        () => apiReturning(500).fetchByCity('Paris'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('coupure réseau', () {
      final api = WeatherApi(
        apiKey: 'cle-de-test',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(() => api.fetchByCity('Paris'), _failsWith(FailureKind.network));
    });

    test('serveur qui ne répond pas', () {
      final api = WeatherApi(
        apiKey: 'cle-de-test',
        client: MockClient((_) async => throw TimeoutException('trop long')),
      );

      expect(() => api.fetchByCity('Paris'), _failsWith(FailureKind.network));
    });

    test('réponse illisible', () {
      final api = WeatherApi(
        apiKey: 'cle-de-test',
        client: MockClient((_) async => http.Response('<html>oops</html>', 200)),
      );

      expect(() => api.fetchByCity('Paris'), throwsA(isA<AppFailure>()));
    });
  });
}
