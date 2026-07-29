import 'package:flutter/material.dart';

import '../models/app_failure.dart';
import '../models/favorite_city.dart';
import '../models/weather.dart';
import '../services/favorites_store.dart';
import '../services/location_service.dart';
import '../services/weather_api.dart';
import '../widgets/failure_banner.dart';
import '../widgets/favorites_list.dart';
import '../widgets/search_field.dart';
import '../widgets/weather_card.dart';

/// Écran unique de l'application : recherche, géolocalisation, météo, favoris.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.weatherApi, this.locationService, this.favoritesStore});

  /// Services injectables : utilisés uniquement par les tests, l'application
  /// se contentant des implémentations réelles créées par défaut.
  final WeatherApi? weatherApi;
  final LocationService? locationService;
  final FavoritesStore? favoritesStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WeatherApi _api = widget.weatherApi ?? WeatherApi();
  late final LocationService _location =
      widget.locationService ?? LocationService();
  late final FavoritesStore _store = widget.favoritesStore ?? FavoritesStore();
  final TextEditingController _searchController = TextEditingController();

  Weather? _weather;
  AppFailure? _failure;
  bool _isLoading = false;
  List<FavoriteCity> _favorites = [];

  /// Numéro de la dernière requête lancée, pour ignorer les réponses périmées.
  int _lastRequestId = 0;

  @override
  void initState() {
    super.initState();
    _restoreFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  // --- Favoris -------------------------------------------------------------

  Future<void> _restoreFavorites() async {
    final saved = await _store.load();
    if (!mounted) return;
    setState(() => _favorites = saved);
  }

  bool get _currentIsFavorite {
    final weather = _weather;
    if (weather == null) return false;
    return _favorites.contains(FavoriteCity.fromWeather(weather));
  }

  Future<void> _addCurrentToFavorites() async {
    final weather = _weather;
    if (weather == null) return;

    final city = FavoriteCity.fromWeather(weather);
    if (_favorites.contains(city)) return; // pas de doublon

    // Pas de message de confirmation ici : le bouton passe à « Déjà en favori »
    // et la ville apparaît dans la barre du bas, un SnackBar ne ferait que
    // masquer cette barre.
    setState(() => _favorites = [..._favorites, city]);
    await _store.save(_favorites);
  }

  Future<void> _removeFavorite(FavoriteCity city) async {
    final previous = _favorites;
    setState(() => _favorites = _favorites.where((c) => c != city).toList());
    await _store.save(_favorites);

    _notify(
      '${city.name} a été retirée de vos favoris.',
      action: SnackBarAction(
        label: 'Annuler',
        onPressed: () async {
          setState(() => _favorites = previous);
          await _store.save(_favorites);
        },
      ),
    );
  }

  // --- Appels météo --------------------------------------------------------

  /// Exécute une requête météo en gérant l'état de chargement et les erreurs
  /// de façon uniforme, quelle que soit la source (ville, GPS, favori).
  Future<void> _run(Future<Weather> Function() request) async {
    // Les puces de favoris restent cliquables pendant un chargement : deux
    // requêtes peuvent donc se chevaucher. Seule la dernière lancée a le droit
    // de modifier l'écran, sinon une réponse lente écraserait la plus récente.
    final requestId = ++_lastRequestId;
    bool isStale() => !mounted || requestId != _lastRequestId;

    setState(() {
      _isLoading = true;
      _failure = null;
    });

    try {
      final weather = await request();
      if (isStale()) return;
      setState(() => _weather = weather);
    } on AppFailure catch (failure) {
      if (isStale()) return;
      // La météo précédente reste affichée : l'app demeure utilisable.
      setState(() => _failure = failure);
    } catch (_) {
      if (isStale()) return;
      setState(
        () => _failure = const AppFailure(
          'Une erreur inattendue est survenue. Réessayez dans un instant.',
        ),
      );
    } finally {
      if (!isStale()) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchCity() async {
    FocusScope.of(context).unfocus();
    await _run(() => _api.fetchByCity(_searchController.text));
  }

  Future<void> _useCurrentPosition() async {
    FocusScope.of(context).unfocus();
    await _run(() async {
      final position = await _location.currentPosition();
      return _api.fetchByCoordinates(position.latitude, position.longitude);
    });
  }

  /// Au clic sur un favori : on rappelle l'API pour obtenir la météo
  /// **actuelle**, aucune donnée n'est relue depuis le stockage.
  Future<void> _openFavorite(FavoriteCity city) async {
    _searchController.text = city.name;
    await _run(() => _api.fetchByCoordinates(city.latitude, city.longitude));
  }

  // --- Retours utilisateur -------------------------------------------------

  void _notify(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openSystemSettings() async {
    final kind = _failure?.kind;
    if (kind == null) return;
    await _location.openSettings(kind);
  }

  // --- Construction de l'interface ----------------------------------------

  /// Dégradé de fond adapté à la condition météo et au moment de la journée.
  List<Color> get _backgroundColors {
    final weather = _weather;
    if (weather == null) {
      return const [Color(0xFF2C3E63), Color(0xFF1B2440)];
    }
    if (!weather.isDaytime) {
      return const [Color(0xFF1B2A4A), Color(0xFF0D1425)];
    }

    // Le premier chiffre du code icône identifie la famille de conditions.
    return switch (weather.iconCode.substring(0, 2)) {
      '01' => const [Color(0xFF3E8BD8), Color(0xFF1F5CA8)], // ciel dégagé
      '02' || '03' => const [Color(0xFF5B90C4), Color(0xFF2F5F96)], // nuages
      '04' => const [Color(0xFF5D6B7D), Color(0xFF394452)], // couvert
      '09' || '10' => const [Color(0xFF4C6076), Color(0xFF2A3746)], // pluie
      '11' => const [Color(0xFF3A3F55), Color(0xFF1D2030)], // orage
      '13' => const [Color(0xFF7FA5C4), Color(0xFF4A6E8C)], // neige
      '50' => const [Color(0xFF7B8794), Color(0xFF4E5964)], // brouillard
      _ => const [Color(0xFF2C3E63), Color(0xFF1B2440)],
    };
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _backgroundColors,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SearchField(
                  controller: _searchController,
                  onSearch: _searchCity,
                  onLocate: _useCurrentPosition,
                  isBusy: _isLoading,
                ),
              ),

              if (failure != null)
                FailureBanner(
                  failure: failure,
                  onDismiss: () => setState(() => _failure = null),
                  onOpenSettings: _openSystemSettings,
                ),

              Expanded(child: _buildContent()),

              FavoritesList(
                favorites: _favorites,
                onSelect: _openFavorite,
                onRemove: _removeFavorite,
                selectedId: _weather == null
                    ? null
                    : FavoriteCity.fromWeather(_weather!).id,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _weather == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final weather = _weather;
    if (weather == null) return const _EmptyState();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WeatherCard(
            weather: weather,
            isFavorite: _currentIsFavorite,
            onAddFavorite: _addCurrentToFavorites,
          ),
        ),
        // Rafraîchissement par-dessus la météo déjà affichée.
        if (_isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: Colors.white,
              backgroundColor: Colors.transparent,
              minHeight: 2,
            ),
          ),
      ],
    );
  }
}

/// Écran d'accueil avant toute recherche.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_cloudy_outlined, size: 84, color: Colors.white38),
            SizedBox(height: 20),
            Text(
              'Quelle météo aujourd\'hui ?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Recherchez une ville, ou appuyez sur le bouton de '
              'localisation pour connaître la météo autour de vous.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
