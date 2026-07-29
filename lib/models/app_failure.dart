/// Nature d'une erreur, utilisée par l'interface pour choisir l'icône,
/// la couleur et l'éventuelle action proposée à l'utilisateur.
enum FailureKind {
  /// Le champ de recherche était vide.
  emptyInput,

  /// La ville demandée est inconnue d'OpenWeatherMap.
  cityNotFound,

  /// Pas de connexion, DNS injoignable, serveur qui ne répond pas...
  network,

  /// Clé API absente, invalide ou pas encore activée.
  apiKey,

  /// L'utilisateur a refusé l'accès à sa position.
  permissionDenied,

  /// Refus définitif : il faut passer par les réglages du téléphone.
  permissionDeniedForever,

  /// Le GPS / service de localisation est désactivé sur l'appareil.
  locationServiceDisabled,

  /// Aucun point GPS n'a pu être obtenu dans le temps imparti (intérieur,
  /// émulateur sans fix satellite...). Rien à corriger dans les réglages.
  locationTimeout,

  /// Le quota de requêtes gratuit est dépassé.
  rateLimited,

  /// Tout le reste.
  unknown,
}

/// Erreur applicative porteuse d'un message déjà rédigé en français,
/// prêt à être affiché tel quel à l'utilisateur.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.kind = FailureKind.unknown});

  final String message;
  final FailureKind kind;

  /// Vrai si l'utilisateur peut corriger la situation dans les réglages système.
  bool get isSettingsRelated =>
      kind == FailureKind.permissionDeniedForever ||
      kind == FailureKind.locationServiceDisabled;

  @override
  String toString() => message;
}
