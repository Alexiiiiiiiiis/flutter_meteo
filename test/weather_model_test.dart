import 'package:flutter_meteo/models/favorite_city.dart';
import 'package:flutter_meteo/models/weather.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Weather.fromJson', () {
    test('lit une réponse complète de l\'API', () {
      final weather = Weather.fromJson({
        'coord': {'lon': 2.3488, 'lat': 48.8534},
        'weather': [
          {'id': 800, 'main': 'Clear', 'description': 'ciel dégagé', 'icon': '01d'},
        ],
        'main': {
          'temp': 21.4,
          'feels_like': 20.9,
          'temp_min': 19,
          'temp_max': 23,
          'humidity': 62,
        },
        'wind': {'speed': 3.6},
        'sys': {'country': 'FR'},
        'name': 'Paris',
      });

      expect(weather.cityName, 'Paris');
      expect(weather.country, 'FR');
      expect(weather.temperature, 21.4);
      expect(weather.humidity, 62);
      expect(weather.iconCode, '01d');
      expect(weather.isDaytime, isTrue);
      expect(weather.windKmh, closeTo(12.96, 0.01));
      // L'API renvoie la description en minuscules.
      expect(weather.capitalizedDescription, 'Ciel dégagé');
      expect(weather.iconUrl, contains('01d@4x.png'));
      expect(weather.formattedCoordinates, contains('48.8534° N'));
      expect(weather.formattedCoordinates, contains('2.3488° E'));
    });

    test('formate les coordonnées de l\'hémisphère sud et à l\'ouest', () {
      final weather = Weather.fromJson({
        'coord': {'lat': -33.8688, 'lon': -70.6693},
        'name': 'Santiago',
      });

      expect(weather.formattedCoordinates, contains('33.8688° S'));
      expect(weather.formattedCoordinates, contains('70.6693° O'));
    });

    test('ne plante pas sur une réponse partielle', () {
      final weather = Weather.fromJson({'name': 'Nulle part'});

      expect(weather.cityName, 'Nulle part');
      expect(weather.temperature, 0);
      expect(weather.description, isEmpty);
      expect(weather.capitalizedDescription, 'Conditions inconnues');
      expect(weather.iconCode, '01d'); // valeur de repli
    });

    test('remplace un code icône vide ou tronqué', () {
      // Une chaîne vide passerait le test `?? '01d'` puis casserait le
      // découpage `substring(0, 2)` utilisé pour choisir le fond d'écran.
      for (final broken in ['', '  ', '0']) {
        final weather = Weather.fromJson({
          'weather': [
            {'description': 'test', 'icon': broken},
          ],
        });
        expect(weather.iconCode, '01d', reason: 'icône « $broken »');
        expect(weather.iconCode.substring(0, 2), '01');
      }
    });

    test('gère les températures renvoyées en entier', () {
      final weather = Weather.fromJson({
        'main': {'temp': 18, 'humidity': 50},
        'weather': [
          {'description': 'nuageux', 'icon': '03n'},
        ],
      });

      expect(weather.temperature, 18.0);
      expect(weather.isDaytime, isFalse);
    });
  });

  group('FavoriteCity', () {
    test('deux villes de même nom et pays sont identiques', () {
      const a = FavoriteCity(name: 'Paris', country: 'FR', latitude: 48.85, longitude: 2.35);
      const b = FavoriteCity(name: 'paris', country: 'fr', latitude: 48.86, longitude: 2.36);

      expect(a, equals(b));
      expect({a, b}, hasLength(1)); // pas de doublon dans la liste
    });

    test('sérialisation aller-retour', () {
      const city = FavoriteCity(name: 'Lyon', country: 'FR', latitude: 45.75, longitude: 4.85);
      final restored = FavoriteCity.fromJson(city.toJson());

      expect(restored, equals(city));
      expect(restored.latitude, 45.75);
      expect(restored.label, 'Lyon, FR');
    });
  });
}
