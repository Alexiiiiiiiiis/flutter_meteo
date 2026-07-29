import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_meteo/screens/home_screen.dart';
import 'package:flutter_meteo/services/favorites_store.dart';
import 'package:flutter_meteo/services/weather_api.dart';
import 'package:flutter_meteo/widgets/weather_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cherche un texte **dans la carte météo** uniquement : le nom de la ville
/// apparaît aussi dans le champ de recherche et dans la liste des favoris.
Finder _inCard(String text) => find.descendant(
  of: find.byType(WeatherCard),
  matching: find.text(text),
);

String _bodyFor(String city, double temp, String description) => jsonEncode({
  'coord': {'lon': 2.35, 'lat': 48.85},
  'weather': [
    {'description': description, 'icon': '01d'},
  ],
  'main': {
    'temp': temp,
    'feels_like': temp,
    'temp_min': temp,
    'temp_max': temp,
    'humidity': 60,
  },
  'wind': {'speed': 3.0},
  'sys': {'country': 'FR'},
  'name': city,
});

/// Monte l'écran principal avec une API simulée.
Future<void> _pumpApp(WidgetTester tester, {required MockClient client}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        weatherApi: WeatherApi(client: client, apiKey: 'cle-de-test'),
        favoritesStore: FavoritesStore(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche l\'écran d\'accueil et la liste de favoris vide', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      client: MockClient(
        (_) async => http.Response(_bodyFor('Paris', 20, 'ciel dégagé'), 200),
      ),
    );

    expect(find.text('Quelle météo aujourd\'hui ?'), findsOneWidget);
    expect(find.text('Mes favoris (0)'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('une recherche affiche ville, température et description', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      client: MockClient(
        (_) async => http.Response(_bodyFor('Lyon', 24.6, 'peu nuageux'), 200),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Lyon');
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();

    expect(_inCard('Lyon'), findsOneWidget);
    expect(_inCard('25°'), findsOneWidget); // 24,6 arrondi
    expect(_inCard('Peu nuageux'), findsOneWidget);
  });

  testWidgets('une ville inconnue affiche un message compréhensible', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      client: MockClient(
        (_) async => http.Response('{"message":"city not found"}', 404),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Zzzzzz');
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();

    expect(find.textContaining('introuvable'), findsOneWidget);
    // L'application reste utilisable : le champ de recherche est toujours là.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('une recherche vide est signalée sans appel réseau', (
    tester,
  ) async {
    var networkCalls = 0;
    await _pumpApp(
      tester,
      client: MockClient((_) async {
        networkCalls++;
        return http.Response(_bodyFor('Paris', 20, 'ciel dégagé'), 200);
      }),
    );

    // Recherche déclenchée alors que le champ n'a jamais été rempli.
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Saisissez le nom d\'une ville'),
      findsOneWidget,
    );
    expect(networkCalls, 0);
  });

  testWidgets('un favori peut être ajouté puis retiré', (tester) async {
    await _pumpApp(
      tester,
      client: MockClient(
        (_) async => http.Response(_bodyFor('Nantes', 18, 'nuageux'), 200),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Nantes');
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();

    // Le bouton est en bas de la carte : il faut le faire défiler à l'écran.
    await tester.ensureVisible(find.text('Ajouter aux favoris'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter aux favoris'));
    await tester.pumpAndSettle();

    expect(find.text('Mes favoris (1)'), findsOneWidget);
    expect(find.text('Nantes, FR'), findsOneWidget);
    // Le bouton se verrouille : impossible de créer un doublon.
    expect(find.text('Déjà en favori'), findsOneWidget);

    await tester.tap(find.byTooltip('Retirer Nantes des favoris'));
    await tester.pumpAndSettle();

    expect(find.text('Mes favoris (0)'), findsOneWidget);
  });

  testWidgets('une réponse lente n\'écrase pas un favori cliqué après', (
    tester,
  ) async {
    // Le bouton de recherche est désactivé pendant un chargement, mais les
    // puces de favoris restent cliquables : c'est par là que deux requêtes
    // peuvent se chevaucher. La dernière demandée doit gagner.
    SharedPreferences.setMockInitialValues({
      'favorite_cities_v1': jsonEncode([
        {'name': 'Lente', 'country': 'FR', 'lat': 1.0, 'lon': 1.0},
        {'name': 'Lille', 'country': 'FR', 'lat': 2.0, 'lon': 2.0},
      ]),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          weatherApi: WeatherApi(
            apiKey: 'cle-de-test',
            client: MockClient((request) async {
              if (request.url.queryParameters['lat'] == '1.0') {
                await Future<void>.delayed(const Duration(seconds: 3));
                return http.Response(_bodyFor('Lente', 99, 'obsolète'), 200);
              }
              return http.Response(_bodyFor('Lille', 15, 'nuageux'), 200);
            }),
          ),
          favoritesStore: FavoritesStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lente, FR'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Lille, FR'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(_inCard('Lille'), findsOneWidget);
    expect(_inCard('99°'), findsNothing);
  });

  testWidgets('les favoris sont rechargés au démarrage et rafraîchis au clic', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'favorite_cities_v1': jsonEncode([
        {'name': 'Brest', 'country': 'FR', 'lat': 48.39, 'lon': -4.48},
      ]),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          weatherApi: WeatherApi(
            apiKey: 'cle-de-test',
            client: MockClient(
              (_) async =>
                  http.Response(_bodyFor('Brest', 12.2, 'pluie légère'), 200),
            ),
          ),
          favoritesStore: FavoritesStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Le favori a survécu au redémarrage de l'application.
    expect(find.text('Mes favoris (1)'), findsOneWidget);

    await tester.tap(find.text('Brest, FR'));
    await tester.pumpAndSettle();

    // La météo affichée provient de l'API, pas du stockage local.
    expect(_inCard('12°'), findsOneWidget);
    expect(_inCard('Pluie légère'), findsOneWidget);
  });
}
