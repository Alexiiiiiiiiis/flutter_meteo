import 'package:flutter/material.dart';

import '../models/weather.dart';

/// Carte principale : ville, température, icône officielle et description.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather, required this.onAddFavorite, required this.isFavorite});

  final Weather weather;
  final VoidCallback onAddFavorite;

  /// Permet de griser le bouton quand la ville est déjà enregistrée.
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final updatedAt = TimeOfDay.fromDateTime(weather.fetchedAt);

    return Column(
      children: [
        // --- Ville ---------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.place_outlined, color: Colors.white70, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                weather.cityName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (weather.country.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                weather.country,
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Mis à jour à ${updatedAt.hour.toString().padLeft(2, '0')}:'
          '${updatedAt.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 2),
        // Coordonnées renvoyées par l'API : utiles pour vérifier d'un coup d'œil
        // le point réellement interrogé après une géolocalisation.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_outlined, color: Colors.white38, size: 13),
            const SizedBox(width: 5),
            Text(
              weather.formattedCoordinates,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),

        // --- Icône fournie par l'API + température --------------------------
        Image.network(
          weather.iconUrl,
          width: 160,
          height: 160,
          // Si l'icône ne se charge pas (réseau lent), l'app reste utilisable.
          errorBuilder: (_, _, _) =>
              const Icon(Icons.cloud_outlined, size: 110, color: Colors.white70),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const SizedBox(
                  width: 160,
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                ),
        ),
        Text(
          '${weather.temperature.round()}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 78,
            fontWeight: FontWeight.w200,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          weather.capitalizedDescription,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          'Ressenti ${weather.feelsLike.round()}°   ·   '
          'Min ${weather.tempMin.round()}°   ·   Max ${weather.tempMax.round()}°',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),

        // --- Détails secondaires -------------------------------------------
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Detail(
              icon: Icons.water_drop_outlined,
              label: 'Humidité',
              value: '${weather.humidity} %',
            ),
            const SizedBox(width: 28),
            _Detail(
              icon: Icons.air,
              label: 'Vent',
              value: '${weather.windKmh.round()} km/h',
            ),
          ],
        ),

        // --- Ajout aux favoris ----------------------------------------------
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: isFavorite ? null : onAddFavorite,
          icon: Icon(isFavorite ? Icons.star : Icons.star_outline),
          label: Text(isFavorite ? 'Déjà en favori' : 'Ajouter aux favoris'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
            disabledForegroundColor: Colors.white60,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Petit bloc « icône + valeur + libellé » utilisé pour l'humidité et le vent.
class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
