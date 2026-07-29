/// Configuration de l'application.
///
/// La clé API OpenWeatherMap n'est **jamais** écrite en dur dans le code : elle
/// est injectée au lancement pour ne pas se retrouver dans le dépôt Git.
///
/// Elle est lue depuis le fichier `.env` à la racine du projet :
///   flutter run --dart-define-from-file=.env
///
/// `--dart-define-from-file` accepte nativement le format `clé=valeur`, aucune
/// dépendance de type `flutter_dotenv` n'est donc nécessaire.
library;

/// Clé API OpenWeatherMap, vide si elle n'a pas été fournie au lancement.
const String kOwmApiKey = String.fromEnvironment('OWM_API_KEY');

/// Unités et langue demandées à l'API (°C et descriptions en français).
const String kOwmUnits = 'metric';
const String kOwmLang = 'fr';
