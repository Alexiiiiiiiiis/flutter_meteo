import 'package:flutter/material.dart';

import '../models/app_failure.dart';

/// Bandeau d'erreur affiché en haut du contenu.
///
/// Il reste volontairement non bloquant : l'application continue de
/// fonctionner (recherche, favoris) pendant qu'il est visible.
class FailureBanner extends StatelessWidget {
  const FailureBanner({
    super.key,
    required this.failure,
    required this.onDismiss,
    this.onOpenSettings,
  });

  final AppFailure failure;
  final VoidCallback onDismiss;

  /// Proposé uniquement pour les erreurs que l'utilisateur peut corriger
  /// dans les réglages du téléphone.
  final VoidCallback? onOpenSettings;

  IconData get _icon => switch (failure.kind) {
    FailureKind.emptyInput => Icons.edit_outlined,
    FailureKind.cityNotFound => Icons.search_off_outlined,
    FailureKind.network => Icons.wifi_off_outlined,
    FailureKind.apiKey => Icons.vpn_key_outlined,
    FailureKind.permissionDenied ||
    FailureKind.permissionDeniedForever => Icons.location_disabled_outlined,
    FailureKind.locationServiceDisabled => Icons.location_off_outlined,
    FailureKind.locationTimeout => Icons.location_searching,
    FailureKind.rateLimited => Icons.hourglass_top_outlined,
    FailureKind.unknown => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    final showSettings = failure.isSettingsRelated && onOpenSettings != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failure.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (showSettings)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: onOpenSettings,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Ouvrir les réglages'),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            tooltip: 'Masquer',
          ),
        ],
      ),
    );
  }
}
