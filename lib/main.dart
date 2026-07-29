import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const MeteoApp());
}

/// Application météo — TP Flutter IPSSI.
///
/// Consomme l'API OpenWeatherMap : recherche par ville, géolocalisation,
/// affichage de la météo courante et gestion de villes favorites persistées.
class MeteoApp extends StatelessWidget {
  const MeteoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Météo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E8BD8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
