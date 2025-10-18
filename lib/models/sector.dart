// lib/models/sector.dart
import 'package:latlong2/latlong.dart';
import 'package:demo_bici/models/route_point_data.dart'; // Asegúrate de esta importación

class Sector {
  final String id;
  final String name;
  final int startIndex;
  final int endIndex;
  final List<LatLng> polyline; // La lista de puntos LatLng que forman el sector
  final double distanceKm; // Distancia calculada del sector

  // **NUEVAS PROPIEDADES** para almacenar estadísticas específicas del sector
  final double? elevationGainM;
  final double? elevationLossM;
  final double? maxElevationM;
  final double? minElevationM;
  final double? avgSpeedKmh;
  final double? maxSpeedKmh;
  final double? minSpeedKmh;
  final double? avgTempC;
  final double? maxTempC;
  final double? minTempC;

  Sector({
    required this.id,
    required this.name,
    required this.startIndex,
    required this.endIndex,
    required this.polyline,
    required this.distanceKm,
    this.elevationGainM,
    this.elevationLossM,
    this.maxElevationM,
    this.minElevationM,
    this.avgSpeedKmh,
    this.maxSpeedKmh,
    this.minSpeedKmh,
    this.avgTempC,
    this.maxTempC,
    this.minTempC,
  });
}