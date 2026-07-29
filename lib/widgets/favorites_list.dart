import 'package:flutter/material.dart';

import '../models/favorite_city.dart';

/// Bandeau des villes favorites, affiché en bas de l'écran.
///
/// Un appui sur une ville relance un appel à l'API (météo actuelle), la
/// corbeille la retire définitivement de la liste enregistrée.
class FavoritesList extends StatelessWidget {
  const FavoritesList({
    super.key,
    required this.favorites,
    required this.onSelect,
    required this.onRemove,
    this.selectedId,
  });

  final List<FavoriteCity> favorites;
  final ValueChanged<FavoriteCity> onSelect;
  final ValueChanged<FavoriteCity> onRemove;

  /// Identifiant de la ville actuellement affichée, mise en évidence.
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Mes favoris (${favorites.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (favorites.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucune ville enregistrée pour l\'instant. '
                  'Recherchez une ville puis appuyez sur « Ajouter aux favoris ».',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              )
            else
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final city = favorites[index];
                    return _FavoriteChip(
                      city: city,
                      isSelected: city.id == selectedId,
                      onTap: () => onSelect(city),
                      onRemove: () => onRemove(city),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({
    required this.city,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteCity city;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: isSelected ? 0.28 : 0.14),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                city.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                tooltip: 'Retirer ${city.name} des favoris',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
