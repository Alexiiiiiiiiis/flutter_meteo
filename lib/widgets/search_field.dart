import 'package:flutter/material.dart';

/// Champ de saisie de la ville + bouton loupe + bouton GPS.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onLocate,
    required this.isBusy,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onLocate;

  /// Désactive les boutons pendant un chargement pour éviter les doubles appels.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !isBusy,
            textInputAction: TextInputAction.search,
            // La touche « rechercher » du clavier lance la même action.
            onSubmitted: (_) => onSearch(),
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Rechercher une ville...',
              hintStyle: const TextStyle(color: Colors.white54),
              // Bouton de recherche : même action que la touche « entrée ».
              prefixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.white70),
                tooltip: 'Rechercher',
                onPressed: isBusy ? null : onSearch,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        tooltip: 'Effacer',
                        onPressed: controller.clear,
                      ),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // --- Bouton GPS ------------------------------------------------------
        Tooltip(
          message: 'Utiliser ma position',
          child: Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: isBusy ? null : onLocate,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
