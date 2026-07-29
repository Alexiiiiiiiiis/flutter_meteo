import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/app_failure.dart';

/// Récupération de la position de l'appareil.
///
/// Le parcours complet est traité : service de localisation coupé, permission
/// jamais demandée, refus ponctuel, refus définitif, et délai dépassé.
class LocationService {
  static const Duration _timeout = Duration(seconds: 20);

  /// Position actuelle de l'appareil.
  ///
  /// Lève une [AppFailure] explicite si la position ne peut pas être obtenue.
  Future<Position> currentPosition() async {
    // 1. Le GPS de l'appareil est-il allumé ? Inutile de demander la
    //    permission si le service lui-même est désactivé.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const AppFailure(
        'La localisation est désactivée sur votre appareil. '
        'Activez-la dans les réglages, puis réessayez.',
        kind: FailureKind.locationServiceDisabled,
      );
    }

    // 2. Permission : on la demande seulement si elle n'a pas déjà été accordée.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const AppFailure(
        'L\'accès à votre position a été refusé définitivement. '
        'Autorisez-le dans les réglages de l\'application pour utiliser le GPS.',
        kind: FailureKind.permissionDeniedForever,
      );
    }

    if (permission == LocationPermission.denied) {
      throw const AppFailure(
        'Sans accès à votre position, la météo locale ne peut pas être '
        'affichée. Vous pouvez toujours rechercher une ville manuellement.',
        kind: FailureKind.permissionDenied,
      );
    }

    // 3. Lecture de la position elle-même.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // suffisant pour une ville
          timeLimit: _timeout,
        ),
      );
    } on PermissionDeniedException {
      throw const AppFailure(
        'L\'accès à votre position a été refusé.',
        kind: FailureKind.permissionDenied,
      );
    } catch (_) {
      // Délai dépassé, en intérieur, ou émulateur sans fix satellite : une
      // position récente reste largement assez précise pour choisir une ville.
      final fallback = await _lastKnownPosition();
      if (fallback != null) return fallback;

      throw const AppFailure(
        'Impossible de vous localiser pour le moment. Placez-vous près d\'une '
        'fenêtre et réessayez, ou recherchez votre ville manuellement.',
        kind: FailureKind.locationTimeout,
      );
    }
  }

  /// Dernière position connue de l'appareil, `null` si indisponible.
  Future<Position?> _lastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Ouvre les réglages système, proposé quand la permission est bloquée.
  Future<void> openSettings(FailureKind kind) =>
      kind == FailureKind.locationServiceDisabled
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}
